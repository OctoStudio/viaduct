import AppKit
import SwiftUI

@MainActor
final class WindowManager {
    static let shared = WindowManager()
    private let mainWindowDelegate = MainWindowDelegate()
    private var mainWindow: NSWindow?

    private init() {}

    func openMain() {
        if let existing = mainWindow {
            existing.makeKeyAndOrderFront(nil)
            activate()
            return
        }
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1420, height: 760),
            styleMask: [.titled, .closable, .resizable, .miniaturizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.identifier = NSUserInterfaceItemIdentifier("ViaductMain")
        window.title = "Viaduct"
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isReleasedWhenClosed = false
        window.delegate = mainWindowDelegate
        window.center()
        window.contentView = NSHostingView(rootView: MainWindowView())
        mainWindow = window
        window.makeKeyAndOrderFront(nil)
        activate()
    }

    // Opens main window then presents the new-tunnel editor once the view hierarchy is ready.
    func openNewTunnelEditor() {
        AppState.shared.editingTunnel = nil
        openMain()
        // Give SwiftUI one runloop cycle to attach the .sheet modifier before firing it.
        DispatchQueue.main.async {
            AppState.shared.isEditorPresented = true
        }
    }

    func openSettingsPage() {
        AppState.shared.selectedSidebarItem = .settings
        openMain()
    }

    private func activate() {
        // activate(ignoringOtherApps:) is deprecated on 14+ but is the correct call
        // for an LSUIElement accessory app that needs to pull itself to front.
        NSApp.activate(ignoringOtherApps: true)
    }
}

private final class MainWindowDelegate: NSObject, NSWindowDelegate {
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        sender.orderOut(nil)
        return false
    }
}
