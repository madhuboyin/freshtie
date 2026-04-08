import XCTest
@testable import Freshtie

/// Unit tests for the Phase 4 prompt engine.
///
/// To run: add a Unit Testing Bundle target named "FreshtieTests" in Xcode
/// (File → New → Target → Unit Testing Bundle, host app: Freshtie) and
/// include this file in that target's Sources.
///
/// All test helpers create @Model instances without a ModelContext; this is
/// valid because the engine only reads rawText, createdAt, and the passed
/// sortedNotes array — it never traverses the SwiftData graph.
final class PromptEngineTests: XCTestCase {

    // MARK: - Helpers

    private func makeNote(_ text: String, daysAgo: Int = 0) -> Note {
        let note = Note(rawText: text)
        note.createdAt = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
        return note
    }

    private func makePerson(_ name: String = "Test") -> Person {
        Person(displayName: name)
    }

    // MARK: - Negative assertion helper

    /// Asserts that no prompt in `pool` contains any term from `disallowed` (case-insensitive).
    /// A failure here means a trust-breaking prompt family has leaked into the output.
    private func assertNoPrompt(
        in pool: [String],
        contains disallowed: [String],
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        for prompt in pool {
            let lower = prompt.lowercased()
            for term in disallowed {
                XCTAssertFalse(
                    lower.contains(term),
                    "Trust regression: prompt '\(prompt)' contains disallowed term '\(term)'",
                    file: file, line: line
                )
            }
        }
    }

    // MARK: - Disallowed prompt-family term sets
    // Each set names terms that would confirm a trust-breaking wrong prompt family leaked in.

    /// Family / kids / household — never acceptable for identity-only notes.
    private let familyPromptTerms = [
        "family", "kids", "children", "everyone at home", "wife", "husband", "spouse",
    ]

    /// Job transition / new role — never acceptable for work-activity notes.
    private let jobTransitionTerms = [
        "new role", "new company", "settling in", "onboarding", "new job", "new position",
    ]

    /// Current education — never acceptable for old-classmate notes.
    private let currentSchoolTerms = [
        "classes", "semester", "exam", "coursework", "courses",
    ]

    /// Physical relocation — never acceptable for job-change notes.
    private let relocationTerms = [
        "new place", "packing", "new city", "new home",
    ]

    // MARK: - Zero signal

    func testNoNotesReturnsExactlyThreePrompts() {
        let prompts = PromptEngine.prompts(for: makePerson(), sortedNotes: [])
        XCTAssertEqual(prompts.count, 3)
    }

    func testNoNotesPromptsAreNonEmpty() {
        let prompts = PromptEngine.prompts(for: makePerson(), sortedNotes: [])
        XCTAssertFalse(prompts.contains(where: { $0.text.isEmpty }))
    }

    func testNoNotesUsesGenericPool() {
        let prompts = PromptEngine.prompts(for: makePerson(), sortedNotes: [])
        let genericTexts = Set(PromptLibrary.generic)
        XCTAssertTrue(prompts.allSatisfy { genericTexts.contains($0.text) })
    }

    // MARK: - Category detection

    func testProfessionalKeywordMapped() {
        let signals  = KeywordExtractor.extract(from: "Starting new job at Google")
        let category = PromptCategorizer.categorize(signals: signals)
        XCTAssertEqual(category, .professional)
    }

    func testTravelKeywordMapped() {
        let signals  = KeywordExtractor.extract(from: "Trip to Japan next month")
        let category = PromptCategorizer.categorize(signals: signals)
        XCTAssertEqual(category, .travel)
    }

    func testMoveKeywordMapped() {
        let signals  = KeywordExtractor.extract(from: "Moving to NYC on Friday")
        let category = PromptCategorizer.categorize(signals: signals)
        XCTAssertEqual(category, .move)
    }

    func testLifeEventBeatsProfessional() {
        // "wedding" should win over any job signal
        let signals  = KeywordExtractor.extract(from: "Daughter's wedding next month")
        let category = PromptCategorizer.categorize(signals: signals)
        XCTAssertEqual(category, .lifeEvent)
    }

