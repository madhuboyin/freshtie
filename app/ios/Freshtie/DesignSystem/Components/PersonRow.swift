import SwiftUI

/// List row that represents a person — avatar, name, optional context snippet.
/// Used in HomeView's recent-people list.
struct PersonRow: View {
    let person: Person

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            AvatarView(initials: person.initials, size: AppSize.avatarMD)

            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(person.displayName)
                    .font(AppTypography.headline)
                    .foregroundStyle(AppColors.label)

                if let context = person.lastContext {
                    Text(context)
                        .font(AppTypography.subheadline)
                        .foregroundStyle(AppColors.secondaryLabel)
                        .lineLimit(1)
                } else if let label = person.lastInteractionLabel {
                    Text(label)
                        .font(AppTypography.subheadline)
                        .foregroundStyle(AppColors.tertiaryLabel)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppColors.tertiaryLabel)
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm + AppSpacing.xs)
        .contentShape(Rectangle())
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 0) {
        PersonRow(person: PreviewData.populatedPerson)
        Divider()
            .padding(.leading, AppSpacing.md + AppSize.avatarMD + AppSpacing.md)
        PersonRow(person: PreviewData.emptyPerson)
        Divider()
            .padding(.leading, AppSpacing.md + AppSize.avatarMD + AppSpacing.md)
        PersonRow(person: PreviewData.recentPeople[2])
    }
}
