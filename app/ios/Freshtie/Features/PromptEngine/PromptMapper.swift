import Foundation

/// Maps a NoteInterpretationResult to the correct PromptLibrary pool.
///
/// Routing hierarchy — specific → contextual-soft → generic:
///   1. Highly specific angles (career, relocation, travel, life event) use event-aware pools.
///   2. Soft-anchor angles (backgroundSoftAnchor, socialConnectionAnchor) route through
///      `contextualSoftPool`, which uses ConversationalHandle to pick a note-connected pool
///      before falling back to generic.
///   3. genericCatchUp uses the generic pool directly.
///
/// Wrong specificity is worse than generic; when in doubt, use a lower tier.
enum PromptMapper {

    static func pool(for result: NoteInterpretationResult) -> [String] {
        switch result.promptAngle {

        case .oldConnectionCatchUp:
            return oldConnectionPool(for: result)

        case .socialConnectionAnchor:
            // Family or social relation — use ConversationalHandle for contextual-soft framing.
            // Must NOT produce family/kids/household prompts.
            return contextualSoftPool(for: result)

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
            // Identity / background note — use ConversationalHandle to try contextual-soft
            // before falling back to generic.
            return contextualSoftPool(for: result)

        case .genericCatchUp:
            return PromptLibrary.generic
        }
    }

    // MARK: - Contextual-Soft Routing

    /// Routes a soft-anchor note through its ConversationalHandle.
    ///
    /// Selection order:
    ///   1. Specific contextual-soft pool keyed by handle
    ///   2. Generic fallback (only when handle == .generic)
    private static func contextualSoftPool(for result: NoteInterpretationResult) -> [String] {
        switch result.conversationalHandle {
        case .recoveryCheckin:
            return PromptLibrary.recoveryCheckin
        case .propertySupportCheckin:
            return PromptLibrary.propertySupportCheckin
        case .locationAnchor:
            return PromptLibrary.locationAnchor
        case .familyRelationSoft:
            return PromptLibrary.familyRelationSoft
        case .sharedConnectionAnchor:
            return PromptLibrary.softCatchUp
        case .busyWorkCheckin:
            return PromptLibrary.workActivity
        case .oldConnectionCatchup:
            return PromptLibrary.classmateCatchUp
        case .careerUpdate:
            return PromptLibrary.professional
        case .relocationUpdate:
            return PromptLibrary.moveAfter
        case .travelUpdate:
            return PromptLibrary.travelAfter
        case .familyEventFollowup:
            return PromptLibrary.lifeEventAfter
        case .lifeUpdateCheckin:
            return PromptLibrary.workActivity
        case .generic:
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
            return PromptLibrary.classmateCatchUp
        }
    }

    private static func lifeUpdatePool(for result: NoteInterpretationResult) -> [String] {
        switch result.topic {
        case .educationCurrent: return PromptLibrary.school
        case .health:           return PromptLibrary.health
        default:                return PromptLibrary.workActivity
        }
    }
}
