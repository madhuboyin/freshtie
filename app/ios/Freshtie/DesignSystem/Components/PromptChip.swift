import SwiftUI

/// Full-width tappable chip that surfaces a single conversation prompt.
/// The core visual unit of the Person screen — should feel delightful and inviting.
struct PromptChip: View {
    let text: String
    var onTap: (() -> Void)? = nil

    var body: some View {
        Button {
            onTap?()
        } label: {
            Text(text)
                .font(AppTypography.body)
                .foregroundStyle(AppColors.chipLabel)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.sm + AppSpacing.xs)
                .background(AppColors.chipBackground)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                .overlay {
                    RoundedRectangle(cornerRadius: AppRadius.md)
                        .strokeBorder(AppColors.chipBorder, lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: AppSpacing.sm) {
        PromptChip(text: "How are things preparing for the new role at Google?")
        PromptChip(text: "How have you been lately?")
        PromptChip(text: "What's been keeping you busy?")
    }
    .padding()
}
