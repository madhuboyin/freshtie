import SwiftUI

/// The core product section — "Try asking".
///
/// Prompt chips take visual priority. The section label and
/// refresh button are intentionally quiet so prompts dominate.
/// Chips animate subtly when the set changes (on load or refresh).
struct PromptSection: View {
    let prompts: [Prompt]
    let onRefresh: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            SectionHeader("Try asking")

            VStack(spacing: AppSpacing.sm) {
                ForEach(prompts) { prompt in
                    PromptChip(text: prompt.text)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .animation(.easeInOut(duration: 0.22), value: prompts.map(\.id))

            PromptRefreshButton(action: onRefresh)
                .padding(.top, AppSpacing.xs)
        }
    }
}

// MARK: - Preview

#Preview {
    let prompts = [
        Prompt(text: "How's the new job going?"),
        Prompt(text: "Did you end up taking that trip?"),
    ]
    return PromptSection(prompts: prompts, onRefresh: { })
        .padding()
}
