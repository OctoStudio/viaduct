import SwiftUI

struct TunnelListView: View {
    @State private var appState = AppState.shared
    @State private var tunnelManager = TunnelManager.shared
    @State private var sortOrder: SortOrder = .name

    enum SortOrder: String, CaseIterable {
        case name = "Name"
        case host = "Host"
        case status = "Status"
    }

    var sortedTunnels: [Tunnel] {
        appState.filteredTunnels.sorted {
            switch sortOrder {
            case .name:   return $0.name < $1.name
            case .host:   return $0.host < $1.host
            case .status: return stateRank($0) < stateRank($1)
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                TextField("Search", text: $appState.searchText)
                    .textFieldStyle(.plain)
                if !appState.searchText.isEmpty {
                    Button(action: { appState.searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                    }
                    .buttonStyle(.borderless)
                    .foregroundStyle(.secondary)
                }
                Spacer()
                Picker("Sort", selection: $sortOrder) {
                    ForEach(SortOrder.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .controlSize(.small)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.bar)

            Divider()

            if sortedTunnels.isEmpty {
                emptyState
            } else {
                List(sortedTunnels, selection: $appState.selectedTunnelID) { tunnel in
                    TunnelListRow(tunnel: tunnel)
                        .tag(tunnel.id)
                        .contextMenu { tunnelContextMenu(tunnel) }
                }
                .listStyle(.plain)
            }
        }
        .navigationSplitViewColumnWidth(min: 240, ideal: 280)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "rectangle.connected.to.line.below")
                .font(.system(size: 36))
                .foregroundStyle(.tertiary)
            Text(appState.searchText.isEmpty ? "No tunnels" : "No results")
                .foregroundStyle(.secondary)
            if appState.searchText.isEmpty {
                Button("Add Tunnel") {
                    appState.editingTunnel = nil
                    appState.isEditorPresented = true
                }
                .buttonStyle(.borderless)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private func tunnelContextMenu(_ tunnel: Tunnel) -> some View {
        let state = tunnelManager.state(for: tunnel.id)
        let isRunning: Bool = { if case .stopped = state { return false }
            if case .idle = state { return false }
            if case .failed = state { return false }
            return true }()

        if isRunning {
            Button("Stop") { TunnelManager.shared.stop(tunnelID: tunnel.id) }
        } else {
            Button("Connect") { TunnelManager.shared.start(tunnel: tunnel) }
        }
        Button("Restart") { TunnelManager.shared.restart(tunnelID: tunnel.id) }
        Divider()
        Button("Edit…") {
            appState.editingTunnel = tunnel
            appState.isEditorPresented = true
        }
        Divider()
        Button("Delete", role: .destructive) { appState.deleteTunnel(tunnel) }
    }

    private func stateRank(_ tunnel: Tunnel) -> Int {
        switch tunnelManager.state(for: tunnel.id) {
        case .connected: return 0
        case .connecting: return 1
        case .reconnecting: return 2
        case .failed: return 3
        case .idle: return 4
        case .stopped: return 5
        }
    }
}

struct TunnelListRow: View {
    let tunnel: Tunnel
    @State private var tunnelManager = TunnelManager.shared

    var body: some View {
        let state = tunnelManager.state(for: tunnel.id)
        HStack(spacing: 8) {
            StatusDot(state: state)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(tunnel.name)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    typeBadge
                }
                HStack(spacing: 4) {
                    Text(tunnel.host)
                        .foregroundStyle(.secondary)
                        .font(.caption)
                    if let lp = tunnel.localPort {
                        // Use verbatim: to prevent macOS from adding thousands separators
                        Text(verbatim: ":\(lp)")
                            .foregroundStyle(.tertiary)
                            .font(.caption)
                    }
                }
            }

            Spacer()

            if case .failed(let msg) = state {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                    .help(msg)
            }
        }
        .padding(.vertical, 2)
    }

    @ViewBuilder
    private var typeBadge: some View {
        let (label, color): (String, Color) = switch tunnel.type {
        case .local:   ("L", .blue)
        case .remote:  ("R", .purple)
        case .dynamic: ("D", .orange)
        }
        Text(label)
            .font(.caption2)
            .fontWeight(.bold)
            .foregroundStyle(.white)
            .padding(.horizontal, 4)
            .padding(.vertical, 1)
            .background(color, in: RoundedRectangle(cornerRadius: 3))
    }
}
