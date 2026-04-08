import Foundation

/// Converts raw note text into structured semantic meaning.
///
/// Priority order (first match wins):
///   1. Relationship context  — catches "degree class mate" BEFORE school keywords fire.
///   2. Property support      — catches "looks after my place" BEFORE "is from" identity fires.
///   3. Identity background   — "son of X", "is from Dubai" → background fact with soft anchor.
///   4. Life events           — joined company, moved city, had baby, got married.
///   5. Ongoing topics        — trip planning, health recovery, work busyness.
///   6. Weak signal           — delegate to the existing keyword pipeline.
enum NoteInterpreter {

    static func interpret(_ note: Note, now: Date = Date()) -> NoteInterpretationResult {
        interpret(rawText: note.rawText, noteDate: note.createdAt, now: now)
    }

    /// Visible for testing.
    static func interpret(rawText: String, noteDate: Date, now: Date = Date()) -> NoteInterpretationResult {
        let lower   = rawText.lowercased()
        let entity  = KeywordExtractor.extractTopEntity(from: rawText)
        let temporal = TemporalLogic.state(for: rawText, noteDate: noteDate, now: now)

        // 1. Relationship context
        if let rel = detectRelationship(in: lower) {
            let angle   = deriveAngle(kind: .relationshipContext, relationship: rel, topic: .unknown)
            let spec    = deriveSpecificity(kind: .relationshipContext, topic: .unknown, relationship: rel)
            let handle  = deriveConversationalHandle(kind: .relationshipContext, relationship: rel,
                                                     topic: .unknown, lower: lower, entity: entity)
            return NoteInterpretationResult(
                kind: .relationshipContext,
                relationship: rel,
                topic: .unknown,
                promptability: .medium,
                promptAngle: angle,
                specificityLevel: spec,
                conversationalHandle: handle,
                topEntity: entity,
                temporalState: temporal
            )
        }

        // 2. Property / support context — checked BEFORE identity background so that a note
        //    like "he is from Bangalore. He looks after my place" routes to propertySupportCheckin
        //    rather than being swallowed by the "is from" identity-background pattern.
        if detectPropertySupport(in: lower) {
            return NoteInterpretationResult(
                kind: .ongoingTopic,
                relationship: .unknown,
                topic: .unknown,
                promptability: .medium,
                promptAngle: .backgroundSoftAnchor,
                specificityLevel: .contextualSoft,
                conversationalHandle: .propertySupportCheckin,
                topEntity: entity,
                temporalState: temporal
            )
        }

        // 3. Identity background
        if isIdentityBackground(lower) {
            let handle = deriveIdentityHandle(lower: lower, entity: entity)
            let spec: SpecificityLevel = handle == .generic ? .neutral : .contextualSoft
            return NoteInterpretationResult(
                kind: .identityBackground,
                relationship: .unknown,
                topic: .locationBackground,
                promptability: .low,
                promptAngle: .backgroundSoftAnchor,
                specificityLevel: spec,
                conversationalHandle: handle,
                topEntity: entity,
                temporalState: temporal
            )
        }

        // 4. Life events
        if let topic = detectLifeEvent(in: lower) {
            let angle  = deriveAngle(kind: .lifeEvent, relationship: .unknown, topic: topic)
            let handle = deriveConversationalHandle(kind: .lifeEvent, relationship: .unknown,
                                                    topic: topic, lower: lower, entity: entity)
            return NoteInterpretationResult(
                kind: .lifeEvent,
                relationship: .unknown,
                topic: topic,
                promptability: .high,
                promptAngle: angle,
                specificityLevel: .specific,
                conversationalHandle: handle,
                topEntity: entity,
                temporalState: temporal
            )
        }

        // 5. Ongoing topics
        if let topic = detectOngoingTopic(in: lower) {
            let angle  = deriveAngle(kind: .ongoingTopic, relationship: .unknown, topic: topic)
            let spec   = deriveSpecificity(kind: .ongoingTopic, topic: topic, relationship: .unknown)
            let handle = deriveConversationalHandle(kind: .ongoingTopic, relationship: .unknown,
                                                    topic: topic, lower: lower, entity: entity)
            return NoteInterpretationResult(
                kind: .ongoingTopic,
                relationship: .unknown,
                topic: topic,
                promptability: .high,
                promptAngle: angle,
                specificityLevel: spec,
                conversationalHandle: handle,
                topEntity: entity,
                temporalState: temporal
            )
        }

        // 6. Weak signal — caller falls back to existing keyword pipeline
        return NoteInterpretationResult(
            kind: .weakSignal,
            relationship: .unknown,
            topic: .unknown,
            promptability: .low,
            promptAngle: .genericCatchUp,
            specificityLevel: .generic,
            conversationalHandle: .generic,
            topEntity: entity,
            temporalState: temporal
        )
    }

