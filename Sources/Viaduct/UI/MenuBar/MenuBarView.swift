import SwiftUI

struct MenuBarView: View {
    @State private var appState = AppState.shared
    @State private var tunnelManager = TunnelManager.shared
    @State private var searchText = ""

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "point.3.connected.trianglepath.dotted")
                    .foregroundStyle(globalStatusColor)
                Text("Viaduct")
                    .fontWeight(.semibold)
                Spacer()
                Button(action: openMainWindow) {
                    Text("Open Viaduct")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search tunnels…", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.callout)
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                    }
                    .buttonStyle(.borderless)
                    .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.background.opacity(0.5))

            Divider()

            // Tunnel list
            ScrollView {
                LazyVStack(spacing: 0) {
                    let filtered = filteredTunnels
                    if filtered.isEmpty {
                        Text(searchText.isEmpty ? "No tunnels configured" : "No results")
                            .foregroundStyle(.secondary)
                            .font(.callout)
                            .frame(maxWidth: .infinity)
                            .padding(24)
                    } else {
                        ForEach(filtered) { tunnel in
                            MenuBarTunnelRow(tunnel: tunnel)
                            if tunnel.id != filtered.last?.id {
                                Divider().padding(.leading, 12)
                            }
                        }
                    }
                }
            }
            .frame(maxHeight: 320)

            Divider()

            // Footer
            HStack {
                Button(action: newTunnel) {
                    Label("New Tunnel", systemImage: "plus")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
                Spacer()
                Button("Quit") { NSApp.terminate(nil) }
                    .buttonStyle(.borderless)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .onAppear { appState.reload() }
    }

    private var filteredTunnels: [Tunnel] {
        if searchText.isEmpty { return appState.tunnels }
        let q = searchText.lowercased()
        return appState.tunnels.filter {
            $0.name.lowercased().contains(q) || $0.host.lowercased().contains(q)
        }
    }

    private var globalStatusColor: Color {
        switch tunnelManager.globalStatus {
        case .allConnected: return .green
        case .someErrors:   return .red
        case .mixed:        return .yellow
        case .allStopped:   return .secondary
        }
    }

    private func openMainWindow() {
        WindowManager.shared.openMain()
    }

    private func newTunnel() {
        WindowManager.shared.openNewTunnelEditor()
    }
}

struct MenuBarTunnelRow: View {
    let tunnel: Tunnel
    @State private var tunnelManager = TunnelManager.shared

    private var state: TunnelState { tunnelManager.state(for: tunnel.id) }
    private var isRunning: Bool {
        switch state {
        case .stopped, .idle, .failed: return false
        default: return true
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            StatusDot(state: state)

            VStack(alignment: .leading, spacing: 1) {
                Text(tunnel.name)
                    .font(.callout)
                    .lineLimit(1)
                Text("\(tunnel.host):\(tunnel.port)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Toggle("", isOn: Binding(
                get: { isRunning },
                set: { _ in AppState.shared.toggleTunnel(tunnel) }
            ))
            .toggleStyle(.switch)
            .labelsHidden()
            .controlSize(.small)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }
}