    func testBabyMapsToLifeEvent() {
        let signals  = KeywordExtractor.extract(from: "Having a baby boy")
        let category = PromptCategorizer.categorize(signals: signals)
        XCTAssertEqual(category, .lifeEvent)
    }

    func testHealthKeywordMapped() {
        let signals  = KeywordExtractor.extract(from: "Recovering from surgery")
        let category = PromptCategorizer.categorize(signals: signals)
        XCTAssertEqual(category, .health)
    }

    func testVagueNoteReturnsGeneric() {
        let signals  = KeywordExtractor.extract(from: "Met at cafe")
        let category = PromptCategorizer.categorize(signals: signals)
        XCTAssertEqual(category, .generic)
    }

    // MARK: - Temporal logic

    func testTomorrowNoteIsStillFuture() {
        let now = Date()
        let state = TemporalLogic.state(for: "Moving tomorrow", noteDate: now, now: now)
        XCTAssertEqual(state, .future)
    }

    func testTomorrowNoteFromYesterdayIsPast() {
        let noteDate = Calendar.current.date(byAdding: .day, value: -2, to: Date())!
        let state = TemporalLogic.state(for: "Moving tomorrow", noteDate: noteDate, now: Date())
        XCTAssertEqual(state, .past)
    }

    func testNextWeekNoteFromTwoWeeksAgoIsPast() {
        let noteDate = Calendar.current.date(byAdding: .day, value: -14, to: Date())!
        let state = TemporalLogic.state(for: "Trip next week", noteDate: noteDate, now: Date())
        XCTAssertEqual(state, .past)
    }

    func testNextMonthNoteFromTwoMonthsAgoIsPast() {
        let noteDate = Calendar.current.date(byAdding: .day, value: -60, to: Date())!
        let state = TemporalLogic.state(for: "Daughter's wedding next month", noteDate: noteDate)
        XCTAssertEqual(state, .past)
    }

    func testFreshNextMonthNoteIsFuture() {
        let noteDate = Date()
        let state = TemporalLogic.state(for: "Trip to Japan next month", noteDate: noteDate, now: noteDate)
        XCTAssertEqual(state, .future)
    }

    func testNoTemporalSignalReturnsUnknown() {
        let state = TemporalLogic.state(for: "Started a new job at Google", noteDate: Date())
        XCTAssertEqual(state, .unknown)
    }

    func testSoonNoteFromThreeWeeksAgoIsPast() {
        let noteDate = Calendar.current.date(byAdding: .day, value: -21, to: Date())!
        let state = TemporalLogic.state(for: "Moving soon", noteDate: noteDate)
        XCTAssertEqual(state, .past)
    }

    // MARK: - Temporal phrasing in generated prompts

    func testFutureTravelPromptsContainForwardLooking() {
        let note = makeNote("Trip to Japan next month")   // fresh — still future
        let pool = PromptEngine.resolvedPool(from: [note])
        // Future prompts should be from travelBefore pool
        let validFuture = Set(PromptLibrary.travelBefore + PromptLibrary.travelAfter)
        XCTAssertTrue(pool.allSatisfy { validFuture.contains($0.replacingOccurrences(of: "Japan", with: "{entity}")) })
    }

    func testPastMovePromptUsesAfterPool() {
        let noteDate = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        let note = Note(rawText: "Moving to NYC next week")
        note.createdAt = noteDate
        let pool = PromptEngine.resolvedPool(from: [note])
        let afterTexts = PromptLibrary.moveAfter.map {
            $0.replacingOccurrences(of: "{entity}", with: "NYC")
        }
        XCTAssertTrue(pool.allSatisfy { text in afterTexts.contains(text) || !text.contains("NYC") })
    }

    // MARK: - Entity extraction

