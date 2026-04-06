import SwiftUI

/// Lightweight context cue from the most recent note.
/// Intentionally minimal — this is a memory jog, not a history viewer.
/// Hidden by the caller when the person has no notes.
struct LastContextBlock: View {
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            SectionHeader("Last time")

            Text(text)
                .font(AppTypography.subheadline)
                .foregroundStyle(AppColors.secondaryLabel)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(AppSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
    }
}

// MARK: - Preview

#Preview {
    LastContextBlock(text: "Starting new job at Google next Monday — nervous but excited")
        .padding()
}
