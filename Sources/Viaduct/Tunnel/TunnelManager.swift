import Foundation
import Observation

@Observable
@MainActor
final class TunnelManager {
    static let shared = TunnelManager()

    private(set) var processes: [UUID: TunnelProcess] = [:]
    private(set) var states: [UUID: TunnelState] = [:]
    private(set) var connectedDates: [UUID: Date] = [:]
    private let repository: TunnelRepository

    private init(repository: TunnelRepository = TunnelRepository()) {
        self.repository = repository
    }

    // MARK: - Global state

    var globalStatus: GlobalTunnelStatus {
        let active = states.values.filter { if case .stopped = $0 { return false }; return true }
        if active.isEmpty { return .allStopped }
        let connected = active.filter { if case .connected = $0 { return true }; return false }.count
        let failed = active.filter { if case .failed = $0 { return true }; return false }.count
        if failed > 0 { return .someErrors }
        if connected == active.count { return .allConnected }
        return .mixed
    }

    // MARK: - Lifecycle

    func launchAutoConnectTunnels() {
        guard let tunnels = try? repository.fetchAutoConnectTunnels() else { return }
        for tunnel in tunnels where tunnel.isEnabled {
            start(tunnel: tunnel)
        }
    }

    // MARK: - Control

    func start(tunnel: Tunnel) {
        let proc: TunnelProcess
        if let existing = processes[tunnel.id] {
            proc = existing
        } else {
            proc = TunnelProcess(tunnelID: tunnel.id, repository: repository)
            proc.onStateChange = { [weak self] newState in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    self.states[tunnel.id] = newState
                    switch newState {
                    case .connected:
                        self.connectedDates[tunnel.id] = Date()
                    case .stopped, .failed, .idle:
                        self.connectedDates.removeValue(forKey: tunnel.id)
                    default:
                        break
                    }
                }
            }
            processes[tunnel.id] = proc
        }
        states[tunnel.id] = .connecting
        proc.start(tunnel: tunnel)
    }

    func stop(tunnelID: UUID) {
        processes[tunnelID]?.stop()
        states[tunnelID] = .stopped
    }

    func restart(tunnelID: UUID) {
        guard let tunnel = try? repository.fetchTunnel(id: tunnelID) else { return }
        stop(tunnelID: tunnelID)
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(300))
            self.start(tunnel: tunnel)
        }
    }

    // Called by NetworkMonitor / SleepWakeMonitor
    func reconnectActive() {
        for (id, state) in states {
            switch state {
            case .connected, .connecting, .reconnecting:
                guard let tunnel = try? repository.fetchTunnel(id: id), tunnel.isEnabled else { continue }
                start(tunnel: tunnel)
            default:
                break
            }
        }
    }

    func state(for tunnelID: UUID) -> TunnelState {
        states[tunnelID] ?? .idle
    }

    func connectedAt(for tunnelID: UUID) -> Date? {
        connectedDates[tunnelID]
    }
}

enum GlobalTunnelStatus {
    case allConnected
    case someErrors
    case mixed
    case allStopped
}