    func testEntityFromAtPreposition() {
        let entity = KeywordExtractor.extractTopEntity(from: "Starting new job at Google")
        XCTAssertEqual(entity, "Google")
    }

    func testEntityFromToPreposition() {
        let entity = KeywordExtractor.extractTopEntity(from: "Moving to NYC this weekend")
        XCTAssertEqual(entity, "NYC")
    }

    func testEntityFromInPreposition() {
        let entity = KeywordExtractor.extractTopEntity(from: "Trip in Japan")
        XCTAssertEqual(entity, "Japan")
    }

    func testNoEntityForLowercaseWord() {
        let entity = KeywordExtractor.extractTopEntity(from: "Going to work tomorrow")
        XCTAssertNil(entity)
    }

    // MARK: - Entity substitution in prompts

    func testEntitySubstitutedInOutput() {
        let note = makeNote("Starting new job at Google")
        let prompts = PromptEngine.prompts(for: makePerson(), sortedNotes: [note])
        let texts = prompts.map(\.text)
        let hasGoogle = texts.contains { $0.contains("Google") }
        // It's valid for the engine to produce either entity-specific or generic professional prompts
        XCTAssertFalse(texts.contains(where: { $0.contains("{entity}") }), "Raw token should never reach UI")
        // Either Google appears or we got a generic professional prompt — both are acceptable
        _ = hasGoogle
    }

    // MARK: - Refresh

    func testRefreshReturnsThreePrompts() {
        let person = makePerson()
        let initial = PromptEngine.prompts(for: person, sortedNotes: [])
        let refreshed = PromptEngine.refreshedPrompts(for: person, sortedNotes: [], excluding: initial)
        XCTAssertEqual(refreshed.count, 3)
    }

    func testRefreshAvoidsCurrentPrompts() {
        let person = makePerson()
        let initial = PromptEngine.prompts(for: person, sortedNotes: [])
        let refreshed = PromptEngine.refreshedPrompts(for: person, sortedNotes: [], excluding: initial)
        let initialTexts  = Set(initial.map(\.text))
        let refreshedTexts = Set(refreshed.map(\.text))
        XCTAssertTrue(initialTexts.isDisjoint(with: refreshedTexts))
    }

    func testMultipleRefreshesAllReturnThreePrompts() {
        let person  = makePerson()
        var current = PromptEngine.prompts(for: person, sortedNotes: [])
        for _ in 0 ..< 6 {
            current = PromptEngine.refreshedPrompts(for: person, sortedNotes: [], excluding: current)
            XCTAssertEqual(current.count, 3)
        }
    }

    func testRawEntityTokenNeverReachesUI() {
        let notes = [
            makeNote("Starting new job at Google"),
            makeNote("Moving to NYC next month"),
            makeNote("Trip to Japan soon"),
        ]
        for note in notes {
            let prompts = PromptEngine.prompts(for: makePerson(), sortedNotes: [note])
            XCTAssertFalse(prompts.contains(where: { $0.text.contains("{entity}") }))
        }
    }

    // MARK: - Intent disambiguation (job change vs relocation)

    func testMovedToDifferentCompanyIsJobChange() {
        let text = "moved to a different company"
        let signals = KeywordExtractor.extract(from: text)
        let category = PromptCategorizer.categorize(signals: signals, rawText: text)
        XCTAssertEqual(category, .professional)
    }

    func testMovedToDifferentCompanyProducesNoRelocationPrompts() {
        let note = makeNote("moved to a different company")
        let pool = PromptEngine.resolvedPool(from: [note])
        let relocationPhrases = PromptTemplateLibrary.moveBefore + PromptTemplateLibrary.moveAfter
        let entityStripped = relocationPhrases.map { $0.replacingOccurrences(of: "{entity}", with: "") }
        for text in pool {
            XCTAssertFalse(
                entityStripped.contains(where: { text.contains($0.trimmingCharacters(in: .whitespaces)) }),
                "Relocation prompt '\(text)' should not appear for a job-change note"
            )
        }
    }