    // MARK: - Angle + Specificity Derivation

    /// Derives the conversational angle from the semantic classification.
    private static func deriveAngle(
        kind: NoteKind,
        relationship: RelationshipType,
        topic: TopicType
    ) -> PromptAngle {
        switch kind {
        case .relationshipContext:
            switch relationship {
            case .oldClassmate, .currentClassmate: return .oldConnectionCatchUp
            case .oldColleague:                    return .oldConnectionCatchUp
            case .currentColleague:                return .busyWorkCheckIn
            case .familyRelation:                  return .socialConnectionAnchor
            case .acquaintance, .unknown:           return .genericCatchUp
            }
        case .identityBackground:
            return .backgroundSoftAnchor
        case .lifeEvent:
            switch topic {
            case .companyOrJob: return .careerUpdate
            case .relocation:   return .relocationUpdate
            case .familyEvent:  return .familyEventFollowUp
            default:            return .lifeUpdateCheckIn
            }
        case .ongoingTopic:
            switch topic {
            case .workActivity:                    return .busyWorkCheckIn
            case .travel:                          return .travelUpdate
            case .health, .lifeUpdate:             return .lifeUpdateCheckIn
            case .educationCurrent:                return .lifeUpdateCheckIn
            default:                               return .backgroundSoftAnchor
            }
        case .weakSignal:
            return .genericCatchUp
        }
    }

    /// Derives how pointed the final prompt should be.
    private static func deriveSpecificity(
        kind: NoteKind,
        topic: TopicType,
        relationship: RelationshipType
    ) -> SpecificityLevel {
        switch kind {
        case .lifeEvent:
            return .specific
        case .ongoingTopic:
            switch topic {
            case .workActivity:     return .contextual
            case .travel:           return .specific
            case .health:           return .contextual
            case .educationCurrent: return .contextual
            default:                return .neutral
            }
        case .relationshipContext:
            switch relationship {
            case .oldClassmate, .currentClassmate,
                 .oldColleague, .currentColleague,
                 .familyRelation:
                return .contextual
            case .acquaintance, .unknown:
                return .neutral
            }
        case .identityBackground:
            return .neutral          // preserved for backward compat; contextualSoft set per-handle above
        case .weakSignal:
            return .generic
        }
    }

    // MARK: - Conversational Handle Derivation

    /// Derives the safest "what can I ask about?" direction from the classified note.
    private static func deriveConversationalHandle(
        kind: NoteKind,
        relationship: RelationshipType,
        topic: TopicType,
        lower: String,
        entity: String?
    ) -> ConversationalHandle {
        switch kind {
        case .relationshipContext:
            switch relationship {
            case .familyRelation:                  return .familyRelationSoft
            case .oldClassmate, .currentClassmate: return .oldConnectionCatchup
            case .oldColleague:                    return .oldConnectionCatchup
            case .currentColleague:                return .busyWorkCheckin
            case .acquaintance, .unknown:           return .generic
            }
        case .identityBackground:
            return deriveIdentityHandle(lower: lower, entity: entity)
        case .lifeEvent:
            switch topic {
            case .companyOrJob: return .careerUpdate
            case .relocation:   return .relocationUpdate
            case .familyEvent:  return .familyEventFollowup
            default:            return .lifeUpdateCheckin
            }
        case .ongoingTopic:
            switch topic {
            case .health:           return .recoveryCheckin
            case .travel:           return .travelUpdate
            case .workActivity:     return .busyWorkCheckin
            case .educationCurrent: return .lifeUpdateCheckin
            default:                return .lifeUpdateCheckin
            }
        case .weakSignal:
            return .generic
        }
    }

