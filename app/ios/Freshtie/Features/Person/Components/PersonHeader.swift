import SwiftUI

/// Minimal person header — small avatar + "last spoke" time.
/// The navigation title carries the name; this adds just enough
/// visual identity and temporal context without dominating.
struct PersonHeader: View {
    let person: Person

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            AvatarView(initials: person.initials, size: AppSize.avatarMD)

            if let label = person.lastInteractionLabel {
                Text("Last spoke \(label)")
                    .font(AppTypography.footnote)
                    .foregroundStyle(AppColors.tertiaryLabel)
            }

            Spacer()
        }
    }
}

// MARK: - Preview

#Preview {
    let person = Person(displayName: "Sarah Chen")
    return PersonHeader(person: person)
        .padding()
}
