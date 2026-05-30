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
    var body: some View {
        SettingsContent()
            .padding(32)
            .frame(width: 620, height: 420)
            .background(ViaductStyle.detailBackground)
    }
}

struct MainSettingsView: View {
    @State private var appState = AppState.shared

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Text("Settings")
                    .font(.system(size: 24, weight: .bold))
                Spacer()
                Button {
                    appState.selectedSidebarItem = .allTunnels
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                }
                .buttonStyle(DetailIconButtonStyle())
                .help("Close Settings")
            }
            .padding(.horizontal, 46)
            .frame(height: ViaductStyle.titlebarHeight)
            .background(ViaductStyle.titlebarBackground)
            .overlay(alignment: .bottom) { Rectangle().fill(ViaductStyle.hairlineSoft).frame(height: 0.5) }

            ScrollView {
                SettingsContent()
                    .padding(.horizontal, 46)
                    .padding(.top, 34)
                    .padding(.bottom, 40)
                    .frame(maxWidth: 860, alignment: .topLeading)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
            }
        }
        .background(ViaductStyle.detailBackground)
    }
}

private struct SettingsContent: View {
    @AppStorage(AppSettings.appearanceKey) private var appearance = AppAppearance.system.rawValue
    @AppStorage(AppSettings.connectAtLoginKey) private var connectAtLogin = true
    @State private var openAtLogin = SMAppService.mainApp.status == .enabled
    @State private var loginItemError: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            SettingsCard(title: "General") {
                SettingsPickerRow(label: "Appearance") {
                    Picker("", selection: $appearance) {
                        ForEach(AppAppearance.allCases) { option in
                            Text(option.label).tag(option.rawValue)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                    .frame(width: 260)
                }

                SettingsToggleRow(
                    label: "Open at login",
                    isOn: $openAtLogin
                )
                .onChange(of: openAtLogin) { _, enabled in
                    updateOpenAtLogin(enabled)
                }

                SettingsToggleRow(
                    label: "Connect at login",
                    isOn: $connectAtLogin,
                    last: loginItemError == nil
                )

                if let loginItemError {
                    SettingsTextRow(label: "Login item", value: loginItemError, isError: true, last: true)
                }
            }

            SettingsCard(title: "Tunnels") {
                SettingsTextRow(label: "Auto-connect", value: "Per-tunnel setting")
                SettingsTextRow(label: "Reconnect", value: "Network and wake events")
                SettingsTextRow(
                    label: "Defaults",
                    value: "Configure launch behavior from each tunnel's editor.",
                    last: true
                )
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

private struct SettingsCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.uppercased())
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundStyle(.tertiary)
                .tracking(0.6)

            VStack(spacing: 0) {
                content
            }
            .background(ViaductStyle.cardBackground, in: RoundedRectangle(cornerRadius: ViaductStyle.cardCorner))
            .overlay {
                RoundedRectangle(cornerRadius: ViaductStyle.cardCorner)
                    .strokeBorder(ViaductStyle.hairline, lineWidth: 0.5)
            }
        }
    }
}

private struct SettingsPickerRow<Control: View>: View {
    let label: String
    var last = false
    @ViewBuilder let control: Control

    var body: some View {
        SettingsRow(label: label, last: last) {
            control
        }
    }
}

private struct SettingsToggleRow: View {
    let label: String
    @Binding var isOn: Bool
    var last = false

    var body: some View {
        SettingsRow(label: label, last: last) {
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .toggleStyle(.switch)
        }
    }
}

private struct SettingsTextRow: View {
    let label: String
    let value: String
    var isError = false
    var last = false

    var body: some View {
        SettingsRow(label: label, last: last) {
            Text(value)
                .font(.system(size: 12.5))
                .foregroundStyle(isError ? ViaductStyle.danger : .secondary)
                .lineLimit(2)
                .multilineTextAlignment(.trailing)
        }
    }
}

private struct SettingsRow<Content: View>: View {
    let label: String
    var last = false
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 12) {
                Text(label)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(width: 150, alignment: .leading)
                    .fixedSize()

                Spacer(minLength: 12)

                content
            }
            .padding(.horizontal, 18)
            .frame(minHeight: 54)

            if !last {
                Divider().padding(.leading, 14)
            }
        }
    }
}
