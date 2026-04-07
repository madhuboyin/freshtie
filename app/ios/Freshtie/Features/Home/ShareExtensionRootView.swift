import SwiftUI

/// Root UI for the FreshtieShare extension.
///
/// Intentionally text-only — AVAudioEngine with hardware input/output nodes is
/// not available inside a Share Extension sandbox, so voice capture is left to
/// the main app.  Users type an optional note here; the main app handles voice.
struct ShareExtensionRootView: View {
    let displayName: String
    let onSave: (String, String?) -> Void  // (noteText, audioFileName)
    let onCancel: () -> Void

    @State private var noteText: String = ""

    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            // Header
            HStack {
                Button("Cancel", action: onCancel)
                    .foregroundStyle(AppColors.secondaryLabel)

                Spacer()

                Text("Freshtie")
                    .font(AppTypography.headline)

                Spacer()

                Button("Add") {
                    onSave(noteText, nil)
                }
                .fontWeight(.bold)
                .foregroundStyle(AppColors.accent)
            }
            .padding(.bottom, AppSpacing.sm)

            // Prompt copy
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("One thing to remember")
                    .font(AppTypography.title2)
                    .foregroundStyle(AppColors.label)
                Text("about \(displayName).")
                    .font(AppTypography.title2)
                    .foregroundStyle(AppColors.secondaryLabel)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Text input
            TextField("Optional note…", text: $noteText, axis: .vertical)
                .font(AppTypography.body)
                .padding(AppSpacing.md)
                .background(AppColors.secondaryBackground)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                .lineLimit(3...6)

            Spacer()
        }
        .padding(AppSpacing.md)
        .background(AppColors.background)
    }
}

#Preview {
    ShareExtensionRootView(
        displayName: "John Doe",
        onSave: { _, _ in },
        onCancel: { }
    )
}
