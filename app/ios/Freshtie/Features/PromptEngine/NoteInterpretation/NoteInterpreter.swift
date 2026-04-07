import Foundation

/// Converts raw note text into structured semantic meaning.
///
/// Priority order (first match wins):
///   1. Relationship context — catches "degree class mate" BEFORE school keywords fire.
///   2. Identity background — "son of X", "is from Dubai" → low promptability, generic only.
///   3. Life events — joined company, moved city, had baby, got married.
///   4. Ongoing topics — trip planning, health recovery.
///   5. Weak signal — delegate to the existing keyword pipeline.
enum NoteInterpreter {

    static func interpret(_ note: Note, now: Date = Date()) -> NoteInterpretationResult {
        interpret(rawText: note.rawText, noteDate: note.createdAt, now: now)
    }

    /// Visible for testing.
    static func interpret(rawText: String, noteDate: Date, now: Date = Date()) -> NoteInterpretationResult {
        let lower  = rawText.lowercased()
        let entity = KeywordExtractor.extractTopEntity(from: rawText)
        let temporal = TemporalLogic.state(for: rawText, noteDate: noteDate, now: now)

        // 1. Relationship context
        if let rel = detectRelationship(in: lower) {
            return NoteInterpretationResult(
                kind: .relationshipContext,
                relationship: rel,
                topic: .unknown,
                promptability: .medium,
                topEntity: entity,
                temporalState: temporal
            )
        }

        // 2. Identity background
        if isIdentityBackground(lower) {
            return NoteInterpretationResult(
                kind: .identityBackground,
                relationship: .unknown,
                topic: .locationBackground,
                promptability: .low,
                topEntity: entity,
                temporalState: temporal
            )
        }

        // 3. Life events
        if let topic = detectLifeEvent(in: lower) {
            return NoteInterpretationResult(
                kind: .lifeEvent,
                relationship: .unknown,
                topic: topic,
                promptability: .high,
                topEntity: entity,
                temporalState: temporal
            )
        }

        // 4. Ongoing topics
        if let topic = detectOngoingTopic(in: lower) {
            return NoteInterpretationResult(
                kind: .ongoingTopic,
                relationship: .unknown,
                topic: topic,
                promptability: .high,
                topEntity: entity,
                temporalState: temporal
            )
        }

        // 5. Weak signal — caller falls back to existing keyword pipeline
        return NoteInterpretationResult(
            kind: .weakSignal,
            relationship: .unknown,
            topic: .unknown,
            promptability: .low,
            topEntity: entity,
            temporalState: temporal
        )
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

        // Extended family relation (NOT identity like "son of X" — that's identityBackground)
        let familyRelationPatterns = ["cousin", "uncle", "aunt", "nephew", "niece",
                                      "brother-in-law", "sister-in-law"]
        if familyRelationPatterns.contains(where: { lower.contains($0) }) { return .familyRelation }

        // Acquaintance
        let acquaintancePatterns = ["friend of a friend", "mutual friend", "neighbor"]
        if acquaintancePatterns.contains(where: { lower.contains($0) }) { return .acquaintance }

        return nil
    }

    // MARK: - Identity Background Detection

    private static func isIdentityBackground(_ lower: String) -> Bool {
        // "son of X", "daughter of X" — pure identity, no conversation hook
        let familyIdentityPhrases = ["son of ", "daughter of ", "child of ", "kid of "]
        if familyIdentityPhrases.contains(where: { lower.contains($0) }) { return true }

        // "he is from X", "originally from X" — location as background fact
        // Intentionally specific to avoid catching "recovering from surgery"
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
        let travelPhrases = ["trip to", "traveling to", "travelling to", "visiting", "planning a trip"]
        if travelPhrases.contains(where: { lower.contains($0) }) { return .travel }

        let healthPhrases = ["recovering from", "surgery", "in hospital", "fell sick", "health issue", "treatment"]
        if healthPhrases.contains(where: { lower.contains($0) }) { return .health }

        let educationPhrases = ["studying", "enrolled in", "doing a course", "in school", "at university", "at college"]
        if educationPhrases.contains(where: { lower.contains($0) }) { return .educationCurrent }

        return nil
    }
}
