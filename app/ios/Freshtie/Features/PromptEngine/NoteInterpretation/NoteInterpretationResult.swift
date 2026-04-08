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
/// Kept for backward compatibility — prefer SpecificityLevel for new routing logic.
enum Promptability {
    case high    // Enough context for specific intent prompts.
    case medium  // Partial context — use safe catch-up or soft prompts.
    case low     // Background/identity only — generic pool only.
}

// MARK: - Prompt Angle

/// The safest and most relevant conversational direction encoded in a note.
///
/// This is the middle layer between note meaning and final prompt wording.
/// Drives which prompt family the Composer selects, independently of raw topic keywords.
enum PromptAngle {
    /// Old classmate, ex-colleague — reconnecting after time apart.
    case oldConnectionCatchUp
    /// Family or social connection (not an event) — gentle, identity-aware framing.
    case socialConnectionAnchor
    /// Work busyness / effort — NOT a job change or new role.
    case busyWorkCheckIn
    /// New role, new company, job transition — explicit career move.
    case careerUpdate
    /// Moving city or country — physical relocation.
    case relocationUpdate
    /// Upcoming or completed trip.
    case travelUpdate
    /// Wedding, baby, milestone — specific life event.
    case familyEventFollowUp
    /// Health, general life update — soft situation check-in.
    case lifeUpdateCheckIn
    /// Where-from, whose relative — background fact with minimal prompt hook.
    case backgroundSoftAnchor
    /// No meaningful direction — pure safe generic output.
    case genericCatchUp
}

// MARK: - Specificity Level

/// Controls how directly the Prompt Composer references note context.
///
/// Hierarchy: specific → contextual → neutral → generic
/// Wrong specificity is worse than generic — prefer downgrading over misfiring.
enum SpecificityLevel {
    /// High-confidence, event-rich note — prompt can reference the topic directly.
    case specific
    /// Note gives relational or activity context — prompt is note-aware but softer.
    case contextual
    /// Note suggests a possible direction but evidence is thin — lightly connected prompts.
    case neutral
    /// Almost no safe direction available — pure generic fallback.
    case generic
}

// MARK: - Result

struct NoteInterpretationResult {
    let kind: NoteKind
    let relationship: RelationshipType
    let topic: TopicType
    let promptability: Promptability    // backward-compat; prefer specificityLevel for routing
    let promptAngle: PromptAngle        // conversational direction derived from note meaning
    let specificityLevel: SpecificityLevel // how pointed the final prompt should be
    let topEntity: String?
    let temporalState: TemporalState
}
