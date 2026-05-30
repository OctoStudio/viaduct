import SwiftUI
import AppKit

enum ViaductStyle {
    static let sidebarWidth: CGFloat = 250
    static let listWidth: CGFloat = 390
    static let titlebarHeight: CGFloat = 64

    static let accent = adaptiveColor(dark: 0x5b8cff, light: 0x1f5fff)
    static let success = adaptiveColor(dark: 0x36c869, light: 0x1f9d4d)
    static let warning = adaptiveColor(dark: 0xf0a330, light: 0xe08a00)
    static let danger = adaptiveColor(dark: 0xff5b50, light: 0xd6342b)
    static let muted = Color(.tertiaryLabelColor)

    static let hairline = adaptiveColor(dark: 0x363a44, light: 0xdedacf)
    static let hairlineSoft = adaptiveColor(dark: 0x292d36, light: 0xebe7dc)
    static let surface = adaptiveColor(dark: 0x20242c, light: 0xf3f1ea)
    static let surfaceHover = adaptiveColor(dark: 0x292e38, light: 0xebeefa)
    static let surfaceActive = adaptiveColor(dark: 0x31394a, light: 0xe9eefc)
    static let chip = adaptiveColor(dark: 0x2a303b, light: 0xf3f1ea)
    static let input = adaptiveColor(dark: 0x171b22, light: 0xf7f5ee)

    static let windowBackground = adaptiveColor(dark: 0x0f1218, light: 0xeceadf)
    static let sidebarBackground = adaptiveColor(dark: 0x151922, light: 0xf3f1ea)
    static let listBackground = adaptiveColor(dark: 0x11151c, light: 0xfbfaf6)
    static let detailBackground = adaptiveColor(dark: 0x0f1218, light: 0xfffef9)
    static let titlebarBackground = adaptiveColor(dark: 0x121720, light: 0xf7f5ee)
    static let cardBackground = adaptiveColor(dark: 0x171b22, light: 0xfffef9)
    static let commandBackground = adaptiveColor(dark: 0x090c12, light: 0x15171c)
    static let selectedListBackground = adaptiveColor(dark: 0x1d2947, light: 0xe9eefc)
    static let selectedListBorder = adaptiveColor(dark: 0x36548c, light: 0xb8c9ff)
    static let tagGreenBackground = adaptiveColor(dark: 0x14251d, light: 0xedf7f0)
    static let tagAmberBackground = adaptiveColor(dark: 0x2a2112, light: 0xfff4dd)
    static let tagBlueBackground = adaptiveColor(dark: 0x172033, light: 0xeef3ff)

    static let fieldCorner: CGFloat = 9
    static let cardCorner: CGFloat = 10

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
