import SwiftUI

struct TunnelDetailView: View {
    @State private var appState = AppState.shared
    @State private var tunnelManager = TunnelManager.shared

    private var tunnel: Tunnel? {
        guard let id = appState.selectedTunnelID else { return nil }
        return appState.tunnels.first(where: { $0.id == id })
    }

    var body: some View {
        if let tunnel {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    tunnelHeader(tunnel)
                    connectionDetails(tunnel)
                    forwardingDetails(tunnel)
                    authDetails(tunnel)
                    logSection(tunnel)
                }
                .padding(20)
            }
            .navigationTitle(tunnel.name)
            .toolbar {
                tunnelToolbar(tunnel)
            }
        } else {
            ContentUnavailableView(
                "Select a Tunnel",
                systemImage: "rectangle.connected.to.line.below",
                description: Text("Choose a tunnel from the list, or create a new one.")
            )
        }
    }

    @ViewBuilder
    private func tunnelHeader(_ tunnel: Tunnel) -> some View {
        let state = tunnelManager.state(for: tunnel.id)
        HStack(spacing: 12) {
            StatusDot(state: state)
                .scaleEffect(1.5)
            VStack(alignment: .leading) {
                Text(statusLabel(state))
                    .font(.headline)
                if case .failed(let msg) = state {
                    Text(msg)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            Spacer()
        }
        .padding()
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 10))
    }

    @ViewBuilder
    private func connectionDetails(_ tunnel: Tunnel) -> some View {
        DetailSection(title: "Connection") {
            DetailRow(label: "Host", value: "\(tunnel.host):\(tunnel.port)")
            if let user = tunnel.user { DetailRow(label: "User", value: user) }
            if let jump = tunnel.proxyJump { DetailRow(label: "ProxyJump", value: jump) }
        }
    }

    @ViewBuilder
    private func forwardingDetails(_ tunnel: Tunnel) -> some View {
        DetailSection(title: "Forwarding") {
            DetailRow(label: "Type", value: tunnel.type.rawValue.capitalized)
            switch tunnel.type {
            case .local:
                if let lp = tunnel.localPort { DetailRow(label: "Local Port", value: "\(lp)") }
                if let rh = tunnel.remoteHost { DetailRow(label: "Remote Host", value: rh) }
                if let rp = tunnel.remotePort { DetailRow(label: "Remote Port", value: "\(rp)") }
            case .remote:
                if let rp = tunnel.remotePort { DetailRow(label: "Remote Port", value: "\(rp)") }
                if let lp = tunnel.localPort { DetailRow(label: "Local Port", value: "\(lp)") }
            case .dynamic:
                if let lp = tunnel.localPort { DetailRow(label: "SOCKS Port", value: "\(lp)") }
            }
        }
    }

    @ViewBuilder
    private func authDetails(_ tunnel: Tunnel) -> some View {
        DetailSection(title: "Authentication") {
            DetailRow(label: "Method", value: tunnel.authMethod.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
            if let id = tunnel.identityFile { DetailRow(label: "Identity", value: id) }
            DetailRow(label: "Agent Forwarding", value: tunnel.agentForwarding ? "Yes" : "No")
        }
    }

    @ViewBuilder
    private func logSection(_ tunnel: Tunnel) -> some View {
        let events = (try? TunnelRepository().fetchRecentEvents(tunnelID: tunnel.id, limit: 20)) ?? []
        if !events.isEmpty {
            DetailSection(title: "Recent Events") {
                ForEach(events) { event in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: eventIcon(event.event))
                            .foregroundStyle(eventColor(event.event))
                            .frame(width: 14)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(event.event.rawValue.capitalized)
                                .font(.caption)
                                .fontWeight(.medium)
                            if let msg = event.message {
                                Text(msg)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        Text(event.timestamp, style: .relative)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }

    @ToolbarContentBuilder
    private func tunnelToolbar(_ tunnel: Tunnel) -> some ToolbarContent {
        let state = tunnelManager.state(for: tunnel.id)
        let isRunning: Bool = { switch state {
            case .stopped, .idle, .failed: return false; default: return true
        }}()

        ToolbarItem(placement: .primaryAction) {
            Button(action: { AppState.shared.toggleTunnel(tunnel) }) {
                Label(isRunning ? "Stop" : "Connect",
                      systemImage: isRunning ? "stop.fill" : "play.fill")
            }
        }
        ToolbarItem {
            Button(action: { TunnelManager.shared.restart(tunnelID: tunnel.id) }) {
                Label("Restart", systemImage: "arrow.clockwise")
            }
            .disabled(!isRunning)
        }
        ToolbarItem {
            Button(action: {
                AppState.shared.editingTunnel = tunnel
                AppState.shared.isEditorPresented = true
            }) {
                Label("Edit", systemImage: "pencil")
            }
        }
    }

    private func statusLabel(_ state: TunnelState) -> String {
        switch state {
        case .idle:                         return "Idle"
        case .connecting:                   return "Connecting…"
        case .connected:                    return "Connected"
        case .reconnecting(let n):          return "Reconnecting (attempt \(n))…"
        case .stopped:                      return "Stopped"
        case .failed:                       return "Failed"
        }
    }

    private func eventIcon(_ kind: ConnectionEventKind) -> String {
        switch kind {
        case .connected:    return "checkmark.circle.fill"
        case .disconnected: return "minus.circle.fill"
        case .error:        return "exclamationmark.triangle.fill"
        case .reconnecting: return "arrow.clockwise.circle.fill"
        }
    }

    private func eventColor(_ kind: ConnectionEventKind) -> Color {
        switch kind {
        case .connected:    return .green
        case .disconnected: return .secondary
        case .error:        return .red
        case .reconnecting: return .orange
        }
    }
}

// MARK: - Reusable detail sub-views

struct DetailSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 4) {
                content
            }
            .padding(12)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .foregroundStyle(.secondary)
                .frame(width: 110, alignment: .leading)
            Text(value)
                .textSelection(.enabled)
            Spacer()
        }
        .font(.callout)
    }
}
