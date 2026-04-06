import SwiftUI

/// Animated bar waveform displayed while the app is actively listening.
/// Decorative animation only — a future phase can drive bar heights from
/// live AVAudio metering levels for a more reactive feel.
struct ListeningIndicator: View {
    @State private var isAnimating = false

    private static let barHeights: [CGFloat] = [
        14, 24, 36, 44, 38, 26, 42, 30, 46, 36,
        28, 40, 22, 34, 42, 28, 18, 32, 26, 14,
    ]

    var body: some View {
        HStack(alignment: .center, spacing: 4) {
            ForEach(0 ..< 20, id: \.self) { i in
                Capsule()
                    .fill(AppColors.accent)
                    .frame(width: 3.5)
                    .frame(height: isAnimating ? Self.barHeights[i] : 6)
                    .animation(
                        .easeInOut(duration: 0.45)
                            .repeatForever(autoreverses: true)
                            .delay(Double(i) * 0.04),
                        value: isAnimating
                    )
            }
        }
        .onAppear  { isAnimating = true  }
        .onDisappear { isAnimating = false }
    }
}

// MARK: - Preview

#Preview {
    ListeningIndicator()
        .frame(height: 52)
        .padding()
}
