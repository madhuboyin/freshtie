import Foundation

/// The semantic kind of a note — drives which prompt pool is selected.
enum NoteKind {
    /// "degree class mate", "ex colleague" — catch-up framing.
    case relationshipContext
    /// "son of X", "he is from Dubai" — background facts, low promptability.
    case identityBackground
    /// Joined a company, moved city, had a baby, got married.
    case lifeEvent
    /// Planning a trip, recovering from surgery — in-progress situation.
    case ongoingTopic
    /// Everything else — delegate to the existing keyword pipeline.
    case weakSignal
}

enum RelationshipType {
    case oldClassmate      // "degree class mate", "ex classmate"
    case currentClassmate  // "classmate" (still studying together)
    case oldColleague      // "ex colleague", "former colleague"
    case currentColleague  // "colleague", "coworker"
    case familyRelation    // "cousin", "uncle", etc.
    case acquaintance      // "friend of a friend", "mutual friend"
    case unknown
}

enum TopicType {
    case companyOrJob
    case relocation
    case travel
    case educationCurrent
    case familyEvent
    case health
    case lifeUpdate
    /// Work effort / busyness — NOT a job change or new role.
    case workActivity
    case locationBackground
    case unknown
}

/// Controls which prompt pool tier is used.
enum Promptability {
    case high    // Enough context for specific intent prompts.
    case medium  // Partial context — use safe catch-up or soft prompts.
    case low     // Background/identity only — generic pool only.
}

struct NoteInterpretationResult {
    let kind: NoteKind
    let relationship: RelationshipType
    let topic: TopicType
    let promptability: Promptability
    let topEntity: String?
    let temporalState: TemporalState
}
