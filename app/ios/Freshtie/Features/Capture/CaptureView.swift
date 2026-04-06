import SwiftUI

/// Ultra-light capture screen. Phase 7 will integrate AVAudioSession + SFSpeechRecognizer.
///
/// Supports two presentation contexts:
///   • Tab  (`isSheet = false`) — no Cancel button; resets to idle after save.
///   • Sheet (`isSheet = true`) — Cancel button in nav bar; dismisses after save.
struct CaptureView: View {
    var isSheet: Bool = false

    @Environment(\.dismiss) private var dismiss
    @State private var state: CaptureState = .idle
    @State private var inputText = ""

    // MARK: - State machine

    enum CaptureState: Equatable { case idle, listening, saved }

    // MARK: - Body

    var body: some View {
        if isSheet {
            NavigationStack {
                mainContent
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button("Cancel") { dismiss() }
                                .foregroundStyle(AppColors.secondaryLabel)
                        }
                    }
            }
        } else {
            mainContent
        }
    }

    // MARK: - Layout

    private var mainContent: some View {
        VStack(spacing: 0) {
            Spacer()

            stateContent
                .padding(.horizontal, AppSpacing.md)

            Spacer()
            Spacer()

            if state != .saved {
                bottomBar
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.bottom, AppSpacing.xl)
            }
        }
        .frame(maxWidth: .infinity)
        .background(AppColors.background)
    }

    @ViewBuilder
    private var stateContent: some View {
        if state == .idle {
            idleState
        } else if state == .listening {
            listeningState
        } else {
            savedState
        }
    }

    // MARK: - State views

    private var idleState: some View {
        VStack(spacing: AppSpacing.xl) {
            VStack(spacing: AppSpacing.xs) {
                Text("Say one thing")
                    .font(AppTypography.title2)
                    .foregroundStyle(AppColors.label)
                Text("before you forget.")
                    .font(AppTypography.title2)
                    .foregroundStyle(AppColors.secondaryLabel)
            }
            .multilineTextAlignment(.center)

            micButton
        }
    }

    private var listeningState: some View {
        VStack(spacing: AppSpacing.xl) {
            Text("Listening…")
                .font(AppTypography.title2)
                .foregroundStyle(AppColors.label)

            WaveformView()
                .frame(height: 52)
        }
    }

    private var savedState: some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(AppColors.accent)

            Text("Saved")
                .font(AppTypography.title3)
                .foregroundStyle(AppColors.label)
        }
    }

    // MARK: - Controls

    private var micButton: some View {
        Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                state = .listening
            }
            // TODO: Phase 7 — start AVAudioSession + SFSpeechRecognizer here
        } label: {
            ZStack {
                Circle()
                    .fill(AppColors.accent.opacity(0.10))
                    .frame(width: 80, height: 80)

                Circle()
                    .fill(AppColors.accent)
                    .frame(width: 64, height: 64)

                Image(systemName: "mic.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(.white)
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var bottomBar: some View {
        if state == .idle {
            textEntryRow
        } else if state == .listening {
            saveButton
        }
    }

    private var textEntryRow: some View {
        HStack(spacing: AppSpacing.sm) {
            TextField("Or type something…", text: $inputText)
                .font(AppTypography.body)
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.sm + AppSpacing.xs)
                .background(AppColors.secondaryBackground)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                .submitLabel(.done)
                .onSubmit { if !inputText.isEmpty { handleSave() } }

            if !inputText.isEmpty {
                Button(action: handleSave) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(AppColors.accent)
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: inputText.isEmpty)
    }

    private var saveButton: some View {
        Button(action: handleSave) {
            Text("Save")
                .font(AppTypography.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.md)
                .background(AppColors.accent)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        }
    }

    // MARK: - Actions

    private func handleSave() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            state = .saved
        }
        if isSheet {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { dismiss() }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                withAnimation { state = .idle; inputText = "" }
            }
        }
    }
}

// MARK: - Waveform animation

/// Animated bar waveform that simulates active listening.
/// Phase 7 will drive bar heights from live audio levels.
private struct WaveformView: View {
    @State private var isAnimating = false

    private static let targetHeights: [CGFloat] = [
        14, 24, 36, 44, 38, 26, 42, 30, 46, 36,
        28, 40, 22, 34, 42, 28, 18, 32, 26, 14,
    ]

    var body: some View {
        HStack(alignment: .center, spacing: 4) {
            ForEach(0 ..< 20, id: \.self) { i in
                Capsule()
                    .fill(AppColors.accent)
                    .frame(width: 3.5)
                    .frame(height: isAnimating ? Self.targetHeights[i] : 6)
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

// MARK: - Previews

#Preview("Idle — Sheet") {
    CaptureView(isSheet: true)
}

#Preview("Idle — Tab") {
    CaptureView()
}