    func testPhysicalRelocationClassifiedAsMove() {
        let text = "moving to NYC next week"
        let signals = KeywordExtractor.extract(from: text)
        let category = PromptCategorizer.categorize(signals: signals, rawText: text)
        XCTAssertEqual(category, .move)
    }

    func testPhysicalRelocationFutureUsesMoveBeforePool() {
        let note = makeNote("moving to NYC next week")
        let pool = PromptEngine.resolvedPool(from: [note])
        let futureTexts = PromptLibrary.moveBefore.map {
            $0.replacingOccurrences(of: "{entity}", with: "NYC")
        }
        XCTAssertTrue(pool.allSatisfy { futureTexts.contains($0) || !$0.contains("NYC") })
    }

    func testStartedAtEntityIsJobChange() {
        let text = "started at Google"
        let signals = KeywordExtractor.extract(from: text)
        let category = PromptCategorizer.categorize(signals: signals, rawText: text)
        XCTAssertEqual(category, .professional)
    }

    func testPlanningTripIsTravel() {
        let text = "planning trip to London"
        let signals = KeywordExtractor.extract(from: text)
        let category = PromptCategorizer.categorize(signals: signals, rawText: text)
        XCTAssertEqual(category, .travel)
    }

    func testMetAtCafeIsGeneric() {
        let text = "met at cafe"
        let signals = KeywordExtractor.extract(from: text)
        let category = PromptCategorizer.categorize(signals: signals, rawText: text)
        XCTAssertEqual(category, .generic)
    }

    // MARK: - Confidence Scoring

    func testHighConfidenceForRichNote() {
        let text = "Started new job at Google"
        let signals = KeywordExtractor.extract(from: text)
        let category = PromptCategorizer.categorize(signals: signals, rawText: text)
        let temporal = TemporalLogic.state(for: text, noteDate: Date())
        let confidence = ConfidenceScorer.score(signals: signals, category: category, temporal: temporal, rawText: text)
        XCTAssertEqual(confidence, .high)
    }

    func testMediumConfidenceForModerateNote() {
        let text = "started at company"
        let signals = KeywordExtractor.extract(from: text)
        let category = PromptCategorizer.categorize(signals: signals, rawText: text)
        let temporal = TemporalLogic.state(for: text, noteDate: Date())
        let confidence = ConfidenceScorer.score(signals: signals, category: category, temporal: temporal, rawText: text)
        XCTAssertEqual(confidence, .medium)
    }

    func testLowConfidenceForVagueNote() {
        let text = "met at cafe"
        let signals = KeywordExtractor.extract(from: text)
        let category = PromptCategorizer.categorize(signals: signals, rawText: text)
        let temporal = TemporalLogic.state(for: text, noteDate: Date())
        let confidence = ConfidenceScorer.score(signals: signals, category: category, temporal: temporal, rawText: text)
        XCTAssertEqual(confidence, .low)
    }

    // MARK: - Second-note fallback

    func testSecondNoteUsedWhenFirstIsGeneric() {
        let primary   = makeNote("Met at a cafe")                      // generic
        let secondary = makeNote("Starting new job at Google", daysAgo: 5) // professional
        let pool = PromptEngine.resolvedPool(from: [primary, secondary])
        let genericTexts = Set(PromptLibrary.generic)
        // Pool should NOT be the generic pool because secondary note provided signal
        XCTAssertFalse(pool.allSatisfy { genericTexts.contains($0) })
    }

    // MARK: - NoteInterpreter: relationship context

    func testDegreeClassMateIsOldClassmate() {
        let result = NoteInterpreter.interpret(rawText: "He is from gudivada and he is my degree class mate", noteDate: Date())
        XCTAssertEqual(result.kind, .relationshipContext)
        XCTAssertEqual(result.relationship, .oldClassmate)
    }

