import Foundation

/// Maps a NoteInterpretationResult to the correct PromptLibrary pool.
///
/// Called by PromptEngine when NoteInterpreter produces a non-weak result.
/// Falls back to PromptLibrary.generic for any unhandled combination.
enum PromptMapper {

    static func pool(for result: NoteInterpretationResult) -> [String] {
        switch result.promptability {
        case .low:
            return PromptLibrary.generic

        case .medium:
            return mediumPool(for: result)

        case .high:
            return highPool(for: result)
        }
    }

    // MARK: - Medium (catch-up / soft intent)

    private static func mediumPool(for result: NoteInterpretationResult) -> [String] {
        guard result.kind == .relationshipContext else { return PromptLibrary.generic }

        switch result.relationship {
        case .oldClassmate:
            return PromptLibrary.classmateCatchUp
        case .currentClassmate:
            return PromptLibrary.school
        case .oldColleague:
            return PromptLibrary.colleagueCatchUp
        case .currentColleague:
            return PromptLibrary.safeColleaguePool
        case .familyRelation:
            return PromptLibrary.family
        case .acquaintance, .unknown:
            return PromptLibrary.generic
        }
    }

    // MARK: - High (specific intent + temporal)

    private static func highPool(for result: NoteInterpretationResult) -> [String] {
        switch result.kind {
        case .lifeEvent:
            return lifeEventPool(topic: result.topic, state: result.temporalState)
        case .ongoingTopic:
            return ongoingTopicPool(topic: result.topic, state: result.temporalState)
        default:
            return PromptLibrary.generic
        }
    }

    private static func lifeEventPool(topic: TopicType, state: TemporalState) -> [String] {
        switch topic {
        case .familyEvent:
            return state == .past ? PromptLibrary.lifeEventAfter : PromptLibrary.lifeEventBefore
        case .companyOrJob:
            return PromptLibrary.professional
        case .relocation:
            return state == .past ? PromptLibrary.moveAfter : PromptLibrary.moveBefore
        default:
            return PromptLibrary.generic
        }
    }

    private static func ongoingTopicPool(topic: TopicType, state: TemporalState) -> [String] {
        switch topic {
        case .travel:
            return state == .past ? PromptLibrary.travelAfter : PromptLibrary.travelBefore
        case .health:
            return PromptLibrary.health
        case .educationCurrent:
            return PromptLibrary.school
        case .workActivity:
            return PromptLibrary.workActivity
        default:
            return PromptLibrary.generic
        }
    }
}
