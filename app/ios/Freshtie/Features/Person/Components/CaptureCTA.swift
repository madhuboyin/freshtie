import SwiftUI

/// Secondary CTA — visually quiet so it never competes with prompts.
/// Opens the quick capture sheet to add a note about this person.
struct CaptureCTA: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "plus.circle")
                    .font(.system(size: 16, weight: .regular))
                Text("Add something (optional)")
                    .font(AppTypography.callout)
            }
            .foregroundStyle(AppColors.secondaryLabel)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.md)
            .background(AppColors.secondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    CaptureCTA { }
        .padding()
}
