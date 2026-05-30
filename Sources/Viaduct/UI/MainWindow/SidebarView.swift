import SwiftUI

struct SidebarView: View {
    @State private var appState = AppState.shared

    var body: some View {
        ZStack {
            ViaductStyle.sidebarBackground

            VStack(spacing: 0) {
                ViaductStyle.sidebarBackground
                    .frame(height: ViaductStyle.titlebarHeight)

                ScrollView {
                    VStack(alignment: .leading, spacing: 2) {
                        SidebarHeader("Smart Groups")
                        SidebarButton(
                            item: .allTunnels,
                            title: "All Tunnels",
                            count: appState.tunnels.count,
                            systemImage: "line.3.horizontal",
                            tint: ViaductStyle.accent
                        )
                        SidebarButton(
                            item: .connected,
                            title: "Connected",
                            count: connectedCount,
                            status: .connected
                        )
                        SidebarButton(
                            item: .errors,
                            title: "Errors",
                            count: errorCount,
                            status: .failed("")
                        )
                        SidebarButton(
                            item: .autoConnect,
                            title: "Auto-Connect",
                            systemImage: "bolt.fill",
                            tint: ViaductStyle.warning
                        )

                        if !appState.tags.isEmpty {
                            SidebarHeader("Tags")
                            ForEach(appState.tags) { tag in
                                SidebarButton(
                                    item: .tag(tag),
                                    title: tag.name,
                                    count: tagCount(tag),
                                    tagColor: Color(hex: tag.color)
                                )
                            }
                        }
                    }
                    .padding(.bottom, 8)
                }

                sidebarFooter
            }
        }
        .overlay(alignment: .trailing) { Rectangle().fill(ViaductStyle.hairline).frame(width: 0.5) }
        .frame(width: ViaductStyle.sidebarWidth)
    }

    private var connectedCount: Int {
        appState.tunnels.filter {
            if case .connected = TunnelManager.shared.state(for: $0.id) { return true }
            return false
        }.count
    }

    private var errorCount: Int {
        appState.tunnels.filter {
            if case .failed = TunnelManager.shared.state(for: $0.id) { return true }
            return false
        }.count
    }

    private var sidebarFooter: some View {
        HStack(spacing: 8) {
            Image(systemName: "network")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: 24, height: 22)
                .background(ViaductStyle.surface, in: RoundedRectangle(cornerRadius: 5))

            Text("\(connectedCount) of \(appState.tunnels.count) active")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
                .monospacedDigit()

            Spacer()

            Button {
                appState.selectedSidebarItem = .settings
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(appState.selectedSidebarItem == .settings ? .white : .secondary)
                    .frame(width: 24, height: 22)
                    .background(
                        appState.selectedSidebarItem == .settings ? ViaductStyle.accent : ViaductStyle.surface,
                        in: RoundedRectangle(cornerRadius: 5)
                    )
            }
            .buttonStyle(.plain)
            .help("Settings")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .overlay(alignment: .top) { Rectangle().fill(ViaductStyle.hairline).frame(height: 0.5) }
    }

    private func tagCount(_ tag: Tag) -> Int {
        appState.tunnelTags.values.reduce(0) { count, tags in
            count + (tags.contains(where: { $0.id == tag.id }) ? 1 : 0)
        }
    }

    private func openEditor() {
        appState.editingTunnel = nil
        appState.isEditorPresented = true
    }
}

private struct SidebarHeader: View {
    let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title.uppercased())
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(.tertiary)
            .padding(.horizontal, 18)
            .padding(.top, 14)
            .padding(.bottom, 4)
    }
}

private struct SidebarButton: View {
    @State private var appState = AppState.shared

    let item: SidebarItem
    let title: String
    var count: Int?
    var systemImage: String?
    var tint: Color = .secondary
    var status: TunnelState?
    var tagColor: Color?

    private var isSelected: Bool {
        appState.selectedSidebarItem == item
    }

    var body: some View {
        Button {
            appState.selectedSidebarItem = item
        } label: {
            HStack(spacing: 8) {
                icon
                    .frame(width: 16)
                Text(title)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if let count {
                    Text("\(count)")
                        .font(.system(size: 11, weight: .medium))
                        .monospacedDigit()
                        .foregroundStyle(isSelected ? .white.opacity(0.85) : Color(.tertiaryLabelColor))
                }
            }
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(isSelected ? .white : .primary)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(isSelected ? ViaductStyle.accent : Color.clear, in: RoundedRectangle(cornerRadius: 6))
            .contentShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 8)
    }

    @ViewBuilder
    private var icon: some View {
        if let status {
            StatusDot(state: status)
        } else if let tagColor {
            Circle().fill(tagColor).frame(width: 10, height: 10)
        } else if let systemImage {
            Image(systemName: systemImage)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(isSelected ? .white : tint)
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
