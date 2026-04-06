import SwiftUI
import SwiftData

/// Focused capture screen — always bound to a specific Person.
///
/// Presentation contexts:
///   Tab  (`isSheet = false`) — pushed by CapturePersonPickerView; back to exit.
///   Sheet (`isSheet = true`) — presented from PersonView; Cancel to dismiss.
///
/// State machine (driven by CaptureViewModel):
///   idle ──tap mic──▶ listening ──2.5 s silence──▶ auto-save ──▶ dismiss
///   idle ──type + send──▶ auto-save ──▶ dismiss
///   idle ──tap mic (denied)──▶ permissionDenied  (text input only)
struct CaptureView: View {
    let person: Person
    var isSheet: Bool = false

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel = CaptureViewModel()

    // MARK: - Body

    var body: some View {
        if isSheet {
            NavigationStack {
                mainContent
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button("Done") {
                                // Manual dismissal: save immediately and close
                                performSave(isManual: true)
                            }
                            .fontWeight(.semibold)
                            .foregroundStyle(AppColors.accent)
                        }
                    }
                    .navigationTitle(person.displayName)
                    .navigationBarTitleDisplayMode(.inline)
            }
            .onDisappear {
                // Background/Swipe dismissal: save if not already saved
                performSave(isManual: false)
            }
        } else {
            mainContent
                .navigationTitle(person.displayName)
                .navigationBarTitleDisplayMode(.inline)
                .onDisappear {
                    performSave(isManual: false)
                }
        }
    }

    // MARK: - Layout

    private var mainContent: some View {
        VStack(spacing: 0) {
            Spacer()

            centreContent
                .padding(.horizontal, AppSpacing.md)

            Spacer()
            Spacer()

            if viewModel.captureState != .saved {
                TextInputField(text: $viewModel.inputText, onSubmit: { performSave(isManual: true) })
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.bottom, AppSpacing.xl)
            }
        }
        .frame(maxWidth: .infinity)
        .background(AppColors.background)
        // Ensure speech is stopped when view goes away
        .onDisappear {
            viewModel.cancel()
        }
        // Silence timer or manual stop fires triggerSave — view handles the actual persist.
        .onChange(of: viewModel.triggerSave) { _, shouldSave in
            if shouldSave { performSave(isManual: false) }
        }
    }

    @ViewBuilder
    private var centreContent: some View {
        switch viewModel.captureState {
        case .idle:
            idleView
        case .permissionDenied:
            permissionDeniedView
        case .listening:
            listeningView
        case .saved:
            savedView
        }
    }

    // MARK: - State views

    private var idleView: some View {
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

            MicrophoneButton(isListening: false) {
                Task { await viewModel.tapMic() }
            }
        }
    }

    /// Shown when microphone or speech recognition permission has been denied.
    ///
    /// Voice is clearly unavailable — mic button is hidden, text input is primary.
    /// "Turn on in Settings" gives a direct recovery path without re-prompting.
    private var permissionDeniedView: some View {
        VStack(spacing: AppSpacing.lg) {
            Image(systemName: "mic.slash")
                .font(.system(size: 44))
                .foregroundStyle(AppColors.tertiaryLabel)

            VStack(spacing: AppSpacing.xs) {
                Text("Voice capture unavailable")
                    .font(AppTypography.title3)
                    .foregroundStyle(AppColors.label)
                Text("Type something below instead.")
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.secondaryLabel)
            }
            .multilineTextAlignment(.center)

            Button("Turn on in Settings") {
                OpenSettingsButton.open()
            }
            .font(AppTypography.callout)
            .foregroundStyle(AppColors.accent)
        }
    }

    private var listeningView: some View {
        VStack(spacing: AppSpacing.xl) {
            Group {
                if viewModel.liveTranscript.isEmpty {
                    Text("Listening…")
                        .foregroundStyle(AppColors.label)
                } else {
                    Text(viewModel.liveTranscript)
                        .foregroundStyle(AppColors.label)
                        .lineLimit(3)
                }
            }
            .font(AppTypography.title2)
            .multilineTextAlignment(.center)
            .animation(.easeInOut(duration: 0.18), value: viewModel.liveTranscript.isEmpty)

            ListeningIndicator()
                .frame(height: 52)

            MicrophoneButton(isListening: true) {
                Task { await viewModel.tapMic() }
            }
        }
    }

    private var savedView: some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(AppColors.accent)

            Text("Saved")
                .font(AppTypography.title3)
                .foregroundStyle(AppColors.label)
        }
    }

    // MARK: - Save

    private func performSave(isManual: Bool = false) {
        guard viewModel.captureState != .saved else { return }

        let text = viewModel.effectiveText
        if !text.isEmpty {
            PersonRepository.addNote(
                rawText: text,
                sourceType: viewModel.captureSourceType,
                to: person,
                in: modelContext
            )
        }

        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            viewModel.markSaved()
        }

        if isSheet {
            if isManual || text.isEmpty {
                dismiss()
            } else {
                // Silence-trigger: show checkmark briefly before auto-dismiss
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                    dismiss()
                }
            }
        } else if !isManual {
            // Inline tab: reset state for next capture if they stay on this screen
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation { viewModel.reset() }
            }
        }
    }
}

// MARK: - Previews

#Preview("Sheet") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Person.self, Note.self, configurations: config)
    let person = Person(displayName: "Sarah Chen")
    container.mainContext.insert(person)

    return CaptureView(person: person, isSheet: true)
        .modelContainer(container)
}

#Preview("Inline (tab push)") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Person.self, Note.self, configurations: config)
    let person = Person(displayName: "Sarah Chen")
    container.mainContext.insert(person)

    return NavigationStack {
        CaptureView(person: person, isSheet: false)
    }
    .modelContainer(container)
}
