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
    private var reconnectTask: Task<Void, Never>?
    private var policy = ReconnectPolicy()
    private var manualStop = false
    private let repository: TunnelRepository

    // Called by TunnelManager when state changes; do not call directly.
    var onStateChange: ((TunnelState) -> Void)?

    init(tunnelID: UUID, repository: TunnelRepository = TunnelRepository()) {
        self.tunnelID = tunnelID
        self.repository = repository
    }

    func start(tunnel: Tunnel) {
        manualStop = false
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
                self?.handleTermination(exitCode: p.terminationStatus, tunnel: tunnel)
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
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(2))
            guard let self, case .connecting = self.state, self.process?.isRunning == true else { return }
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
        let humanError: String?

        if lower.contains("permission denied") {
            humanError = "Authentication failed: Permission denied"
        } else if lower.contains("connection refused") {
            humanError = "Connection refused by \(tunnel.host)"
        } else if lower.contains("host key verification failed") {
            humanError = "Host key verification failed for \(tunnel.host)"
        } else if lower.contains("no route to host") {
            humanError = "No route to host \(tunnel.host)"
        } else if lower.contains("connection timed out") {
            humanError = "Connection timed out to \(tunnel.host)"
        } else if lower.contains("bind: address already in use") {
            humanError = "Local port \(tunnel.localPort.map(String.init) ?? "?") already in use"
        } else if lower.contains("forwarding_success") || lower.contains("all forwarding requests processed") {
            humanError = nil
            transition(to: .connected)
        } else {
            humanError = nil
        }

        if let err = humanError {
            lastError = err
            try? repository.appendEvent(ConnectionEvent(
                tunnelID: tunnelID,
                event: .error,
                message: err
            ))
        }
    }

    @MainActor
    private func handleTermination(exitCode: Int32, tunnel: Tunnel) {
        stderrTask?.cancel()
        stderrTask = nil
        process = nil

        guard !manualStop else { return }

        let msg = "Process exited with code \(exitCode)"
        try? repository.appendEvent(ConnectionEvent(tunnelID: tunnelID, event: .disconnected, message: msg))
        scheduleReconnect(tunnel: tunnel)
    }

    private func scheduleReconnect(tunnel: Tunnel) {
        guard !manualStop else { return }
        let delay = policy.delay
        policy.increment()
        let attempt = policy.attempt
        transition(to: .reconnecting(attempt: attempt))

        reconnectTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(delay))
            guard let self, !self.manualStop, !Task.isCancelled else { return }
            guard let fresh = try? self.repository.fetchTunnel(id: self.tunnelID), fresh.isEnabled else { return }
            self.launch(tunnel: fresh)
        }
    }

    private func terminateProcess() {
        stderrTask?.cancel()
        stderrTask = nil
        if let proc = process, proc.isRunning {
            proc.terminate()
        }
        process = nil
    }

    private func transition(to newState: TunnelState) {
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
