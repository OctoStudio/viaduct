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
            Rectangle().fill(ViaductStyle.hairline).frame(height: 0.5)
            searchBar
            Rectangle().fill(ViaductStyle.hairline).frame(height: 0.5)
            tunnelList
            Rectangle().fill(ViaductStyle.hairline).frame(height: 0.5)
            menuFooter
        }
        .frame(width: 320)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .preferredColorScheme(AppAppearance(rawValue: appearance)?.colorScheme)
        .onAppear { appState.reload() }
    }

    // MARK: - Header

    private var menuHeader: some View {
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 5)
                .fill(ViaductStyle.accent)
                .frame(width: 18, height: 18)
                .overlay {
                    Image(systemName: "network")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.white)
                }

            Text("Viaduct")
                .font(.system(size: 13, weight: .semibold))

            Spacer()

            Text("\(connectedCount)/\(appState.tunnels.count) active")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)

            Button(action: { WindowManager.shared.openMain() }) {
                Image(systemName: "arrow.up.right.square")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help("Open Viaduct")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
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
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color(.controlBackgroundColor).opacity(0.18))
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
                                .padding(.leading, 40)
                        }
                    }
                }
            }
        }
        .frame(maxHeight: 340)
    }

    // MARK: - Footer

    private var menuFooter: some View {
        HStack {
            Button(action: { WindowManager.shared.openNewTunnelEditor() }) {
                Label("New Tunnel", systemImage: "plus")
                    .font(.system(size: 11.5))
            }
            .buttonStyle(.plain)
            .foregroundStyle(ViaductStyle.accent)

            Spacer()

            SettingsLink {
                Text("Settings")
                    .font(.system(size: 11.5))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)

            Button("Quit") { NSApp.terminate(nil) }
                .buttonStyle(.plain)
                .font(.system(size: 11.5))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
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
        HStack(spacing: 10) {
            StatusDot(state: state)

            VStack(alignment: .leading, spacing: 2) {
                Text(tunnel.name)
                    .font(.system(size: 12.5, weight: .semibold))
                    .lineLimit(1)
                Text(compactRoute)
                    .font(.system(size: 10.5, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Button(isRunning ? "Stop" : "Connect") {
                AppState.shared.toggleTunnel(tunnel)
            }
            .buttonStyle(.plain)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(isRunning ? ViaductStyle.danger : ViaductStyle.accent)
            .padding(.horizontal, 10)
            .frame(height: 22)
            .background {
                Capsule()
                    .fill(isRunning ? ViaductStyle.danger.opacity(0.12) : ViaductStyle.accent.opacity(0.12))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }

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
