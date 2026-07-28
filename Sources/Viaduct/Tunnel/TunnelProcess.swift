import Foundation

enum TunnelState: Equatable {
    case idle
    case connecting
    case connected
    case reconnecting(attempt: Int)
    case stopped
    case failed(String)
}

@MainActor
final class TunnelProcess: ObservableObject {
    let tunnelID: UUID
    @Published private(set) var state: TunnelState = .idle
    @Published private(set) var lastError: String?

    private var process: Process?
    private var stderrTask: Task<Void, Never>?
    private var connectedTask: Task<Void, Never>?
    private var reconnectTask: Task<Void, Never>?
    private var policy = ReconnectPolicy()
    private var manualStop = false
    private var permanentFailure = false
    private let repository: TunnelRepository

    // Called by TunnelManager when state changes; do not call directly.
    var onStateChange: ((TunnelState) -> Void)?

    init(tunnelID: UUID, repository: TunnelRepository = TunnelRepository()) {
        self.tunnelID = tunnelID
        self.repository = repository
    }

    func start(tunnel: Tunnel) {
        manualStop = false
        permanentFailure = false
        lastError = nil
        reconnectTask?.cancel()
        reconnectTask = nil
        policy.reset()
        launch(tunnel: tunnel)
    }

    func stop() {
        manualStop = true
        reconnectTask?.cancel()
        reconnectTask = nil
        terminateProcess()
        transition(to: .stopped)
    }

    private func launch(tunnel: Tunnel) {
        terminateProcess()

        let args = SSHCommandBuilder.buildArguments(for: tunnel)
        let env = SSHCommandBuilder.buildEnvironment(for: tunnel)

        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/ssh")
        proc.arguments = args
        proc.environment = env

        let stderrPipe = Pipe()
        proc.standardOutput = FileHandle.nullDevice
        proc.standardError = stderrPipe

        proc.terminationHandler = { [weak self] p in
            Task { @MainActor [weak self] in
                self?.handleTermination(process: p, exitCode: p.terminationStatus, tunnel: tunnel)
            }
        }

        do {
            try proc.run()
        } catch {
            transition(to: .failed("Failed to launch ssh: \(error.localizedDescription)"))
            scheduleReconnect(tunnel: tunnel)
            return
        }

        process = proc
        transition(to: .connecting)

        stderrTask = Task { [weak self] in
            await self?.readStderr(pipe: stderrPipe, tunnel: tunnel)
        }

        // After a brief window, if still running assume connected
        connectedTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(2))
            guard let self, !Task.isCancelled, case .connecting = self.state, self.process?.isRunning == true else { return }
            self.transition(to: .connected)
        }
    }

    private func readStderr(pipe: Pipe, tunnel: Tunnel) async {
        let handle = pipe.fileHandleForReading
        for await line in handle.lines() {
            await MainActor.run {
                self.parseStderrLine(line, tunnel: tunnel)
            }
        }
    }

    @MainActor
    private func parseStderrLine(_ line: String, tunnel: Tunnel) {
        let lower = line.lowercased()

        if lower.contains("permission denied") {
            let agentBased = tunnel.authMethod == .onePasswordAgent || tunnel.authMethod == .systemAgent
            if agentBased {
                // Agent may be locked/missing key — transient, keep retrying
                let agentName = tunnel.authMethod == .onePasswordAgent ? "1Password" : "SSH agent"
                lastError = "Authentication failed — check \(agentName) has the right key"
            } else {
                permanentFailure = true
                let err = "Authentication failed: Permission denied"
                lastError = err
                transition(to: .failed(err))
            }
        } else if lower.contains("host key verification failed") {
            permanentFailure = true
            let err = "Host key verification failed for \(tunnel.host)"
            lastError = err
            transition(to: .failed(err))
        } else if lower.contains("bind: address already in use") {
            permanentFailure = true
            let err = "Local port \(tunnel.localPort.map(String.init) ?? "?") already in use"
            lastError = err
            transition(to: .failed(err))
        } else if lower.contains("connection refused") {
            lastError = "Connection refused by \(tunnel.host)"
        } else if lower.contains("no route to host") {
            lastError = "No route to host \(tunnel.host)"
        } else if lower.contains("connection timed out") {
            lastError = "Connection timed out to \(tunnel.host)"
        } else if lower.contains("forwarding_success") || lower.contains("all forwarding requests processed") {
            transition(to: .connected)
        }
    }

    @MainActor
    private func handleTermination(process terminatedProcess: Process, exitCode: Int32, tunnel: Tunnel) {
        guard process === terminatedProcess else { return }

        stderrTask?.cancel()
        stderrTask = nil
        connectedTask?.cancel()
        connectedTask = nil
        process = nil

        guard !manualStop else { return }

        let msg = "Process exited with code \(exitCode)"
        try? repository.appendEvent(ConnectionEvent(tunnelID: tunnelID, event: .disconnected, message: msg))
        scheduleReconnect(tunnel: tunnel)
    }

    private func scheduleReconnect(tunnel: Tunnel) {
        guard !manualStop, !permanentFailure else { return }
        let delay = policy.delay
        policy.increment()
        let attempt = policy.attempt
        transition(to: .reconnecting(attempt: attempt))

        reconnectTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(delay))
            guard let self, !self.manualStop, !self.permanentFailure, !Task.isCancelled else { return }
            guard let fresh = try? self.repository.fetchTunnel(id: self.tunnelID), fresh.isEnabled else { return }
            self.launch(tunnel: fresh)
        }
    }

    private func terminateProcess() {
        stderrTask?.cancel()
        stderrTask = nil
        connectedTask?.cancel()
        connectedTask = nil
        if let proc = process, proc.isRunning {
            proc.terminate()
        }
        process = nil
    }

    private func transition(to newState: TunnelState) {
        guard newState != state else { return }

        state = newState
        onStateChange?(newState)

        let eventKind: ConnectionEventKind?
        switch newState {
        case .connected:    eventKind = .connected
        case .stopped:      eventKind = .disconnected
        case .failed:       eventKind = .error
        default:            eventKind = nil
        }

        if let kind = eventKind {
            let msg: String? = {
                if case .failed(let m) = newState { return m }
                return nil
            }()
            try? repository.appendEvent(ConnectionEvent(tunnelID: tunnelID, event: kind, message: msg))
        }
    }
}

// MARK: - FileHandle async lines

extension FileHandle {
    func lines() -> AsyncStream<String> {
        AsyncStream { continuation in
            let handle = self
            Thread.detachNewThread {
                while true {
                    let data = handle.availableData
                    if data.isEmpty { break }
                    if let str = String(data: data, encoding: .utf8) {
                        for line in str.components(separatedBy: "\n") where !line.isEmpty {
                            continuation.yield(line)
                        }
                    }
                }
                continuation.finish()
            }
        }
    }
}
