import SwiftUI

/// Tappable search/pick row on the Home screen.
/// Phase 3 will wire this to CNContactPickerViewController.
struct SearchSelectRow: View {
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AppColors.secondaryLabel)

                Text("Search or pick someone…")
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.tertiaryLabel)

                Spacer()
            }
            .padding(.horizontal, AppSpacing.md)
            .frame(height: AppSize.minTapTarget + AppSpacing.sm)
            .background(AppColors.secondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    SearchSelectRow(onTap: {})
        .padding()
}
