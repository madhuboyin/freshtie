import SwiftUI
import UIKit

/// Full-width tappable chip that surfaces a single conversation prompt.
/// Tapping copies the text to the clipboard with brief visual feedback.
/// The core visual unit of the Person screen — should feel delightful and inviting.
struct PromptChip: View {
    let text: String
    var onTap: (() -> Void)? = nil

    @State private var didCopy = false

    var body: some View {
        Button {
            UIPasteboard.general.string = text
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                didCopy = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeOut(duration: 0.25)) {
                    didCopy = false
                }
            }
            onTap?()
        } label: {
            HStack {
                Text(text)
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.chipLabel)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if didCopy {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppColors.accent)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm + AppSpacing.xs)
            .background(didCopy ? AppColors.accent.opacity(0.11) : AppColors.chipBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
            .overlay {
                RoundedRectangle(cornerRadius: AppRadius.md)
                    .strokeBorder(
                        didCopy ? AppColors.accent.opacity(0.28) : AppColors.chipBorder,
                        lineWidth: 1
                    )
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: didCopy)
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
