import SwiftUI
import ServiceManagement

@main
struct ViaductApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @AppStorage(AppSettings.appearanceKey) private var appearance = AppAppearance.system.rawValue

    var body: some Scene {
        Settings {
            SettingsView()
                .preferredColorScheme(AppAppearance(rawValue: appearance)?.colorScheme)
        }
    }
}

enum AppSettings {
    static let appearanceKey = "settings.appearance"
    static let openAtLoginKey = "settings.openAtLogin"
    static let connectAtLoginKey = "settings.connectAtLogin"

    static func registerDefaults() {
        UserDefaults.standard.register(defaults: [
            appearanceKey: AppAppearance.system.rawValue,
            openAtLoginKey: false,
            connectAtLoginKey: true
        ])
    }
}

enum AppAppearance: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppSettings.registerDefaults()
        NSApp.setActivationPolicy(.accessory)
        _ = appDatabase
        Task { @MainActor in AppState.shared.loadAll() }
        NetworkMonitor.shared.start()
        SleepWakeMonitor.shared.start()
        if UserDefaults.standard.bool(forKey: AppSettings.connectAtLoginKey) {
            Task { @MainActor in TunnelManager.shared.launchAutoConnectTunnels() }
        }
        statusBarController = StatusBarController()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag { Task { @MainActor in WindowManager.shared.openMain() } }
        return true
    }
}

struct SettingsView: View {
    @AppStorage(AppSettings.appearanceKey) private var appearance = AppAppearance.system.rawValue
    @AppStorage(AppSettings.connectAtLoginKey) private var connectAtLogin = true
    @State private var openAtLogin = SMAppService.mainApp.status == .enabled
    @State private var loginItemError: String?

    var body: some View {
        TabView {
            Form {
                Picker("Appearance", selection: $appearance) {
                    ForEach(AppAppearance.allCases) { option in
                        Text(option.label).tag(option.rawValue)
                    }
                }
                .pickerStyle(.segmented)

                Toggle("Open Viaduct at login", isOn: $openAtLogin)
                    .onChange(of: openAtLogin) { _, enabled in
                        updateOpenAtLogin(enabled)
                    }

                Toggle("Connect auto-connect tunnels at login", isOn: $connectAtLogin)

                if let loginItemError {
                    Text(loginItemError)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            .formStyle(.grouped)
            .padding(20)
            .frame(width: 430, height: 220)
            .tabItem {
                Label("General", systemImage: "gearshape")
            }

            Form {
                LabeledContent("Auto-connect") {
                    Text("Per-tunnel setting")
                        .foregroundStyle(.secondary)
                }
                LabeledContent("Reconnect") {
                    Text("Network and wake events")
                        .foregroundStyle(.secondary)
                }
                Text("Tunnel defaults are configured per tunnel. Use the editor's Behavior section to choose which tunnels connect automatically.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .formStyle(.grouped)
            .padding(20)
            .frame(width: 430, height: 220)
            .tabItem {
                Label("Tunnels", systemImage: "point.3.connected.trianglepath.dotted")
            }
        }
    }

    private func updateOpenAtLogin(_ enabled: Bool) {
        loginItemError = nil
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            loginItemError = error.localizedDescription
            openAtLogin = SMAppService.mainApp.status == .enabled
        }
    }
}
