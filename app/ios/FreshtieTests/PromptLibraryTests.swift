import XCTest
@testable import Freshtie

final class PromptLibraryTests: XCTestCase {

    func testGenericPoolReturnsUsagePrompts() {
        let pool = PromptLibrary.pool(for: .generic, state: .unknown, confidence: .low)
        XCTAssertTrue(pool.count >= 4)
        XCTAssertTrue(pool.contains("How have things been going?"))
    }

    func testLowConfidenceAlwaysFallsBackToGeneric() {
        let intents: [PromptCategory] = [.professional, .travel, .move, .family, .lifeEvent, .school, .health]
        for intent in intents {
            let pool = PromptLibrary.pool(for: intent, state: .future, confidence: .low)
            XCTAssertEqual(pool, PromptLibrary.generic)
        }
    }

    func testMediumConfidenceUsesSafeIntentPrompts() {
        let pool = PromptLibrary.pool(for: .professional, state: .future, confidence: .medium)
        XCTAssertTrue(pool.contains("How's work going?"))
        XCTAssertFalse(pool.contains("How are things at {entity}?"))
    }

    func testHighConfidenceUsesSpecificIntentAndTemporalPrompts() {
        // Professional (no temporal variants in high confidence pool, just the pool)
        let profPool = PromptLibrary.pool(for: .professional, state: .unknown, confidence: .high)
        XCTAssertTrue(profPool.contains("How are things at {entity}?"))

        // Travel Future
        let travelFuture = PromptLibrary.pool(for: .travel, state: .future, confidence: .high)
        XCTAssertTrue(travelFuture.contains("When do you leave?"))

        // Travel Past
        let travelPast = PromptLibrary.pool(for: .travel, state: .past, confidence: .high)
        XCTAssertTrue(travelPast.contains("How did the travel go?"))
    }

    func testAllHighConfidencePoolsHaveSufficientVariants() {
        let intents: [PromptCategory] = [.professional, .travel, .move, .family, .lifeEvent, .school, .health]
        for intent in intents {
            let pool = PromptLibrary.pool(for: intent, state: .future, confidence: .high)
            XCTAssertTrue(pool.count >= 3, "Pool for \(intent) should have at least 3 variants")
        }
    }
}
