import Foundation
import SwiftData

/// Lightweight helpers for SwiftUI previews.
///
/// For component-level previews (PersonRow, PromptChip, etc.) create bare
/// Person instances — relationships return empty defaults without a context,
/// which is acceptable.
///
/// For screen-level previews (HomeView, PersonView) attach the shared preview
/// container:
///
///     .modelContainer(.preview)
///
enum PreviewData {

    /// A bare Person with no notes — suitable for component previews.
    static var emptyPerson: Person { Person(displayName: "Riley Morgan") }

    /// A bare Person — use `.modelContainer(.preview)` to get one with real notes.
    static var samplePerson: Person { Person(displayName: "Sarah Chen") }

    // MARK: Prompts (used until Phase 4 ships the real prompt engine)

    /// Generic prompts shown when a person has no notes.
    static let genericPrompts: [Prompt] = [
        Prompt(text: "How have you been lately?"),
        Prompt(text: "What's been keeping you busy?"),
    ]

    /// Contextual prompts for the populated preview state.
    static let contextualPrompts: [Prompt] = [
        Prompt(text: "How are things preparing for the new role at Google?"),
        Prompt(text: "How are you feeling going into it?"),
    ]
}