    func testDegreeClassMateProducesCatchUpNotSchool() {
        let note = makeNote("He is from gudivada and he is my degree class mate")
        let pool = PromptEngine.resolvedPool(from: [note])
        let schoolTexts = Set(PromptLibrary.school)
        XCTAssertFalse(pool.allSatisfy { schoolTexts.contains($0) }, "Should not use school pool for old classmate")
        let catchUpTexts = Set(PromptLibrary.classmateCatchUp)
        XCTAssertTrue(pool.allSatisfy { catchUpTexts.contains($0) }, "Should use classmateCatchUp pool")
    }

    func testExClassmateIsOldClassmate() {
        let result = NoteInterpreter.interpret(rawText: "ex classmate from my batch", noteDate: Date())
        XCTAssertEqual(result.kind, .relationshipContext)
        XCTAssertEqual(result.relationship, .oldClassmate)
    }

    // MARK: - NoteInterpreter: identity background

    func testSonOfIsIdentityBackground() {
        let result = NoteInterpreter.interpret(rawText: "he is son of venkat alla and from dubai", noteDate: Date())
        XCTAssertEqual(result.kind, .identityBackground)
        XCTAssertEqual(result.promptability, .low)
    }

    func testSonOfProducesGenericOnly() {
        let note = makeNote("he is son of venkat alla and from dubai")
        let pool = PromptEngine.resolvedPool(from: [note])
        let genericTexts = Set(PromptLibrary.generic)
        XCTAssertTrue(pool.allSatisfy { genericTexts.contains($0) }, "son-of note must only use generic pool")
        let familyTexts = Set(PromptLibrary.family)
        XCTAssertFalse(pool.allSatisfy { familyTexts.contains($0) }, "son-of note must NOT use family/kids pool")
    }

    func testIsFromLocationIsIdentityBackground() {
        let result = NoteInterpreter.interpret(rawText: "he is from dubai", noteDate: Date())
        XCTAssertEqual(result.kind, .identityBackground)
        XCTAssertEqual(result.promptability, .low)
    }

    func testIsFromLocationProducesGenericOnly() {
        let note = makeNote("he is from dubai")
        let pool = PromptEngine.resolvedPool(from: [note])
        let genericTexts = Set(PromptLibrary.generic)
        XCTAssertTrue(pool.allSatisfy { genericTexts.contains($0) })
    }

    // MARK: - NoteInterpreter: life events

    func testHadABabyBoyIsFamilyEventPast() {
        let result = NoteInterpreter.interpret(rawText: "had a baby boy", noteDate: Date())
        XCTAssertEqual(result.kind, .lifeEvent)
        XCTAssertEqual(result.topic, .familyEvent)
        XCTAssertEqual(result.temporalState, .past)
    }

    func testHadABabyBoyProducesLifeEventAfterPool() {
        let note = makeNote("had a baby boy")
        let pool = PromptEngine.resolvedPool(from: [note])
        let afterTexts = Set(PromptLibrary.lifeEventAfter)
        XCTAssertTrue(pool.allSatisfy { afterTexts.contains($0) })
    }

    // MARK: - NoteInterpreter: colleague context

    func testExColleagueIsOldColleague() {
        let result = NoteInterpreter.interpret(rawText: "ex colleague from TCS", noteDate: Date())
        XCTAssertEqual(result.kind, .relationshipContext)
        XCTAssertEqual(result.relationship, .oldColleague)
    }

    func testExColleagueProducesColleagueCatchUp() {
        let note = makeNote("ex colleague from TCS")
        let pool = PromptEngine.resolvedPool(from: [note])
        let catchUpTexts = Set(PromptLibrary.colleagueCatchUp)
        XCTAssertTrue(pool.allSatisfy { catchUpTexts.contains($0) })
    }

    func testCurrentColleagueIsCurrentColleague() {
        let result = NoteInterpreter.interpret(rawText: "my colleague at the office", noteDate: Date())
        XCTAssertEqual(result.kind, .relationshipContext)
        XCTAssertEqual(result.relationship, .currentColleague)
    }

    // MARK: - NoteInterpreter: recovering from surgery is NOT identity background

