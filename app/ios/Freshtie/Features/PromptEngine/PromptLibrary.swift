import Foundation

/// Curated, production-grade library of prompts organized by intent and temporal state.
/// All prompts are natural, human-sounding, and socially safe.
enum PromptLibrary {

    /// Returns a pool of prompts based on category, state, and confidence.
    static func pool(for category: PromptCategory, state: TemporalState, confidence: ConfidenceLevel) -> [String] {
        // Low confidence always falls back to generic
        guard confidence != .low else { return generic }

        // Medium confidence uses safe, less specific intent prompts
        if confidence == .medium {
            return safeIntentPool(for: category)
        }

        // High confidence uses specific intent + temporal state prompts
        switch category {
        case .professional: return professional
        case .travel:       return state == .past ? travelAfter : travelBefore
        case .move:         return state == .past ? moveAfter : moveBefore
        case .family:       return family
        case .lifeEvent:    return state == .past ? lifeEventAfter : lifeEventBefore
        case .school:       return school
        case .health:       return health
        case .generic:      return generic
        }
    }

    // MARK: - Generic (Safety Net)

    static let generic = [
        "What have you been up to lately?",
        "How have things been going?",
        "Anything new since we last spoke?",
        "What’s been keeping you busy lately?",
        "How’s everything going?",
        "How are you doing these days?",
        "Catch me up — what's new?",
        "How's life been lately?"
    ]

    // MARK: - Medium Confidence (Safe Contextual)

    private static func safeIntentPool(for category: PromptCategory) -> [String] {
        switch category {
        case .professional: return ["How's work going?", "How are things at the office?", "How's the career treating you?"]
        case .travel:       return ["How was the travel?", "Any fun trips lately?", "Where to next?"]
        case .move:         return ["How's the new place?", "Are you all settled in?", "How's the neighborhood?"]
        case .family:       return ["How's the family doing?", "How is everyone at home?", "How are things with the family?"]
        case .lifeEvent:    return ["How have things been since the big event?", "How did everything turn out?", "How's life been lately?"]
        case .school:       return ["How's school been going?", "How are classes?", "How is the semester treating you?"]
        case .health:       return ["How are you feeling now?", "How's everything going health-wise?", "Hope you're doing better — how have things been?"]
        case .generic:      return generic
        }
    }

    // MARK: - High Confidence (Intent + Time)

    static let professional = [
        "How are things at {entity}?",
        "How’s the new role going?",
        "How have things been settling in at work?",
        "How's the new job treating you?",
        "Are you enjoying the new position?"
    ]

    static let travelBefore = [
        "How’s the {entity} trip planning going?",
        "Are you excited for the trip?",
        "When do you leave?",
        "All set for the upcoming travels?",
        "Counting down the days until the trip?"
    ]

    static let travelAfter = [
        "How was the {entity} trip?",
        "How did the travel go?",
        "What was the highlight of the trip?",
        "Welcome back! How was the experience?",
        "Did you have a good time on the trip?"
    ]

    static let moveBefore = [
        "How’s the move planning going?",
        "Are you all set for the move?",
        "When are you moving?",
        "How's the packing coming along?",
        "Excited to get settled in the new place?"
    ]

    static let moveAfter = [
        "How’s the new place?",
        "How are you settling in?",
        "How’s life in the new city?",
        "How is the new neighborhood treating you?",
        "Everything coming together in the new home?"
    ]

    static let family = [
        "How's the family?",
        "How are the kids doing?",
        "How's everyone at home?",
        "How is {entity} doing?",
        "Hope the family is doing well — how are they?"
    ]

    static let lifeEventBefore = [
        "How are the preparations coming along?",
        "How’s everything coming together?",
        "Are you excited for it?",
        "Almost time — how are you feeling?",
        "Is everything ready for the big day?"
    ]

    static let lifeEventAfter = [
        "How did it go?",
        "How was the big day?",
        "How’s everyone doing after it?",
        "How have things been since then?",
        "What was the best part of the event?"
    ]

    static let school = [
        "How’s school been going?",
        "How are classes going?",
        "How’s the semester treating you?",
        "How's everything with your studies?",
        "Are you enjoying your courses this term?"
    ]

    static let health = [
        "How are you feeling now?",
        "How’s everything been going health-wise?",
        "Hope you’re doing better — how have things been?",
        "How are you holding up?",
        "How’s the recovery progressing?"
    ]

    // MARK: - Catch-Up (Relationship Context)

    /// For old classmates — reconnecting after time apart.
    static let classmateCatchUp = [
        "How have things been since college?",
        "What have you been up to these days?",
        "It’s been a while — how have things been?",
        "How’s life been since graduation?",
        "What are you working on these days?"
    ]

    /// For old colleagues — reconnecting after working together.
    static let colleagueCatchUp = [
        "What have you been up to since we worked together?",
        "How have things been going lately?",
        "It’s been a while — what are you working on these days?",
        "How’s work been treating you?",
        "What have you been up to?"
    ]

    /// For work-activity / busyness notes — safe, effort-neutral prompts.
    /// NOT used for job-change or new-role notes.
    static let workActivity = [
        "How has work been going?",
        "Sounds like you've been busy — how are things?",
        "How have things been lately?",
        "Hope the workload has settled down — how are you doing?",
        "How's everything going?"
    ]

    /// For current colleagues — soft professional check-in.
    static let safeColleaguePool = [
        "How’s work going?",
        "How are things at the office?",
        "How’s the project coming along?",
        "How’s the team doing?",
        "How’s everything going at work?"
    ]

    // MARK: - Contextual-Soft Pools (ConversationalHandle-driven)
    //
    // These pools sit between specific intent prompts and fully generic prompts.
    // They feel connected to the note without overclaiming or making strong assumptions.
    // Selected by PromptMapper when ConversationalHandle is set but specificity is low.

    /// Recovery / post-surgery check-in — "got operated", "recovering".
    static let recoveryCheckin = [
        "How are you feeling now?",
        "How has recovery been going?",
        "Hope you’re doing better — how have things been?",
        "How are you holding up?",
        "How’s everything been lately?"
    ]

    /// Property / place support — "looks after my place", "property".
    static let propertySupportCheckin = [
        "How have things been going on that front?",
        "How’s everything going with the place there?",
        "How have things been lately on that front?",
        "How are things holding up over there?",
        "How’s everything been on your side?"
    ]

    /// Location anchor — person is from or associated with a place.
    /// The {entity} token is substituted with the location name when available.
    static let locationAnchor = [
        "How have things been in {entity}?",
        "How’s life been there lately?",
        "What’s new with you these days?",
        "How are things going over there?",
        "How have things been on your side?"
    ]

    /// Direct family relation ("my cousin", "my uncle") — gentle, identity-aware framing.
    /// Must NOT contain spouse, kids, household, or home references.
    static let familyRelationSoft = [
        "How have things been with you lately?",
        "What’s new with you these days?",
        "How’s everything been on your side?",
        "How have things been going?",
        "What have you been up to lately?"
    ]

    /// Shared-connection anchor — person identified via a third party ("cousin of X", "son of X").
    /// Soft neutral framing with no assumption about the user’s relationship with them.
    static let softCatchUp = [
        "How have things been lately?",
        "What’s new with you these days?",
        "How’s everything been going?",
        "What have you been up to?",
        "How are things going?"
    ]
}
