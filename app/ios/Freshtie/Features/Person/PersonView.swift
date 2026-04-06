import SwiftUI
import SwiftData

/// Core product screen — shows who you're talking to and what to say.
///
/// Layout (top → bottom):
///   PersonHeader  — small avatar + last-spoke time
///   LastContextBlock — most recent note, 2 lines max (hidden if no notes)
///   PromptSection — "Try asking" + 2 prompt chips + refresh
///   CaptureCTA    — "Add something (optional)"
///
/// Prompts load synchronously on appear (<1 ms) from the local
/// PromptEngine and refresh without network or loading states.
struct PersonView: View {
    let person: Person

    @Environment(\.modelContext) private var modelContext
    @State private var showCapture = false
    @State private var currentPrompts: [Prompt] = []

    private var sortedNotes: [Note] {
        person.notes.sorted { $0.createdAt > $1.createdAt }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                PersonHeader(person: person)

                if let contextText = person.lastContext {
                    LastContextBlock(text: contextText)
                }

                PromptSection(prompts: currentPrompts, onRefresh: rotatePrompts)

                CaptureCTA { showCapture = true }
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.top, AppSpacing.md)
            .padding(.bottom, AppSpacing.xxl)
        }
        .background(AppColors.background)
        .navigationTitle(person.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            PersonRepository.markOpened(person, in: modelContext)
            generatePrompts()
            AnalyticsService.shared.track(.prompt_viewed, metadata: [
                AnalyticsMetadata.personID: person.id.uuidString,
                AnalyticsMetadata.promptCount: String(currentPrompts.count)
            ])
        }
        // Re-generate when a note is added via the capture sheet.
        .onChange(of: person.notes.count) { _, _ in
            generatePrompts()
            AnalyticsService.shared.track(.prompt_viewed, metadata: [
                AnalyticsMetadata.personID: person.id.uuidString,
                AnalyticsMetadata.promptCount: String(currentPrompts.count)
            ])
        }
        .sheet(isPresented: $showCapture) {
            CaptureView(person: person, isSheet: true)
        }
    }

    // MARK: - Prompt generation

    private func generatePrompts() {
        withAnimation(.easeIn(duration: 0.2)) {
            currentPrompts = PromptEngine.prompts(for: person, sortedNotes: sortedNotes)
        }
    }

    private func rotatePrompts() {
        withAnimation(.easeInOut(duration: 0.22)) {
            currentPrompts = PromptEngine.refreshedPrompts(
                for: person,
                sortedNotes: sortedNotes,
                excluding: currentPrompts
            )
            AnalyticsService.shared.track(.prompt_refreshed, metadata: [
                AnalyticsMetadata.personID: person.id.uuidString,
                AnalyticsMetadata.promptCount: String(currentPrompts.count)
            ])
        }
    }
}

// MARK: - Previews

#Preview("With Notes") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Person.self, Note.self, configurations: config)
    let ctx = container.mainContext

    let sarah = Person(displayName: "Sarah Chen")
    sarah.lastOpenedAt = Calendar.current.date(byAdding: .day, value: -14, to: Date())
    ctx.insert(sarah)

    let n1 = Note(rawText: "Starting new job at Google next Monday")
    n1.person = sarah
    ctx.insert(n1)

    let n2 = Note(rawText: "Excited but nervous about the team")
    n2.person = sarah
    ctx.insert(n2)

    try! ctx.save()

    return NavigationStack { PersonView(person: sarah) }
        .modelContainer(container)
}

#Preview("No Notes") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Person.self, Note.self, configurations: config)
    let person = Person(displayName: "Riley Morgan")
    container.mainContext.insert(person)

    return NavigationStack { PersonView(person: person) }
        .modelContainer(container)
}

#Preview("Temporal — Future") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Person.self, Note.self, configurations: config)
    let ctx = container.mainContext

    let alex = Person(displayName: "Alex Rivera")
    ctx.insert(alex)

    let n = Note(rawText: "Moving to NYC next Friday")
    n.person = alex
    ctx.insert(n)

    try! ctx.save()

    return NavigationStack { PersonView(person: alex) }
        .modelContainer(container)
}
