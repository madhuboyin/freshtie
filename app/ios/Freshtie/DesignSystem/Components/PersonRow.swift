import SwiftUI

/// List row that represents a person — avatar, name, and context subtitle.
///
/// Subtitle priority:
///   1. Most recent note text (if any notes exist)
///   2. Relative "last spoke" label (if the person has been opened)
///   3. "No notes yet" — ensures the row always has a supporting line
struct PersonRow: View {
    let person: Person

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            AvatarView(initials: person.initials, size: AppSize.avatarMD)

            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(person.displayName)
                    .font(AppTypography.headline)
                    .foregroundStyle(AppColors.label)

                subtitleText
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

    @ViewBuilder
    private var subtitleText: some View {
        if let context = person.lastContext {
            Text(context)
                .font(AppTypography.subheadline)
                .foregroundStyle(AppColors.secondaryLabel)
                .lineLimit(1)
        } else if let label = person.lastInteractionLabel {
            Text(label)
                .font(AppTypography.subheadline)
                .foregroundStyle(AppColors.tertiaryLabel)
        } else {
            Text("No notes yet")
                .font(AppTypography.subheadline)
                .foregroundStyle(AppColors.tertiaryLabel)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 0) {
        PersonRow(person: Person(displayName: "Sarah Chen"))
        Divider()
            .padding(.leading, AppSpacing.md + AppSize.avatarMD + AppSpacing.md)
        PersonRow(person: PreviewData.emptyPerson)
        Divider()
            .padding(.leading, AppSpacing.md + AppSize.avatarMD + AppSpacing.md)
        PersonRow(person: Person(displayName: "Jamie Torres"))
    }
    .background(AppColors.secondaryBackground)
    .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
    .padding()
    .background(AppColors.background)
}
