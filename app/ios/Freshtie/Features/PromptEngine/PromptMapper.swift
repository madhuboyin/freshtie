import Foundation

/// Maps a NoteInterpretationResult to the correct PromptLibrary pool.
///
/// Routing is driven by `promptAngle + specificityLevel` — the two new fields that
/// form the middle layer between note meaning and final prompt wording.
///
/// Specificity hierarchy: specific → contextual → neutral → generic.
/// Wrong specificity is worse than generic; when in doubt, use a lower tier.
enum PromptMapper {

    static func pool(for result: NoteInterpretationResult) -> [String] {
        switch result.promptAngle {

        case .oldConnectionCatchUp:
            return oldConnectionPool(for: result)

        case .socialConnectionAnchor:
            // Family or social relation context — safe generic framing, no family/kids prompts.
            return PromptLibrary.generic

        case .busyWorkCheckIn:
            return PromptLibrary.workActivity

        case .careerUpdate:
            return result.specificityLevel == .specific
                ? PromptLibrary.professional
                : PromptLibrary.safeColleaguePool

        case .relocationUpdate:
            return result.temporalState == .past
                ? PromptLibrary.moveAfter
                : PromptLibrary.moveBefore

        case .travelUpdate:
            return result.temporalState == .past
                ? PromptLibrary.travelAfter
                : PromptLibrary.travelBefore

        case .familyEventFollowUp:
            return result.temporalState == .past
                ? PromptLibrary.lifeEventAfter
                : PromptLibrary.lifeEventBefore

        case .lifeUpdateCheckIn:
            return lifeUpdatePool(for: result)

        case .backgroundSoftAnchor:
            return PromptLibrary.generic

        case .genericCatchUp:
            return PromptLibrary.generic
        }
    }

    // MARK: - Private helpers

    private static func oldConnectionPool(for result: NoteInterpretationResult) -> [String] {
        switch result.relationship {
        case .oldClassmate, .currentClassmate:
            return PromptLibrary.classmateCatchUp
        case .oldColleague:
            return PromptLibrary.colleagueCatchUp
        case .currentColleague:
            return PromptLibrary.safeColleaguePool
        default:
            // Unknown relationship in catch-up context — use classmate catch-up as safe default
            return PromptLibrary.classmateCatchUp
        }
    }

    private static func lifeUpdatePool(for result: NoteInterpretationResult) -> [String] {
        switch result.topic {
        case .educationCurrent: return PromptLibrary.school
        case .health:           return PromptLibrary.health
        default:                return PromptLibrary.workActivity   // soft situation check-in
        }
    }
}
