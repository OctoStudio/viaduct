import SwiftUI
import AppKit

enum ViaductStyle {
    static let sidebarWidth: CGFloat = 220
    static let listWidth: CGFloat = 340
    static let titlebarHeight: CGFloat = 50

    static let accent = Color(red: 0.04, green: 0.52, blue: 1.0)
    static let success = Color(red: 0.16, green: 0.71, blue: 0.26)
    static let warning = Color(red: 0.89, green: 0.54, blue: 0.0)
    static let danger = Color(red: 0.90, green: 0.25, blue: 0.23)
    static let muted = Color(.tertiaryLabelColor)

    static let hairline = Color(.separatorColor).opacity(0.55)
    static let surface = Color.primary.opacity(0.035)
    static let surfaceHover = Color.primary.opacity(0.055)
    static let surfaceActive = Color.primary.opacity(0.085)
    static let chip = Color.primary.opacity(0.055)
    static let input = Color.primary.opacity(0.045)

    static let sidebarBackground = adaptiveColor(dark: 0x1d1d1f, light: 0xf3f6fa)
    static let listBackground = adaptiveColor(dark: 0x1b1b1d, light: 0xf8f8fa)
    static let detailBackground = adaptiveColor(dark: 0x202022, light: 0xffffff)
    static let titlebarBackground = adaptiveColor(dark: 0x242427, light: 0xfbfbfc)
    static let cardBackground = adaptiveColor(dark: 0x2a2a2d, light: 0xfbfbfc)

    private static func adaptiveColor(dark: Int, light: Int) -> Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            let value = isDark ? dark : light
            return NSColor(
                red: CGFloat((value >> 16) & 0xff) / 255,
                green: CGFloat((value >> 8) & 0xff) / 255,
                blue: CGFloat(value & 0xff) / 255,
                alpha: 1
            )
        })
    }
}

struct TrafficLights: View {
    var body: some View {
        HStack(spacing: 8) {
            light(Color(red: 1.0, green: 0.37, blue: 0.34))
            light(Color(red: 1.0, green: 0.74, blue: 0.18))
            light(Color(red: 0.16, green: 0.78, blue: 0.25))
        }
    }

    private func light(_ color: Color) -> some View {
        Circle()
            .fill(color)
            .frame(width: 12, height: 12)
            .overlay {
                Circle().strokeBorder(Color.black.opacity(0.18), lineWidth: 0.5)
            }
    }
}

struct StatusDot: View {
    let state: TunnelState
    var size: CGFloat = 8
    @State private var pulse = false

    var body: some View {
        ZStack {
            if isPulsing {
                Circle()
                    .strokeBorder(dotColor.opacity(0.7), lineWidth: 1.5)
                    .scaleEffect(pulse ? 1.8 : 0.5)
                    .opacity(pulse ? 0 : 0.8)
                    .animation(
                        .easeOut(duration: 1.4).repeatForever(autoreverses: false),
                        value: pulse
                    )
            }
            Circle()
                .fill(dotColor)
                .shadow(color: dotColor.opacity(isConnected ? 0.28 : 0), radius: 2)
        }
        .frame(width: size, height: size)
        .onAppear { pulse = isPulsing }
        .onChange(of: isPulsing) { _, v in
            pulse = false
            if v {
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(50))
                    pulse = true
                }
            }
        }
    }

    var dotColor: Color {
        switch state {
        case .connected:              return ViaductStyle.success
        case .connecting:             return ViaductStyle.warning
        case .reconnecting:           return ViaductStyle.warning
        case .failed:                 return ViaductStyle.danger
        case .stopped, .idle:         return ViaductStyle.muted
        }
    }

    private var isConnected: Bool {
        if case .connected = state { return true }
        return false
    }

    private var isPulsing: Bool {
        switch state {
        case .connecting, .reconnecting: return true
        default: return false
        }
    }
}

#Preview {
    HStack(spacing: 16) {
        StatusDot(state: .idle)
        StatusDot(state: .connecting)
        StatusDot(state: .connected)
        StatusDot(state: .reconnecting(attempt: 1))
        StatusDot(state: .stopped)
        StatusDot(state: .failed("oops"))
    }
    .padding()
}
