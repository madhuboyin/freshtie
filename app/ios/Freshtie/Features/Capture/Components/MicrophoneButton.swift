import SwiftUI

/// Pulsing microphone button — primary entry point for voice capture.
/// Switches to a stop icon while actively listening.
struct MicrophoneButton: View {
    var isListening: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                // Outer pulse ring — visible only while listening
                Circle()
                    .fill(AppColors.accent.opacity(isListening ? 0.12 : 0))
                    .frame(width: 88, height: 88)

                Circle()
                    .fill(AppColors.accent.opacity(0.10))
                    .frame(width: 80, height: 80)

                Circle()
                    .fill(AppColors.accent)
                    .frame(width: 64, height: 64)

                Image(systemName: isListening ? "stop.fill" : "mic.fill")
                    .font(.system(size: isListening ? 20 : 26, weight: .semibold))
                    .foregroundStyle(.white)
            }
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isListening)
    }
}

// MARK: - Preview

#Preview {
    HStack(spacing: AppSpacing.xl) {
        MicrophoneButton(isListening: false) { }
        MicrophoneButton(isListening: true) { }
    }
    .padding()
}
