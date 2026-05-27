import AppKit
import SwiftUI

final class StatusBarController {
    private var statusItem: NSStatusItem
    private var popover: NSPopover
    private var eventMonitor: Any?

    init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        popover = NSPopover()
        popover.contentSize = NSSize(width: 340, height: 440)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: MenuBarView())

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "point.3.connected.trianglepath.dotted", accessibilityDescription: "Viaduct")
            button.action = #selector(togglePopover)
            button.target = self
        }

        // Update icon when state changes
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.updateIcon()
        }
    }

    @objc private func togglePopover() {
        if popover.isShown {
            closePopover()
        } else {
            openPopover()
        }
    }

    private func openPopover() {
        guard let button = statusItem.button else { return }
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.closePopover()
        }
    }

    private func closePopover() {
        popover.performClose(nil)
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }

    private func updateIcon() {
        Task { @MainActor in
            let status = TunnelManager.shared.globalStatus
            let (symbolName, tint): (String, NSColor) = switch status {
            case .allConnected:  ("point.3.connected.trianglepath.dotted", .systemGreen)
            case .someErrors:    ("point.3.connected.trianglepath.dotted", .systemRed)
            case .mixed:         ("point.3.connected.trianglepath.dotted", .systemYellow)
            case .allStopped:    ("point.3.connected.trianglepath.dotted", .tertiaryLabelColor)
            }
            let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "Viaduct")
            image?.isTemplate = false
            self.statusItem.button?.image = image?.withTintColor(tint)
        }
    }
}

private extension NSImage {
    func withTintColor(_ color: NSColor) -> NSImage {
        let img = self.copy() as! NSImage
        img.lockFocus()
        color.set()
        let rect = NSRect(origin: .zero, size: img.size)
        rect.fill(using: .sourceAtop)
        img.unlockFocus()
        return img
    }
}