    /// Maps an identity-background note to the most useful conversational handle.
    ///
    /// Priority:
    ///   "cousin of X", "son of X" etc. + location entity present → locationAnchor
    ///   "cousin of X", "son of X" etc. + no entity              → sharedConnectionAnchor
    ///   "is from X", "originally from X" + entity present       → locationAnchor
    ///   "is from X", "originally from X" + no entity            → generic
    static func deriveIdentityHandle(lower: String, entity: String?) -> ConversationalHandle {
        // Third-party relation phrases: "son of X", "cousin of X", "friend of X"
        let sharedRelationPhrases = [
            "son of ", "daughter of ", "child of ", "kid of ",
            "cousin of ", "brother of ", "sister of ",
            "uncle of ", "aunt of ", "nephew of ", "niece of ", "friend of ",
        ]
        if sharedRelationPhrases.contains(where: { lower.contains($0) }) {
            // If the note also names a location entity, use that as the soft anchor.
            return entity != nil ? .locationAnchor : .sharedConnectionAnchor
        }

        // Location-as-background: "is from X", "originally from X", etc.
        let locationPhrases = [" is from ", "originally from ", "born in ", "grew up in ", "native of "]
        if locationPhrases.contains(where: { lower.contains($0) }) {
            return entity != nil ? .locationAnchor : .generic
        }

        return .generic
    }

    // MARK: - Relationship Detection

    private static func detectRelationship(in lower: String) -> RelationshipType? {
        // Old classmate — checked before bare "classmate" to prevent school-prompt misfires
        let oldClassmatePatterns = [
            "degree class mate", "degree classmate",
            "ex classmate", "ex class mate",
            "old classmate", "old class mate",
            "former classmate", "former class mate",
            "school friend", "college friend", "uni friend",
            "batch mate", "batchmate",
        ]
        if oldClassmatePatterns.contains(where: { lower.contains($0) }) { return .oldClassmate }

        // Current classmate
        let currentClassmatePatterns = ["classmate", "class mate", "study buddy"]
        if currentClassmatePatterns.contains(where: { lower.contains($0) }) { return .currentClassmate }

        // Old colleague
        let oldColleaguePatterns = [
            "ex colleague", "ex-colleague", "former colleague",
            "ex coworker", "ex-coworker", "former coworker",
            "old colleague", "old coworker",
            "used to work with", "used to work together",
        ]
        if oldColleaguePatterns.contains(where: { lower.contains($0) }) { return .oldColleague }

        // Current colleague
        let currentColleaguePatterns = ["colleague", "coworker", "co-worker", "teammate", "team mate"]
        if currentColleaguePatterns.contains(where: { lower.contains($0) }) { return .currentColleague }

        // "cousin of X", "friend of X" = identity (this person IS someone's relation),
        // not a family-event context. Guard before bare-word match so it falls to isIdentityBackground.
        let familyIdentityOfPatterns = [
            "cousin of ", "brother of ", "sister of ", "uncle of ", "aunt of ",
            "nephew of ", "niece of ", "friend of ",
        ]
        if familyIdentityOfPatterns.contains(where: { lower.contains($0) }) { return nil }

        // Extended family relation (NOT identity like "son of X" — that's identityBackground)
        let familyRelationPatterns = ["cousin", "uncle", "aunt", "nephew", "niece",
                                      "brother-in-law", "sister-in-law"]
        if familyRelationPatterns.contains(where: { lower.contains($0) }) { return .familyRelation }

        // Acquaintance
        let acquaintancePatterns = ["friend of a friend", "mutual friend", "neighbor"]
        if acquaintancePatterns.contains(where: { lower.contains($0) }) { return .acquaintance }

        return nil
    }

    // MARK: - Property / Support Detection

