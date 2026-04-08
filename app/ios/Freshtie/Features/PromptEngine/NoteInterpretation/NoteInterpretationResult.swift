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

// MARK: - Conversational Handle

/// The safest practical conversational direction encoded in a note.
///
/// Unlike PromptAngle (which describes the semantic category of the note),
/// ConversationalHandle represents what the person can naturally be asked about —
/// the "what could I ask about?" layer used to produce contextual-soft prompts
/// before falling all the way back to generic.
///
/// Selection order in PromptMapper:
///   1. Highly specific prompt  (specific SpecificityLevel, event-rich)
///   2. Contextual-soft prompt  (ConversationalHandle drives pool selection)
///   3. Generic fallback        (only when handle == .generic)
enum ConversationalHandle {
    /// Person had a medical procedure or surgery — check in on recovery.
    case recoveryCheckin
    /// Person manages or helps with a property — check in on that situation.
    case propertySupportCheckin
    /// Person is associated with a location — light location-aware framing.
    case locationAnchor
    /// Person is an old contact — gentle reconnect framing.
    case oldConnectionCatchup
    /// Person is identified via a shared person ("cousin of X", "son of X") — soft neutral framing.
    case sharedConnectionAnchor
    /// Person is a direct family relation ("my cousin", "my uncle") — gentle family-aware framing.
    /// Must NOT produce prompts about spouse, kids, or household.
    case familyRelationSoft
    /// Person is busy at work — soft effort-neutral check-in.
    case busyWorkCheckin
    /// Person had a career update — professional framing.
    case careerUpdate
    /// Person relocated — relocation-aware framing.
    case relocationUpdate
    /// Person is traveling — travel-aware framing.
    case travelUpdate
    /// Person had a family life event — event-aware framing.
    case familyEventFollowup
    /// Person has a general life update — soft check-in.
    case lifeUpdateCheckin
    /// No safe directional hook available — pure generic fallback.
    case generic
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
    /// Where-from, whose relative — background fact with a soft anchor.
    case backgroundSoftAnchor
    /// No meaningful direction — pure safe generic output.
    case genericCatchUp
}

// MARK: - Specificity Level

/// Controls how directly the Prompt Composer references note context.
///
/// Hierarchy (high → low): specific → contextual → contextualSoft → neutral → generic
/// Wrong specificity is worse than generic — prefer downgrading over misfiring.
enum SpecificityLevel {
    /// High-confidence, event-rich note — prompt can reference the topic directly.
    case specific
    /// Note gives relational or activity context — prompt is note-aware but softer.
    case contextual
    /// Note provides a soft directional hook but not a clear event —
    /// prompts feel connected without overclaiming. Sits between contextual and neutral.
    case contextualSoft
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
    /// The safest practical "what can I ask about?" direction.
    /// Used by PromptMapper to select a contextual-soft pool before falling back to generic.
    let conversationalHandle: ConversationalHandle
    let topEntity: String?
    let temporalState: TemporalState
}