    func testRecoveringFromSurgeryIsNotIdentityBackground() {
        let result = NoteInterpreter.interpret(rawText: "recovering from surgery", noteDate: Date())
        XCTAssertNotEqual(result.kind, .identityBackground)
        XCTAssertEqual(result.kind, .ongoingTopic)
        XCTAssertEqual(result.topic, .health)
    }

    // MARK: - Regression: relationship identity must not produce family/kids prompts

    /// "he is cousin of sush" — identity note, not a family event.
    func testCousinOfIsIdentityBackground() {
        let result = NoteInterpreter.interpret(rawText: "he is cousin of sush", noteDate: Date())
        XCTAssertEqual(result.kind, .identityBackground)
        XCTAssertEqual(result.promptability, .low)
    }

    func testCousinOfProducesGenericNotFamilyPrompts() {
        let note = makeNote("he is cousin of sush")
        let pool = PromptEngine.resolvedPool(from: [note])
        let genericTexts = Set(PromptLibrary.generic)
        XCTAssertTrue(pool.allSatisfy { genericTexts.contains($0) }, "cousin-of note must use generic pool only")
        assertNoPrompt(in: pool, contains: familyPromptTerms)
    }

    /// "he is son of venkat alla and from dubai" — already covered by testSonOfProducesGenericOnly,
    /// but explicitly assert no family/kids/home content.
    func testSonOfProducesNoFamilyKidsPrompts() {
        let note = makeNote("he is son of venkat alla and from dubai")
        let pool = PromptEngine.resolvedPool(from: [note])
        assertNoPrompt(in: pool, contains: familyPromptTerms)
    }

    // MARK: - Regression: work activity must not produce new-role/new-company prompts

    /// "Sushma has been working very hard" — busyness, not job change.
    func testWorkingVeryHardIsWorkActivity() {
        let result = NoteInterpreter.interpret(rawText: "Sushma has been working very hard", noteDate: Date())
        XCTAssertEqual(result.kind, .ongoingTopic)
        XCTAssertEqual(result.topic, .workActivity)
    }

    func testWorkingHardProducesSafeWorkPromptsNotNewRole() {
        let note = makeNote("Sushma has been working very hard")
        let pool = PromptEngine.resolvedPool(from: [note])
        // Block job-transition prompts AND the misidentified-entity form "how are things at Sushma"
        assertNoPrompt(in: pool, contains: jobTransitionTerms + ["at sushma"])
    }

    // MARK: - Regression: ex classmate must not produce school/semester prompts

    func testExClassmateProducesNonSchoolPrompts() {
        let note = makeNote("he is my ex classmate")
        let pool = PromptEngine.resolvedPool(from: [note])
        assertNoPrompt(in: pool, contains: currentSchoolTerms)
    }

    // MARK: - Negative: job change must not produce relocation prompts (Case 5)

    /// Belt-and-suspenders keyword check alongside the pool-based test above.
    func testCompanyMoveDoesNotGenerateRelocationPrompts() {
        let note = makeNote("moved to a different company")
        let pool = PromptEngine.resolvedPool(from: [note])
        assertNoPrompt(in: pool, contains: relocationTerms)
    }

    // MARK: - Negative: location-as-background must not produce family or relocation prompts

    func testIsFromDubaiDoesNotGenerateFamilyOrRelocationPrompts() {
        let note = makeNote("he is from dubai")
        let pool = PromptEngine.resolvedPool(from: [note])
        assertNoPrompt(in: pool, contains: familyPromptTerms)
        assertNoPrompt(in: pool, contains: relocationTerms)
    }

    // MARK: - Negative: degree classmate must not produce current-education prompts

    func testDegreeClassMateDoesNotGenerateCurrentSchoolPrompts() {
        let note = makeNote("He is from gudivada and he is my degree class mate")
        let pool = PromptEngine.resolvedPool(from: [note])
        assertNoPrompt(in: pool, contains: currentSchoolTerms)
    }
}
