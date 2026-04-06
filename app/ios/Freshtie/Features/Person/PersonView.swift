import SwiftUI

/// Core product screen — shows who you're talking to and what to say.
///
/// Two display states:
///   • Empty  — no notes; generic prompts only.
///   • Populated — context summary + contextual prompts.
///
/// Phase 4 will replace static `prompts` with PromptEngine output.
/// Phase 2 will wire context from NoteStore.
struct PersonView: View {
    let person: Person

    @State private var showCapture = false

    // TODO: Phase 4 — replace with PromptEngine.prompts(for: person)
    private let prompts: [Prompt]

    init(person: Person) {
        self.person = person
        self.prompts = person.lastContext != nil
            ? PreviewData.contextualPrompts
            : PreviewData.genericPrompts
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                personHeader
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.top, AppSpacing.md)

                if person.lastContext != nil {
                    contextSection
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.top, AppSpacing.lg)
                }

                promptsSection
                    .padding(.top, AppSpacing.xl)

                captureSection
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.top, AppSpacing.lg)
            }
            .padding(.bottom, AppSpacing.xxl)
        }
        .background(AppColors.background)
        .navigationTitle(person.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showCapture) {
            CaptureView(isSheet: true)
        }
    }

    // MARK: - Sections

    private var personHeader: some View {
        HStack(spacing: AppSpacing.md) {
            AvatarView(initials: person.initials, size: AppSize.avatarLG)

            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(person.displayName)
                    .font(AppTypography.title2)
                    .foregroundStyle(AppColors.label)

                if let label = person.lastInteractionLabel {
                    Text("Last spoke \(label)")
                        .font(AppTypography.subheadline)
                        .foregroundStyle(AppColors.secondaryLabel)
                }
            }

            Spacer()
        }
    }

    @ViewBuilder
    private var contextSection: some View {
        if let context = person.lastContext {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                SectionHeader("Last time")

                Text(context)
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.secondaryLabel)
                    .padding(AppSpacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppColors.secondaryBackground)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
            }
        }
    }

    private var promptsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            SectionHeader("Try asking")
                .padding(.horizontal, AppSpacing.md)

            VStack(spacing: AppSpacing.sm) {
                ForEach(prompts) { prompt in
                    PromptChip(text: prompt.text)
                }
            }
            .padding(.horizontal, AppSpacing.md)
        }
    }

    private var captureSection: some View {
        Button {
            showCapture = true
        } label: {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "plus.circle")
                    .font(.system(size: 17, weight: .medium))
                Text("Add something (optional)")
                    .font(AppTypography.callout)
            }
            .foregroundStyle(AppColors.secondaryLabel)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.md)
            .background(AppColors.secondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Previews

#Preview("With Context") {
    NavigationStack {
        PersonView(person: PreviewData.populatedPerson)
    }
}

#Preview("No Context") {
    NavigationStack {
        PersonView(person: PreviewData.emptyPerson)
    }
}
