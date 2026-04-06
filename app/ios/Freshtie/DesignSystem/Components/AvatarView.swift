import SwiftUI

/// Circular avatar that renders a person's initials.
/// Used in PersonRow (40 pt) and PersonView header (52 pt).
struct AvatarView: View {
    let initials: String
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(AppColors.avatarBackground)
                .frame(width: size, height: size)

            Text(initials)
                .font(.system(size: size * 0.36, weight: .semibold))
                .foregroundStyle(AppColors.avatarLabel)
        }
        .accessibilityHidden(true)   // parent view provides the accessible label
    }
}

// MARK: - Preview

#Preview {
    HStack(spacing: AppSpacing.lg) {
        AvatarView(initials: "SC", size: AppSize.avatarMD)
        AvatarView(initials: "MW", size: AppSize.avatarLG)
        AvatarView(initials: "J",  size: AppSize.avatarLG)
    }
    .padding()
}
