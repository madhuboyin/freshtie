import Foundation

// Lightweight mock data used exclusively by SwiftUI previews.
// Replace with real data sources in Phase 2 (local data layer).
enum PreviewData {

    static let recentPeople: [Person] = [
        Person(
            displayName: "Sarah Chen",
            lastContext: "Starting new job at Google next Monday",
            lastInteractionLabel: "2 weeks ago"
        ),
        Person(
            displayName: "Marcus Webb",
            lastContext: "Mentioned moving to Austin soon",
            lastInteractionLabel: "Last month"
        ),
        Person(
            displayName: "Jamie Torres",
            lastInteractionLabel: "3 months ago"
        ),
        Person(
            displayName: "Alex Kim",
            lastContext: "Studying for the bar exam",
            lastInteractionLabel: "Yesterday"
        ),
    ]

    static let populatedPerson = Person(
        displayName: "Sarah Chen",
        lastContext: "Starting new job at Google next Monday",
        lastInteractionLabel: "2 weeks ago"
    )

    static let emptyPerson = Person(
        displayName: "Riley Morgan"
    )

    /// Generic prompts shown when no notes exist for a person.
    static let genericPrompts: [Prompt] = [
        Prompt(text: "How have you been lately?"),
        Prompt(text: "What's been keeping you busy?"),
    ]

    /// Contextual prompts driven by a captured note (Phase 4 will generate these dynamically).
    static let contextualPrompts: [Prompt] = [
        Prompt(text: "How are things preparing for the new role at Google?"),
        Prompt(text: "How are you feeling going into it?"),
    ]
}
