import SwiftUI

@main
struct ViaductApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings { EmptyView() }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        _ = appDatabase
        Task { @MainActor in AppState.shared.loadAll() }
        NetworkMonitor.shared.start()
        SleepWakeMonitor.shared.start()
        Task { @MainActor in TunnelManager.shared.launchAutoConnectTunnels() }
        statusBarController = StatusBarController()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag { Task { @MainActor in WindowManager.shared.openMain() } }
        return true
    }
}