    /// Returns true when the note indicates the person manages or supports a property or place.
    ///
    /// Checked BEFORE `isIdentityBackground` so that notes like
    /// "he is from Bangalore. He looks after my place there" do not get swallowed by
    /// the generic "is from" identity pattern.
    private static func detectPropertySupport(in lower: String) -> Bool {
        let supportVerbs = ["looks after", "takes care of", "manages my", "caretaker of"]
        let propertyNouns = ["my place", "my property", "my flat", "my apartment",
                             "my house", "my home", "the property", "the place"]
        let hasSupportVerb   = supportVerbs.contains(where:   { lower.contains($0) })
        let hasPropertyNoun  = propertyNouns.contains(where:  { lower.contains($0) })
        return hasSupportVerb && hasPropertyNoun
    }

    // MARK: - Identity Background Detection

    private static func isIdentityBackground(_ lower: String) -> Bool {
        // "son of X", "cousin of X" etc. — pure identity, no conversation hook
        let familyIdentityPhrases = [
            "son of ", "daughter of ", "child of ", "kid of ",
            "cousin of ", "brother of ", "sister of ",
            "uncle of ", "aunt of ", "nephew of ", "niece of ", "friend of ",
        ]
        if familyIdentityPhrases.contains(where: { lower.contains($0) }) { return true }

        // "he is from X", "originally from X" — location as background fact.
        // Intentionally specific to avoid catching "recovering from surgery".
        let locationBackgroundPhrases = [" is from ", "originally from ", "born in ", "grew up in ", "native of "]
        if locationBackgroundPhrases.contains(where: { lower.contains($0) }) { return true }

        return false
    }

    // MARK: - Life Event Detection

    private static func detectLifeEvent(in lower: String) -> TopicType? {
        // Family events — checked first because they're high-signal
        let familyEventPhrases = [
            "getting married", "is getting married", "wedding",
            "had a baby", "having a baby", "expecting a baby", "pregnant",
            "gave birth", "newborn", "new baby", "had a boy", "had a girl",
            "had a baby boy", "had a baby girl",
        ]
        if familyEventPhrases.contains(where: { lower.contains($0) }) { return .familyEvent }

        // Job / company change
        let jobPhrases = [
            "joined", "started at", "new job", "new role", "new position",
            "accepted an offer", "switched companies", "different company",
            "new company", "changed jobs",
        ]
        if jobPhrases.contains(where: { lower.contains($0) }) { return .companyOrJob }

        // Physical relocation — guard against "moved to a different company"
        let relocationPhrases = [
            "moving to", "moved to", "relocating to", "relocated to",
            "shifting to", "shifted to",
        ]
        if relocationPhrases.contains(where: { lower.contains($0) }) {
            let jobContextWords = ["company", "companies", "role", "job", "offer", "position", "team"]
            if !jobContextWords.contains(where: { lower.contains($0) }) {
                return .relocation
            }
        }

        return nil
    }

    // MARK: - Ongoing Topic Detection

    private static func detectOngoingTopic(in lower: String) -> TopicType? {
        // Work activity / busyness — checked FIRST to prevent "working hard" from reaching
        // the keyword pipeline where "working" triggers professional/new-role prompts.
        let workActivityPhrases = [
            "working hard", "working very hard", "working really hard",
            "busy at work", "very busy with work", "hectic at work", "hectic schedule",
            "long hours", "lots of work", "overloaded with work",
            "been very busy", "been really busy", "so busy",
        ]
        if workActivityPhrases.contains(where: { lower.contains($0) }) { return .workActivity }

        let travelPhrases = ["trip to", "traveling to", "travelling to", "visiting", "planning a trip"]
        if travelPhrases.contains(where: { lower.contains($0) }) { return .travel }

        // Health / recovery — includes surgical / medical procedure notes.
        let healthPhrases = [
            "recovering from", "surgery", "in hospital", "fell sick",
            "health issue", "treatment",
            "got operated", "had operation", "had an operation", "had surgery",
            "operated", "underwent surgery", "medical procedure",
        ]
        if healthPhrases.contains(where: { lower.contains($0) }) { return .health }

        let educationPhrases = ["studying", "enrolled in", "doing a course", "in school", "at university", "at college"]
        if educationPhrases.contains(where: { lower.contains($0) }) { return .educationCurrent }

        return nil
    }
}
