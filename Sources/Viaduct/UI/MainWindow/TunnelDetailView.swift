import AppKit
import SwiftUI

struct TunnelDetailView: View {
    @State private var appState = AppState.shared
    @State private var tunnelManager = TunnelManager.shared
    @State private var showCommand = false
    @State private var events: [ConnectionEvent] = []
    @State private var pendingDelete: Tunnel?

    private var tunnel: Tunnel? {
        guard let id = appState.selectedTunnelID else { return nil }
        return appState.tunnels.first(where: { $0.id == id })
    }

    var body: some View {
        VStack(spacing: 0) {
            if let tunnel {
                detailTitleBar(tunnel)

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        statusBanner(tunnel)
                        metricTiles(tunnel)
                            .padding(.top, 14)
                            .padding(.bottom, 18)
                        forwardingCard(tunnel)
                        connectionCard(tunnel)
                        authCard(tunnel)
                        if showCommand { commandCard(tunnel) }
                        activityCard()
                        tagsView(tunnel)
                    }
                    .padding(.horizontal, 28)
                    .padding(.top, 24)
                    .padding(.bottom, 34)
                }
            } else {
                emptyTitleBar
                ContentUnavailableView(
                    "Select a Tunnel",
                    systemImage: "rectangle.connected.to.line.below",
                    description: Text("Choose a tunnel from the list, or create a new one.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(ViaductStyle.detailBackground)
        .onAppear {
            if let tunnel { loadEvents(for: tunnel) }
        }
        .onChange(of: appState.selectedTunnelID) { _, _ in
            if let tunnel { loadEvents(for: tunnel) }
        }
        .confirmationDialog(
            "Delete Tunnel?",
            isPresented: Binding(get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } }),
            titleVisibility: .visible
        ) {
            if let pendingDelete {
                Button("Delete \(pendingDelete.name)", role: .destructive) {
                    appState.deleteTunnel(pendingDelete)
                    self.pendingDelete = nil
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            if let pendingDelete {
                Text("This removes the saved tunnel, its tags, and connection log for \(pendingDelete.name).")
            }
        }
    }

    private func loadEvents(for tunnel: Tunnel) {
        events = (try? TunnelRepository().fetchRecentEvents(tunnelID: tunnel.id, limit: 20)) ?? []
    }

    // MARK: - Title bar

    private func detailTitleBar(_ tunnel: Tunnel) -> some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                Text(tunnel.name)
                    .font(.system(size: 14, weight: .semibold))
                    .lineLimit(1)
                TypeChip(type: tunnel.type)
            }

            Spacer()

            Button {
                appState.editingTunnel = tunnel
                appState.isEditorPresented = true
            } label: {
                Image(systemName: "pencil")
                    .font(.system(size: 13, weight: .medium))
            }
            .buttonStyle(DetailIconButtonStyle())
            .help("Edit")

            Button { pendingDelete = tunnel } label: {
                Image(systemName: "trash")
                    .font(.system(size: 13, weight: .medium))
            }
            .buttonStyle(DetailIconButtonStyle())
            .help("Delete")

            Rectangle()
                .fill(ViaductStyle.hairline)
                .frame(width: 0.5, height: 14)
                .padding(.horizontal, 2)

            Button { showCommand.toggle() } label: {
                Image(systemName: showCommand ? "terminal.fill" : "terminal")
                    .font(.system(size: 13, weight: .medium))
            }
            .buttonStyle(DetailIconButtonStyle(isActive: showCommand))
            .help("Show Command")

            settingsButton
        }
        .padding(.horizontal, 18)
        .frame(height: ViaductStyle.titlebarHeight)
        .background(ViaductStyle.titlebarBackground)
        .overlay(alignment: .bottom) { Rectangle().fill(ViaductStyle.hairline).frame(height: 0.5) }
    }

    private var emptyTitleBar: some View {
        HStack {
            Spacer()
            settingsButton
        }
        .padding(.horizontal, 18)
        .frame(height: ViaductStyle.titlebarHeight)
        .background(ViaductStyle.titlebarBackground)
        .overlay(alignment: .bottom) { Rectangle().fill(ViaductStyle.hairline).frame(height: 0.5) }
    }

    private var settingsButton: some View {
        Button {
            appState.selectedSidebarItem = .settings
        } label: {
            Image(systemName: "gearshape")
                .font(.system(size: 13, weight: .medium))
        }
        .buttonStyle(DetailIconButtonStyle())
        .help("Settings")
    }

    // MARK: - Status banner

    @ViewBuilder
    private func statusBanner(_ tunnel: Tunnel) -> some View {
        let state = tunnelManager.state(for: tunnel.id)
        let running = isRunning(state)
        let accent = stateColor(state)

        HStack(spacing: 14) {
            Circle()
                .fill(accent.opacity(0.12))
                .frame(width: 36, height: 36)
                .overlay { StatusDot(state: state, size: 12) }

            VStack(alignment: .leading, spacing: 3) {
                Text(statusLabel(state))
                    .font(.system(size: 14, weight: .semibold))
                Text(statusSubtitle(tunnel, state: state))
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            HStack(spacing: 6) {
                Button { AppState.shared.toggleTunnel(tunnel) } label: {
                    HStack(spacing: 5) {
                        Image(systemName: running ? "stop.fill" : "play.fill")
                            .font(.system(size: 9, weight: .semibold))
                        Text(running ? "Stop" : "Connect")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .frame(height: 26)
                    .background(running ? ViaductStyle.danger : ViaductStyle.accent, in: RoundedRectangle(cornerRadius: 6))
                    .shadow(color: (running ? ViaductStyle.danger : ViaductStyle.accent).opacity(0.3), radius: 2, y: 1)
                }
                .buttonStyle(.plain)

                Button { TunnelManager.shared.restart(tunnelID: tunnel.id) } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 11))
                        .frame(width: 26, height: 26)
                        .background(ViaductStyle.cardBackground, in: RoundedRectangle(cornerRadius: 6))
                        .overlay {
                            RoundedRectangle(cornerRadius: 6)
                                .strokeBorder(Color(.separatorColor).opacity(0.6), lineWidth: 0.5)
                        }
                }
                .buttonStyle(.plain)
                .disabled(!running)
                .opacity(running ? 1 : 0.4)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .background(accent.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(accent.opacity(0.20), lineWidth: 0.5)
        }
    }

    // MARK: - Metric tiles

    @ViewBuilder
    private func metricTiles(_ tunnel: Tunnel) -> some View {
        let state = tunnelManager.state(for: tunnel.id)

        HStack(spacing: 8) {
            MetricTile(label: "Uptime") {
                if case .connected = state, let connectedAt = tunnelManager.connectedAt(for: tunnel.id) {
                    TimelineView(.periodic(from: connectedAt, by: 60)) { ctx in
                        Text(formatUptime(from: connectedAt, to: ctx.date))
                            .font(.system(size: 13, weight: .semibold).monospacedDigit())
                    }
                } else {
                    Text("—")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.tertiary)
                }
            }

            MetricTile(label: "Endpoint") {
                Text(tunnel.endpointDescription ?? "—")
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .foregroundStyle(tunnel.endpointDescription == nil ? .tertiary : .primary)
            }

            MetricTile(label: "Auth") {
                Text(authLabel(tunnel.authMethod))
                    .font(.system(size: 12, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }

            MetricTile(label: "Auto-Connect") {
                Text(tunnel.autoConnect ? "On" : "Off")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(tunnel.autoConnect ? ViaductStyle.accent : .secondary)
            }
        }
    }

    // MARK: - Section cards

    @ViewBuilder
    private func forwardingCard(_ tunnel: Tunnel) -> some View {
        let bind = tunnel.bindAddress.flatMap { $0.isEmpty ? nil : $0 } ?? "127.0.0.1"
        DetailCard(title: "Forwarding") {
            KVRow(label: "Type", value: tunnelTypeLabel(tunnel.type))
            KVRow(label: "Route", value: shortRoute(tunnel), mono: true)
            switch tunnel.type {
            case .local:
                if let lp = tunnel.localPort {
                    KVRow(label: "Local", value: "\(bind):\(lp)", mono: true)
                }
                if let rh = tunnel.remoteHost, let rp = tunnel.remotePort {
                    KVRow(label: "Remote Target", value: "\(rh):\(rp)", mono: true, last: true)
                }
            case .remote:
                if let rp = tunnel.remotePort {
                    KVRow(label: "Remote Listen", value: "\(tunnel.host):\(rp)", mono: true)
                }
                let target = tunnel.remoteHost.flatMap { $0.isEmpty ? nil : $0 } ?? "localhost"
                if let lp = tunnel.localPort {
                    KVRow(label: "Forwards To", value: "\(target):\(lp)", mono: true, last: true)
                }
            case .dynamic:
                if let lp = tunnel.localPort {
                    KVRow(label: "SOCKS Port", value: "\(bind):\(lp)", mono: true, last: true)
                }
            }
        }
    }

    @ViewBuilder
    private func connectionCard(_ tunnel: Tunnel) -> some View {
        DetailCard(title: "Connection") {
            KVRow(label: "Host", value: "\(tunnel.host):\(tunnel.port)", mono: true, copyable: true)
            if let user = tunnel.user, !user.isEmpty {
                KVRow(label: "User", value: user, mono: true)
            }
            if let jump = tunnel.proxyJump, !jump.isEmpty {
                KVRow(label: "ProxyJump", value: jump, mono: true)
            }
            KVRow(label: "Host Key Check", value: tunnel.strictHostChecking.rawValue, last: true)
        }
    }

    @ViewBuilder
    private func authCard(_ tunnel: Tunnel) -> some View {
        DetailCard(title: "Authentication") {
            KVRow(label: "Method", value: authLabel(tunnel.authMethod))
            if let id = tunnel.identityFile, !id.isEmpty {
                KVRow(label: "Identity File", value: id, mono: true)
            }
            KVRow(label: "Agent Forwarding", value: tunnel.agentForwarding ? "Enabled" : "Disabled", last: true)
        }
    }

    @ViewBuilder
    private func commandCard(_ tunnel: Tunnel) -> some View {
        let cmd = effectiveCommand(for: tunnel)
        DetailCard(title: "Effective Command", trailing: AnyView(CopyButton(value: cmd))) {
            Text(cmd)
                .font(.system(size: 11.5, design: .monospaced))
                .textSelection(.enabled)
                .lineSpacing(3)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
        }
    }

    @ViewBuilder
    private func activityCard() -> some View {
        DetailCard(title: "Recent Activity") {
            if events.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "clock")
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                    Text("No recent activity")
                        .font(.callout)
                        .foregroundStyle(.tertiary)
                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
            } else {
                ForEach(Array(events.enumerated()), id: \.1.id) { idx, event in
                    HStack(alignment: .top, spacing: 10) {
                        Circle()
                            .fill(eventColor(event.event).opacity(0.1))
                            .frame(width: 22, height: 22)
                            .overlay {
                                Image(systemName: eventIcon(event.event))
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundStyle(eventColor(event.event))
                            }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(eventLabel(event.event))
                                .font(.system(size: 12.5, weight: .medium))
                            if let msg = event.message {
                                Text(msg)
                                    .font(.system(size: 11))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        Text(event.timestamp, style: .relative)
                            .font(.system(size: 11))
                            .foregroundStyle(.tertiary)
                            .monospacedDigit()
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    if idx < events.count - 1 {
                        Divider().padding(.leading, 14)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func tagsView(_ tunnel: Tunnel) -> some View {
        let tags = appState.tunnelTags[tunnel.id] ?? []
        if !tags.isEmpty {
            HStack(spacing: 6) {
                ForEach(tags) { tag in
                    HStack(spacing: 5) {
                        Circle()
                            .fill(Color(hex: tag.color))
                            .frame(width: 6, height: 6)
                        Text(tag.name)
                            .font(.system(size: 11, weight: .medium))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color(hex: tag.color).opacity(0.10), in: Capsule())
                    .overlay {
                        Capsule()
                            .strokeBorder(Color(hex: tag.color).opacity(0.30), lineWidth: 0.5)
                    }
                }
                Spacer()
            }
            .padding(.top, 4)
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private func tunnelToolbar(_ tunnel: Tunnel) -> some ToolbarContent {
        let state = tunnelManager.state(for: tunnel.id)
        let running = isRunning(state)

        ToolbarItem(placement: .primaryAction) {
            Button(action: { AppState.shared.toggleTunnel(tunnel) }) {
                Label(running ? "Stop" : "Connect",
                      systemImage: running ? "stop.fill" : "play.fill")
            }
            .tint(running ? ViaductStyle.danger : ViaductStyle.accent)
        }
        ToolbarItem {
            Button(action: { TunnelManager.shared.restart(tunnelID: tunnel.id) }) {
                Label("Restart", systemImage: "arrow.clockwise")
            }
            .disabled(!running)
        }
        ToolbarItem {
            Button(action: {
                appState.editingTunnel = tunnel
                appState.isEditorPresented = true
            }) {
                Label("Edit", systemImage: "pencil")
            }
        }
        ToolbarItem {
            Button(action: { showCommand.toggle() }) {
                Label("Command", systemImage: showCommand ? "terminal.fill" : "terminal")
            }
        }
    }

    // MARK: - Helpers

    private func isRunning(_ state: TunnelState) -> Bool {
        switch state { case .stopped, .idle, .failed: false; default: true }
    }

    private func stateColor(_ state: TunnelState) -> Color {
        switch state {
        case .connected:                  return ViaductStyle.success
        case .connecting, .reconnecting:  return ViaductStyle.warning
        case .failed:                     return ViaductStyle.danger
        case .stopped, .idle:             return ViaductStyle.muted
        }
    }

    private func statusLabel(_ state: TunnelState) -> String {
        switch state {
        case .idle:               return "Idle"
        case .connecting:         return "Connecting…"
        case .connected:          return "Connected"
        case .reconnecting(let n): return "Reconnecting (attempt \(n))…"
        case .stopped:            return "Stopped"
        case .failed:             return "Connection Failed"
        }
    }

    private func statusSubtitle(_ tunnel: Tunnel, state: TunnelState) -> String {
        switch state {
        case .connected:
            let ep = tunnel.endpointDescription.map { "Listening on \($0)" } ?? "Tunnel is active"
            return ep
        case .connecting:
            return "Establishing channel to \(tunnel.host)…"
        case .reconnecting(let n):
            return "Retrying connection to \(tunnel.host) (attempt \(n))"
        case .failed(let msg):
            return msg
        case .idle, .stopped:
            return "Ready to connect to \(tunnel.host)"
        }
    }

    private func shortRoute(_ tunnel: Tunnel) -> String {
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

    private func tunnelTypeLabel(_ type: TunnelType) -> String {
        switch type {
        case .local:   return "Local Forward"
        case .remote:  return "Remote Forward"
        case .dynamic: return "Dynamic (SOCKS5)"
        }
    }

    private func authLabel(_ method: AuthMethod) -> String {
        switch method {
        case .systemAgent:        return "System SSH Agent"
        case .onePasswordAgent:   return "1Password Agent"
        case .keychainPassphrase: return "Keychain Passphrase"
        }
    }

    private func eventIcon(_ kind: ConnectionEventKind) -> String {
        switch kind {
        case .connected:    return "checkmark"
        case .disconnected: return "moon.fill"
        case .error:        return "exclamationmark.triangle"
        case .reconnecting: return "arrow.clockwise"
        }
    }

    private func eventColor(_ kind: ConnectionEventKind) -> Color {
        switch kind {
        case .connected:    return Color(red: 0.17, green: 0.82, blue: 0.35)
        case .disconnected: return .secondary
        case .error:        return .red
        case .reconnecting: return .orange
        }
    }

    private func eventLabel(_ kind: ConnectionEventKind) -> String {
        switch kind {
        case .connected:    return "Connected"
        case .disconnected: return "Disconnected"
        case .error:        return "Error"
        case .reconnecting: return "Reconnecting"
        }
    }

    private func effectiveCommand(for tunnel: Tunnel) -> String {
        (["ssh"] + SSHCommandBuilder.buildArguments(for: tunnel))
            .map(shellQuoted)
            .joined(separator: " ")
    }

    private func shellQuoted(_ value: String) -> String {
        guard !value.isEmpty else { return "''" }
        let safe = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_+-=.,/:@%")
        if value.unicodeScalars.allSatisfy({ safe.contains($0) }) { return value }
        return "'" + value.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }
}

// MARK: - Detail card

struct DetailCard<Content: View>: View {
    let title: String
    var trailing: AnyView? = nil
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .center) {
                Text(title.uppercased())
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.tertiary)
                    .tracking(0.3)
                Spacer()
                trailing
            }
            .padding(.horizontal, 2)

            VStack(spacing: 0) {
                content
            }
            .background(ViaductStyle.cardBackground, in: RoundedRectangle(cornerRadius: 10))
            .overlay {
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(Color(.separatorColor).opacity(0.5), lineWidth: 0.5)
            }
        }
        .padding(.bottom, 18)
    }
}

struct DetailIconButtonStyle: ButtonStyle {
    var isActive = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.primary)
            .frame(width: 24, height: 22)
            .background(
                (isActive || configuration.isPressed) ? ViaductStyle.surfaceActive : ViaductStyle.surface,
                in: RoundedRectangle(cornerRadius: 5)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 5)
                    .strokeBorder(ViaductStyle.hairline, lineWidth: 0.5)
            }
    }
}

// MARK: - KV row

struct KVRow: View {
    let label: String
    let value: String
    var mono: Bool = false
    var last: Bool = false
    var copyable: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 12) {
                Text(label)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .frame(width: 110, alignment: .leading)
                    .fixedSize()

                Text(value)
                    .font(mono ? .system(size: 12.5, design: .monospaced) : .system(size: 12.5))
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if copyable {
                    CopyButton(value: value)
                }
            }
            .padding(.horizontal, 14)
            .frame(minHeight: 32)

            if !last {
                Divider().padding(.leading, 14)
            }
        }
    }
}

// MARK: - Metric tile

struct MetricTile<Value: View>: View {
    let label: String
    @ViewBuilder let value: Value

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.tertiary)
                .tracking(0.3)
                .lineLimit(1)
            value
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ViaductStyle.cardBackground, in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Color(.separatorColor).opacity(0.4), lineWidth: 0.5)
        }
    }
}

// MARK: - Copy button

struct CopyButton: View {
    let value: String
    @State private var copied = false

    var body: some View {
        Button {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(value, forType: .string)
            copied = true
            Task {
                try? await Task.sleep(for: .milliseconds(1200))
                copied = false
            }
        } label: {
            Image(systemName: copied ? "checkmark" : "doc.on.doc")
                .font(.system(size: 11))
                .foregroundStyle(copied ? Color(red: 0.17, green: 0.82, blue: 0.35) : .secondary)
                .opacity(copied ? 1.0 : 0.55)
                .frame(width: 22, height: 22)
        }
        .buttonStyle(.plain)
        .help("Copy")
    }
}
