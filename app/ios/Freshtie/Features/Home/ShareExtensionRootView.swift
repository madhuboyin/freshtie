import SwiftUI

/// Root UI for the FreshtieShare extension.
///
/// Offers the same conceptual capture modes as the main app:
///   Record  — "Record in Freshtie": saves the contact and routes into the
///             main app's CaptureView. AVAudioEngine is not used inside the
///             extension sandbox; recording happens after the handoff.
///   Type    — inline text note, saved immediately within the extension.
///   Skip    — saves the contact with no note.
///
/// The two-state layout (picker → typing) keeps the initial screen calm
/// and avoids surfacing a keyboard before the user asks for it.
struct ShareExtensionRootView: View {
    let displayName: String
    /// (noteText, requiresCapture)
    let onSave: (String, Bool) -> Void
    let onCancel: () -> Void

    @State private var isTyping = false
    @State private var noteText = ""

    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            header
                .padding(.bottom, AppSpacing.sm)

            tagline
                .frame(maxWidth: .infinity, alignment: .leading)

            if isTyping {
                typingInput
            } else {
                pickerActions
            }

            Spacer()
        }
        .padding(AppSpacing.md)
        .background(AppColors.background)
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button(isTyping ? "Back" : "Cancel") {
                if isTyping {
                    isTyping = false
                    noteText = ""
                } else {
                    onCancel()
                }
            }
            .foregroundStyle(AppColors.secondaryLabel)

            Spacer()

            Text("Freshtie")
                .font(AppTypography.headline)

            Spacer()

            if isTyping {
                Button("Add") { onSave(noteText, false) }
                    .fontWeight(.bold)
                    .foregroundStyle(AppColors.accent)
            } else {
                // Balance the leading button width so the title stays centred.
                Text("Cancel")
                    .foregroundStyle(.clear)
                    .allowsHitTesting(false)
            }
        }
    }

    // MARK: - Tagline

    private var tagline: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("Say one thing")
                .font(AppTypography.title2)
                .foregroundStyle(AppColors.label)
            Text("before you forget about \(displayName).")
                .font(AppTypography.title2)
                .foregroundStyle(AppColors.secondaryLabel)
        }
    }

    // MARK: - Picker mode

    private var pickerActions: some View {
        VStack(spacing: AppSpacing.sm) {
            // Record in Freshtie — primary action
            captureActionRow(
                icon: "waveform",
                label: "Record in Freshtie",
                detail: Image(systemName: "arrow.up.right")
            ) {
                onSave("", true)
            }

            // Type a note — secondary action
            captureActionRow(
                icon: "square.and.pencil",
                label: "Type a note",
                detail: Image(systemName: "chevron.right")
            ) {
                isTyping = true
            }

            Button("Skip") { onSave("", false) }
                .font(AppTypography.callout)
                .foregroundStyle(AppColors.secondaryLabel)
                .padding(.top, AppSpacing.xs)
        }
    }

    private func captureActionRow(
        icon: String,
        label: String,
        detail: Image,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 17))
                    .foregroundStyle(AppColors.accent)
                    .frame(width: 28)

                Text(label)
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.label)

                Spacer()

                detail
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppColors.tertiaryLabel)
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm + AppSpacing.xs)
            .background(AppColors.secondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Typing mode

    private var typingInput: some View {
        TextField("Optional note…", text: $noteText, axis: .vertical)
            .font(AppTypography.body)
            .padding(AppSpacing.md)
            .background(AppColors.secondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
            .lineLimit(3...6)
    }
}

// MARK: - Preview

#Preview("Picker") {
    ShareExtensionRootView(
        displayName: "John Doe",
        onSave: { _, _ in },
        onCancel: { }
    )
}
