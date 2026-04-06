import SwiftUI

/// Subtle refresh control below the prompt chips.
/// Tapping rotates through the engine's full template pool.
/// Visually quiet so it never competes with the prompts themselves.
struct PromptRefreshButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 12, weight: .medium))
                Text("New ideas")
                    .font(AppTypography.footnote)
            }
            .foregroundStyle(AppColors.tertiaryLabel)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    PromptRefreshButton { }
        .padding()
}
