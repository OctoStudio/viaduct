import Foundation
import Network

@MainActor
final class NetworkMonitor {
    static let shared = NetworkMonitor()
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.qdecosne.Viaduct.NetworkMonitor")
    private var previousStatus: NWPath.Status?

    private init() {}

    func start() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                self?.handlePathUpdate(path)
            }
        }
        monitor.start(queue: queue)
    }

    private func handlePathUpdate(_ path: NWPath) {
        defer { previousStatus = path.status }
        // Only reconnect when network becomes satisfied after being unsatisfied
        guard path.status == .satisfied, previousStatus == .unsatisfied else { return }
        TunnelManager.shared.reconnectActive()
    }
}
