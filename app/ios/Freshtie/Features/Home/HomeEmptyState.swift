import SwiftUI

/// Shown on the Home screen when there are no saved people yet.
///
/// Intentionally compact — an entry prompt, not an onboarding wall.
/// One message, one action, no illustration weight.
struct HomeEmptyState: View {
    let onAdd: () -> Void

    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            Image(systemName: "person.2")
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(AppColors.tertiaryLabel)

            Text("Pick someone you're about to talk to")
                .font(AppTypography.subheadline)
                .foregroundStyle(AppColors.secondaryLabel)
                .multilineTextAlignment(.center)

            Button(action: onAdd) {
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Add someone")
                        .font(AppTypography.callout)
                }
                .foregroundStyle(AppColors.accent)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, AppSpacing.xl)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

#Preview {
    HomeEmptyState(onAdd: {})
        .padding(.top, AppSpacing.xxl)
        .background(AppColors.background)
}
