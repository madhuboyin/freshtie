import Foundation

/// All prompt template strings, organized by category and temporal state.
///
/// Templates may contain `{entity}` as a substitution token.
/// Any template containing `{entity}` is silently dropped when no entity is available.
/// Each pool has ≥ 4 entries to support at least one full refresh cycle.
enum PromptTemplateLibrary {

    // MARK: - Generic (zero-signal fallback)

    static let generic: [String] = [
        "What have you been up to lately?",
        "Anything new since we last talked?",
        "How's everything going?",
        "What's been keeping you busy?",
        "How have things been going?",
        "How are you doing these days?",
        "Catch me up — what's new?",
        "What's going on with you?",
    ]

    // MARK: - Professional

    static let professional: [String] = [
        "How are things at {entity}?",
        "How's the new role going?",
        "How's work been going?",
        "Anything interesting happening at work?",
        "How's the new job treating you?",
        "How's everything coming along at work?",
    ]

    // MARK: - Travel

    static let travelBefore: [String] = [
        "How's the {entity} trip coming together?",
        "How's the trip planning going?",
        "Ready for the trip?",
        "Excited for the upcoming travels?",
        "All set for the trip?",
    ]

    static let travelAfter: [String] = [
        "How was the {entity} trip?",
        "How was the trip?",
        "What was the highlight of the trip?",
        "Welcome back — how did it go?",
        "How were the travels?",
    ]

    // MARK: - Move

    static let moveBefore: [String] = [
        "How's the move to {entity} coming along?",
        "How's the move coming together?",
        "All packed and ready for the move?",
        "How's the relocation going?",
        "Getting excited about the move?",
    ]

    static let moveAfter: [String] = [
        "How did the move to {entity} go?",
        "How's the new place?",
        "Settling in well?",
        "How's the new neighborhood?",
        "How's everything coming together in the new place?",
    ]

    // MARK: - Family

    static let family: [String] = [
        "How's the family?",
        "How are the kids?",
        "How's everyone doing?",
        "How's everything at home?",
        "How's {entity} doing?",
    ]

    // MARK: - Life event

    static let lifeEventBefore: [String] = [
        "How are the preparations coming along?",
        "How's everything coming together for the big day?",
        "Getting excited?",
        "How are the wedding preparations going?",
        "Almost time — how are you feeling about it?",
    ]

    static let lifeEventAfter: [String] = [
        "How did everything turn out?",
        "How was the big day?",
        "How was the wedding?",
        "How's the new baby doing?",
        "What's life been like since then?",
    ]

    // MARK: - School

    static let school: [String] = [
        "How's school going?",
        "How are the exams treating you?",
        "How's everything going with your studies?",
        "Surviving the coursework?",
        "How's everything at school?",
    ]

    // MARK: - Health

    static let health: [String] = [
        "How are you feeling these days?",
        "How's the recovery going?",
        "How are you holding up?",
        "Hope you're doing better — how are you feeling?",
        "How are things going health-wise?",
    ]

    // MARK: - Lookup

    static func pool(for category: PromptCategory, state: TemporalState) -> [String] {
        switch category {
        case .professional: return professional
        case .travel:       return state == .past ? travelAfter   : travelBefore
        case .move:         return state == .past ? moveAfter     : moveBefore
        case .family:       return family
        case .lifeEvent:    return state == .past ? lifeEventAfter : lifeEventBefore
        case .school:       return school
        case .health:       return health
        case .generic:      return generic
        }
    }

    // MARK: - Entity substitution

    /// Returns the pool with `{entity}` substituted where possible.
    /// Templates requiring an entity that isn't available are removed.
    static func resolved(pool: [String], entity: String?) -> [String] {
        pool.compactMap { template in
            guard template.contains("{entity}") else { return template }
            guard let e = entity else { return nil }
            return template.replacingOccurrences(of: "{entity}", with: e)
        }
    }
}
