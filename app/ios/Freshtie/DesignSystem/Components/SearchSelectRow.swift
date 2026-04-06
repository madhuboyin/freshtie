import SwiftUI

/// Primary entry control on the Home screen.
///
/// Deliberately larger than a standard row (60 pt) to feel like an
/// important action — not a search field, but a person-selection launcher.
/// The subtle border adds definition against any background.
struct SearchSelectRow: View {
    let onTap: () -> Void
    var placeholder: String = "Search or pick someone…"

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AppColors.secondaryLabel)

                Text(placeholder)
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.tertiaryLabel)

                Spacer()
            }
            .padding(.horizontal, AppSpacing.md)
            .frame(height: AppSize.minTapTarget + AppSpacing.md) // 60 pt
            .background(AppColors.secondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
            .overlay {
                RoundedRectangle(cornerRadius: AppRadius.md)
                    .strokeBorder(AppColors.separator.opacity(0.5), lineWidth: 0.5)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: AppSpacing.md) {
        SearchSelectRow(onTap: {})
        SearchSelectRow(onTap: {}, placeholder: "Who are you about to talk to?")
    }
    .padding()
    .background(AppColors.background)
}
