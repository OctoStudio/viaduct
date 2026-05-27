import SwiftUI

struct StatusDot: View {
    let state: TunnelState
    @State private var pulsing = false

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 8, height: 8)
            .opacity(pulsing ? 0.4 : 1.0)
            .animation(
                isAnimating
                    ? .easeInOut(duration: 0.8).repeatForever(autoreverses: true)
                    : .default,
                value: pulsing
            )
            .onAppear { pulsing = isAnimating }
            .onChange(of: isAnimating) { _, animating in
                pulsing = animating
            }
    }

    private var color: Color {
        switch state {
        case .connected:         return .green
        case .connecting:        return .yellow
        case .reconnecting:      return .orange
        case .failed:            return .red
        case .stopped, .idle:    return Color(.tertiaryLabelColor)
        }
    }

    private var isAnimating: Bool {
        switch state {
        case .connecting, .reconnecting: return true
        default: return false
        }
    }
}

#Preview {
    HStack(spacing: 12) {
        StatusDot(state: .idle)
        StatusDot(state: .connecting)
        StatusDot(state: .connected)
        StatusDot(state: .reconnecting(attempt: 1))
        StatusDot(state: .stopped)
        StatusDot(state: .failed("oops"))
    }
    .padding()
}
