import SwiftUI

struct MenuBarView: View {
    @State private var appState = AppState.shared
    @State private var tunnelManager = TunnelManager.shared
    @State private var searchText = ""
    @AppStorage(AppSettings.appearanceKey) private var appearance = AppAppearance.system.rawValue

    private var filteredTunnels: [Tunnel] {
        guard !searchText.isEmpty else { return appState.tunnels }
        let q = searchText.lowercased()
        return appState.tunnels.filter {
            $0.name.lowercased().contains(q) || $0.host.lowercased().contains(q)
        }
    }

    private var connectedCount: Int {
        appState.tunnels.filter {
            if case .connected = tunnelManager.state(for: $0.id) { return true }
            return false
        }.count
    }

    var body: some View {
        VStack(spacing: 0) {
            menuHeader
            searchBar
            tunnelList
            menuFooter
        }
        .padding(28)
        .frame(width: 400)
        .background(ViaductStyle.detailBackground, in: RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(ViaductStyle.hairline, lineWidth: 1)
        }
        .preferredColorScheme(AppAppearance(rawValue: appearance)?.colorScheme)
        .onAppear { appState.reload() }
    }

    // MARK: - Header

    private var menuHeader: some View {
        HStack(spacing: 12) {

            Text("Viaduct")
                .font(.system(size: 22, weight: .bold))

            Spacer()

            HStack(spacing: 8) {
                Circle().fill(ViaductStyle.success).frame(width: 8, height: 8)
                Text("\(connectedCount) live")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .textCase(.uppercase)
            }
            .foregroundStyle(.secondary)
            .padding(.horizontal, 13)
            .frame(height: 32)
            .background(ViaductStyle.tagGreenBackground, in: Capsule())
            .overlay { Capsule().strokeBorder(ViaductStyle.success.opacity(0.25), lineWidth: 1) }

            Button(action: { WindowManager.shared.openMain() }) {
                Image(systemName: "arrow.up.right.square")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help("Open Viaduct")
        }
        .padding(.bottom, 20)
    }

    // MARK: - Search

    private var searchBar: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
            TextField("Search tunnels…", text: $searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 12))
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 18)
        .frame(height: 42)
        .background(ViaductStyle.input, in: RoundedRectangle(cornerRadius: ViaductStyle.fieldCorner))
        .overlay {
            RoundedRectangle(cornerRadius: ViaductStyle.fieldCorner)
                .strokeBorder(ViaductStyle.hairline, lineWidth: 0.5)
        }
        .padding(.bottom, 18)
    }

    // MARK: - Tunnel list

    private var tunnelList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                let tunnels = filteredTunnels
                if tunnels.isEmpty {
                    VStack(spacing: 8) {
                        Text(searchText.isEmpty ? "No tunnels configured" : "No results")
                            .foregroundStyle(.secondary)
                            .font(.system(size: 12))
                        Button(searchText.isEmpty ? "New Tunnel" : "Clear Search") {
                            if searchText.isEmpty { WindowManager.shared.openNewTunnelEditor() }
                            else { searchText = "" }
                        }
                        .buttonStyle(.plain)
                        .font(.system(size: 11.5))
                        .foregroundStyle(ViaductStyle.accent)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(24)
                } else {
                    ForEach(tunnels) { tunnel in
                        MenuBarTunnelRow(tunnel: tunnel)
                        if tunnel.id != tunnels.last?.id {
                            Rectangle()
                                .fill(ViaductStyle.hairline)
                                .frame(height: 0.5)
                        }
                    }
                }
            }
        }
        .frame(maxHeight: 500)
    }

    // MARK: - Footer

    private var menuFooter: some View {
        HStack(spacing: 16) {
            Button(action: { WindowManager.shared.openNewTunnelEditor() }) {
                Text("New Tunnel")
                    .font(.system(size: 14, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 42)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white)
            .background(ViaductStyle.accent, in: RoundedRectangle(cornerRadius: 8))

            Button {
                WindowManager.shared.openMain()
            } label: {
                Text("Open App")
                    .font(.system(size: 14, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .frame(height: 42)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.primary)
            .background(ViaductStyle.cardBackground, in: RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(ViaductStyle.hairline, lineWidth: 0.5)
            }

            Button(action: { NSApp.terminate(nil) }) {
                Image(systemName: "power")
                    .font(.system(size: 13, weight: .semibold))
                    .frame(width: 42, height: 42)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
        }
        .padding(.top, 18)
    }

    // MARK: - Helpers

    private var globalStatusColor: Color {
        switch tunnelManager.globalStatus {
        case .allConnected: return Color(red: 0.17, green: 0.82, blue: 0.35)
        case .someErrors:   return Color(red: 0.90, green: 0.25, blue: 0.23)
        case .mixed:        return Color(red: 1.0, green: 0.62, blue: 0.04)
        case .allStopped:   return Color(.tertiaryLabelColor)
        }
    }

}

struct MenuBarTunnelRow: View {
    let tunnel: Tunnel
    @State private var tunnelManager = TunnelManager.shared

    private var state: TunnelState { tunnelManager.state(for: tunnel.id) }
    private var isRunning: Bool {
        switch state { case .stopped, .idle, .failed: false; default: true }
    }

    var body: some View {
        HStack(spacing: 16) {
            StatusDot(state: state)

            VStack(alignment: .leading, spacing: 2) {
                Text(tunnel.name)
                    .font(.system(size: 16, weight: .bold))
                    .lineLimit(1)
                Text(compactRoute)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            if case .reconnecting = state {
                Button("Stop") {
                    TunnelManager.shared.stop(tunnelID: tunnel.id)
                }
                .menuBarButton(color: ViaductStyle.danger)

                Button("Retry") {
                    TunnelManager.shared.retry(tunnelID: tunnel.id)
                }
                .menuBarButton(color: ViaductStyle.warning)
            } else {
                Button(buttonTitle) {
                    if case .failed = state {
                        TunnelManager.shared.retry(tunnelID: tunnel.id)
                    } else {
                        AppState.shared.toggleTunnel(tunnel)
                    }
                }
                .menuBarButton(color: buttonColor)
            }
        }
        .padding(.vertical, 18)
        .contentShape(Rectangle())
    }

    private var buttonTitle: String {
        switch state {
        case .reconnecting, .failed: return "Retry"
        default: return isRunning ? "Stop" : "Start"
        }
    }

    private var buttonColor: Color {
        switch state {
        case .reconnecting, .failed: return ViaductStyle.warning
        default: return isRunning ? ViaductStyle.danger : ViaductStyle.accent
        }
    }

    // Only used when state is not .reconnecting
    private var compactRoute: String {
        let bind = tunnel.bindAddress.flatMap { $0.isEmpty ? nil : $0 } ?? "127.0.0.1"
        switch tunnel.type {
        case .local:
            guard let lp = tunnel.localPort, let rh = tunnel.remoteHost, let rp = tunnel.remotePort else { return tunnel.host }
            return "\(bind):\(lp) → \(rh):\(rp)"
        case .remote:
            guard let rp = tunnel.remotePort, let lp = tunnel.localPort else { return tunnel.host }
            return "\(tunnel.host):\(rp) → localhost:\(lp)"
        case .dynamic:
            guard let lp = tunnel.localPort else { return tunnel.host }
            return "SOCKS \(bind):\(lp)"
        }
    }
}

private extension View {
    func menuBarButton(color: Color) -> some View {
        self
            .buttonStyle(.plain)
            .font(.system(size: 11, weight: .bold, design: .monospaced))
            .foregroundStyle(color)
            .textCase(.uppercase)
            .padding(.horizontal, 16)
            .frame(height: 34)
            .background { Capsule().fill(color.opacity(0.10)) }
            .overlay { Capsule().strokeBorder(color.opacity(0.22), lineWidth: 0.8) }
    }
}
