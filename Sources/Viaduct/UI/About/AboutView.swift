import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    private let version: String = {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "Version \(v) (\(b))"
    }()

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(DetailIconButtonStyle())
                .padding(14)
            }
            .frame(height: 44)

            // Icon + name
            VStack(spacing: 14) {
                if let appIcon = NSImage(named: "AppIcon") {
                    Image(nsImage: appIcon)
                        .resizable()
                        .frame(width: 72, height: 72)
                }
                VStack(spacing: 4) {
                    Text("Viaduct")
                        .font(.system(size: 22, weight: .bold))
                    Text(version)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
                Text("SSH tunnel manager for macOS")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 4)
            .padding(.bottom, 28)

            Divider()

            VStack(spacing: 0) {
                AboutLinkRow(icon: "globe", label: "Website", url: "https://octostudio.github.io/viaduct")
                Divider().padding(.leading, 42)
                AboutLinkRow(icon: "chevron.left.forwardslash.chevron.right", label: "GitHub", url: "https://github.com/OctoStudio/viaduct", last: true)
            }
            .background(ViaductStyle.cardBackground, in: RoundedRectangle(cornerRadius: ViaductStyle.cardCorner))
            .overlay {
                RoundedRectangle(cornerRadius: ViaductStyle.cardCorner)
                    .strokeBorder(ViaductStyle.hairline, lineWidth: 0.5)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)

            Text("© 2026 OctoStudio")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
                .padding(.bottom, 28)
        }
        .frame(width: 320)
    }
}

private struct AboutLinkRow: View {
    let icon: String
    let label: String
    let url: String
    var last = false

    var body: some View {
        Button {
            if let u = URL(string: url) { NSWorkspace.shared.open(u) }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .frame(width: 18)
                Text(label)
                    .font(.system(size: 14))
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 14)
            .frame(height: 46)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview("About") {
    AboutView()
        .background(ViaductStyle.detailBackground)
}
