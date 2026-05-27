import AppKit

final class SleepWakeMonitor {
    static let shared = SleepWakeMonitor()
    private var observers: [NSObjectProtocol] = []

    private init() {}

    func start() {
        let nc = NSWorkspace.shared.notificationCenter
        observers.append(nc.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor in
                TunnelManager.shared.reconnectActive()
            }
        })
    }
}
