import SwiftUI

/// Root UI for the FreshtieShare extension.
///
/// Simplified text-only capture flow for Phase 8 original state.
struct ShareExtensionRootView: View {
    let displayName: String
    let onSave: (String) -> Void
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
                    onSave(noteText)
                }
                .fontWeight(.bold)
                .foregroundStyle(AppColors.accent)
            }
            .padding(.bottom, AppSpacing.sm)

            // Content
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("Say one thing")
                    .font(AppTypography.title2)
                    .foregroundStyle(AppColors.label)
                Text("before you forget about \(displayName).")
                    .font(AppTypography.title2)
                    .foregroundStyle(AppColors.secondaryLabel)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Note input
            TextField("Optional note...", text: $noteText, axis: .vertical)
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
        onSave: { _ in },
        onCancel: { }
    )
}
