import SwiftUI

struct TunnelListView: View {
    @State private var appState = AppState.shared
    @State private var tunnelManager = TunnelManager.shared
    @State private var sortOrder: SortOrder = .name
    @State private var pendingDelete: Tunnel?

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
            listToolbar

            if sortedTunnels.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(sortedTunnels) { tunnel in
                            TunnelListRow(tunnel: tunnel, isSelected: appState.selectedTunnelID == tunnel.id)
                                .contentShape(Rectangle())
                                .onTapGesture { appState.selectedTunnelID = tunnel.id }
                                .contextMenu { tunnelContextMenu(tunnel) }

                            if tunnel.id != sortedTunnels.last?.id {
                                Divider().padding(.leading, 44)
                            }
                        }
                    }
                }
                .background(ViaductStyle.listBackground)
            }

            listFooter
        }
        .background(ViaductStyle.listBackground)
        .overlay(alignment: .trailing) { Rectangle().fill(ViaductStyle.hairline).frame(width: 0.5) }
        .frame(width: ViaductStyle.listWidth)
        .confirmationDialog(
            "Delete Tunnel?",
            isPresented: Binding(get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } }),
            titleVisibility: .visible
        ) {
            if let tunnel = pendingDelete {
                Button("Delete \(tunnel.name)", role: .destructive) {
                    appState.deleteTunnel(tunnel)
                    pendingDelete = nil
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            if let tunnel = pendingDelete {
                let running = isRunning(tunnelManager.state(for: tunnel.id))
                Text("This removes the saved tunnel, its tags, and connection log.\(running ? " The tunnel is currently running and will be stopped first." : "")")
            }
        }
    }

    // MARK: - Toolbar

    private var listToolbar: some View {
        HStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.tertiary)
                    .font(.system(size: 12))

                TextField("Search", text: $appState.searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))

                if !appState.searchText.isEmpty {
                    Button(action: { appState.searchText = "" }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.tertiary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .frame(height: 38)
            .background(ViaductStyle.input, in: RoundedRectangle(cornerRadius: ViaductStyle.fieldCorner))
            .overlay {
                RoundedRectangle(cornerRadius: ViaductStyle.fieldCorner)
                    .strokeBorder(ViaductStyle.hairline, lineWidth: 0.5)
            }

            Menu {
                ForEach(SortOrder.allCases, id: \.self) { order in
                    Button {
                        sortOrder = order
                    } label: {
                        if sortOrder == order {
                            Label(order.rawValue, systemImage: "checkmark")
                        } else {
                            Text(order.rawValue)
                        }
                    }
                }
            } label: {
                HStack(spacing: 2) {
                    Text(sortOrder.rawValue)
                        .font(.system(size: 11))
                    Image(systemName: "chevron.down")
                        .font(.system(size: 8, weight: .semibold))
                }
                .foregroundStyle(.secondary)
                .frame(height: 34)
                .padding(.horizontal, 9)
                .background(ViaductStyle.cardBackground, in: RoundedRectangle(cornerRadius: 8))
            }
            .menuStyle(.button)
            .buttonStyle(.plain)

            Button(action: {
                appState.editingTunnel = nil
                appState.isEditorPresented = true
            }) {
                Image(systemName: "plus")
                    .font(.system(size: 13, weight: .medium))
                    .frame(width: 34, height: 34)
                    .background(ViaductStyle.cardBackground, in: RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            .help("New Tunnel (⌘N)")
        }
        .padding(.horizontal, 22)
        .frame(height: ViaductStyle.titlebarHeight)
        .background(ViaductStyle.titlebarBackground)
        .overlay(alignment: .bottom) { Rectangle().fill(ViaductStyle.hairlineSoft).frame(height: 0.5) }
    }

    // MARK: - Footer

    private var listFooter: some View {
        HStack {
            Text("\(sortedTunnels.count) \(sortedTunnels.count == 1 ? "tunnel" : "tunnels")")
                .font(.system(size: 10.5))
                .foregroundStyle(.tertiary)
            Spacer()
        }
        .frame(height: 24)
        .padding(.horizontal, 22)
        .overlay(alignment: .top) { Rectangle().fill(ViaductStyle.hairlineSoft).frame(height: 0.5) }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "rectangle.connected.to.line.below")
                .font(.system(size: 32))
                .foregroundStyle(.tertiary)
            VStack(spacing: 4) {
                Text(appState.searchText.isEmpty ? "No Tunnels" : "No Results")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
                Text(appState.searchText.isEmpty ? "Press ⌘N to add one" : "Try a different search")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Context menu

    @ViewBuilder
    private func tunnelContextMenu(_ tunnel: Tunnel) -> some View {
        let state = tunnelManager.state(for: tunnel.id)
        let running = isRunning(state)
        Button(running ? "Stop" : "Connect") {
            if case .failed = state {
                TunnelManager.shared.retry(tunnelID: tunnel.id)
            } else {
                appState.toggleTunnel(tunnel)
            }
        }
        Button("Restart") { TunnelManager.shared.retry(tunnelID: tunnel.id) }
        Divider()
        Button("Edit…") {
            appState.editingTunnel = tunnel
            appState.isEditorPresented = true
        }
        Divider()
        Button("Delete", role: .destructive) { pendingDelete = tunnel }
    }

    // MARK: - Helpers

    private func isRunning(_ state: TunnelState) -> Bool {
        switch state { case .stopped, .idle, .failed: false; default: true }
    }

    private func stateRank(_ tunnel: Tunnel) -> Int {
        switch tunnelManager.state(for: tunnel.id) {
        case .connected: 0; case .connecting: 1; case .reconnecting: 2
        case .failed: 3; case .idle: 4; case .stopped: 5
        }
    }
}

// MARK: - List row

struct TunnelListRow: View {
    let tunnel: Tunnel
    let isSelected: Bool
    @State private var tunnelManager = TunnelManager.shared

    var body: some View {
        let state = tunnelManager.state(for: tunnel.id)
        let running = isRunning(state)

        HStack(alignment: .top, spacing: 14) {
            StatusDot(state: state)
                .padding(.top, 8)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(tunnel.name)
                        .font(.system(size: 19, weight: .bold))
                        .lineLimit(1)
                    Spacer(minLength: 0)
                    TypeChip(type: tunnel.type, isSelected: isSelected)
                }

                Text(compactRoute)
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                HStack(spacing: 5) {
                    Text(tunnel.host)
                        .font(.system(size: 10.5))
                        .foregroundStyle(Color(.tertiaryLabelColor))
                    stateInfo(state, isSelected: isSelected)
                }
            }

            Spacer(minLength: 0)

            Button {
                if case .failed = state {
                    TunnelManager.shared.retry(tunnelID: tunnel.id)
                } else {
                    AppState.shared.toggleTunnel(tunnel)
                }
            } label: {
                Image(systemName: running ? "stop.fill" : "play.fill")
                    .font(.system(size: 8, weight: .medium))
                    .foregroundStyle(running ? ViaductStyle.danger : ViaductStyle.accent)
                    .frame(width: 22, height: 22)
                    .background {
                        Circle()
                            .fill(running ? ViaductStyle.danger.opacity(0.12) : ViaductStyle.accent.opacity(0.12))
                    }
            }
            .buttonStyle(.plain)
            .contentShape(Circle())
        }
        .foregroundStyle(.primary)
        .padding(.vertical, 18)
        .padding(.horizontal, 20)
        .background(isSelected ? ViaductStyle.selectedListBackground : Color.clear, in: RoundedRectangle(cornerRadius: 10))
        .overlay {
            if isSelected {
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(ViaductStyle.selectedListBorder, lineWidth: 1)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 4)
    }

    private var compactRoute: String {
        let bind = tunnel.bindAddress.flatMap { $0.isEmpty ? nil : $0 } ?? "127.0.0.1"
        switch tunnel.type {
        case .local:
            guard let lp = tunnel.localPort, let rh = tunnel.remoteHost, let rp = tunnel.remotePort else { return "Incomplete" }
            return "\(bind):\(lp)  →  \(rh):\(rp)"
        case .remote:
            guard let rp = tunnel.remotePort, let lp = tunnel.localPort else { return "Incomplete" }
            let target = tunnel.remoteHost.flatMap { $0.isEmpty ? nil : $0 } ?? "localhost"
            return "\(tunnel.host):\(rp)  →  \(target):\(lp)"
        case .dynamic:
            guard let lp = tunnel.localPort else { return "Incomplete" }
            return "SOCKS  \(bind):\(lp)"
        }
    }

    @ViewBuilder
    private func stateInfo(_ state: TunnelState, isSelected: Bool) -> some View {
        switch state {
        case .connected:
            if let connectedAt = tunnelManager.connectedAt(for: tunnel.id) {
                Text("·").font(.system(size: 10.5)).foregroundStyle(Color(.quaternaryLabelColor))
                TimelineView(.periodic(from: connectedAt, by: 60)) { ctx in
                    Text("up \(formatUptime(from: connectedAt, to: ctx.date))")
                        .font(.system(size: 10.5).monospacedDigit())
                        .foregroundStyle(Color(.tertiaryLabelColor))
                }
            }
        case .connecting:
            Text("·").font(.system(size: 10.5)).foregroundStyle(Color(.quaternaryLabelColor))
            Text("Connecting…")
                .font(.system(size: 10.5))
                .foregroundStyle(ViaductStyle.warning)
        case .reconnecting(let n):
            Text("·").font(.system(size: 10.5)).foregroundStyle(Color(.quaternaryLabelColor))
            Text("Reconnecting (attempt \(n))…")
                .font(.system(size: 10.5))
                .foregroundStyle(ViaductStyle.warning)
        case .failed:
            Text("·").font(.system(size: 10.5)).foregroundStyle(Color(.quaternaryLabelColor))
            Text("Connection failed")
                .font(.system(size: 10.5, weight: .medium))
                .foregroundStyle(ViaductStyle.danger)
        default:
            EmptyView()
        }
    }

    private func isRunning(_ state: TunnelState) -> Bool {
        switch state { case .stopped, .idle, .failed: false; default: true }
    }
}

// MARK: - Type chip

struct TypeChip: View {
    let type: TunnelType
    var isSelected = false

    var body: some View {
        Text(type.typeLabel)
            .font(.system(size: 10, weight: .semibold))
            .tracking(0.3)
            .padding(.horizontal, 6)
            .padding(.vertical, 1.5)
            .background(isSelected ? Color.white.opacity(0.32) : ViaductStyle.chip)
            .foregroundStyle(.secondary)
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

// MARK: - Uptime helper

func formatUptime(from start: Date, to now: Date = Date()) -> String {
    let sec = max(0, Int(now.timeIntervalSince(start)))
    if sec < 60  { return "\(sec)s" }
    if sec < 3600 { return "\(sec / 60)m" }
    if sec < 86400 { return "\(sec / 3600)h \((sec % 3600) / 60)m" }
    return "\(sec / 86400)d \((sec % 86400) / 3600)h"
}
