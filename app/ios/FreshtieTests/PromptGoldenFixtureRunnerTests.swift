import XCTest
@testable import Freshtie

/// Fixture-driven regression suite for the Freshtie prompt engine.
///
/// Runs every entry in `PromptGoldenCorpus.all` through the live pipeline and validates
/// both what must NOT appear (disallowed term families) and what SHOULD appear (required
/// direction keywords).
///
/// Three test layers in the overall suite:
///   1. Unit tests (classification, temporal, confidence) — PromptEngineTests.swift
///   2. Negative-assertion regression tests              — PromptEngineTests.swift
///   3. Golden real-world corpus tests                   — THIS FILE
///
/// To add a new case: append a `PromptGoldenFixture` to `PromptGoldenCorpus.all`.
/// No changes to this file are needed.
final class PromptGoldenFixtureRunnerTests: XCTestCase {

    // MARK: - Helpers

    private func pool(for rawNote: String) -> [String] {
        let note = Note(rawText: rawNote)
        note.createdAt = Date()
        return PromptEngine.resolvedPool(from: [note])
    }

    // MARK: - Disallowed term check

    /// For every fixture, asserts that no generated prompt contains any disallowed term.
    /// Failure message names the fixture, the note text, the offending prompt, and the term.
    func testGoldenCorpusDisallowedTerms() {
        for fixture in PromptGoldenCorpus.all {
            let prompts = pool(for: fixture.rawNote)
            for prompt in prompts {
                let lower = prompt.lowercased()
                for term in fixture.disallowedTerms {
                    XCTAssertFalse(
                        lower.contains(term),
                        """
                        [\(fixture.name)] Trust regression detected.
                        Note:     '\(fixture.rawNote)'
                        Prompt:   '\(prompt)'
                        Disallowed term: '\(term)'
                        Rationale: \(fixture.rationale)
                        """
                    )
                }
            }
        }
    }

    // MARK: - Required direction check

    /// For fixtures with a required direction, asserts that the combined prompt output
    /// contains at least one expected direction keyword.
    func testGoldenCorpusRequiredDirection() {
        for fixture in PromptGoldenCorpus.all {
            guard let required = fixture.requiredDirection else { continue }
            let prompts = pool(for: fixture.rawNote)
            let allText = prompts.map { $0.lowercased() }.joined(separator: " ")
            let satisfied = required.contains(where: { allText.contains($0) })
            XCTAssertTrue(
                satisfied,
                """
                [\(fixture.name)] Expected direction not met.
                Note:              '\(fixture.rawNote)'
                Required keywords: \(required)
                Generated prompts: \(prompts)
                Rationale: \(fixture.rationale)
                """
            )
        }
    }

    // MARK: - Sanity checks

    /// Every fixture must produce exactly 3 prompts — no crashes or empty pools.
    func testGoldenCorpusAlwaysProducesThreePrompts() {
        let person = Person(displayName: "Test")
        for fixture in PromptGoldenCorpus.all {
            let note = Note(rawText: fixture.rawNote)
            note.createdAt = Date()
            let prompts = PromptEngine.prompts(for: person, sortedNotes: [note])
            XCTAssertEqual(
                prompts.count, 3,
                "[\(fixture.name)] Expected 3 prompts for '\(fixture.rawNote)', got \(prompts.count)"
            )
        }
    }

    /// No fixture may produce a raw `{entity}` token — substitution must always resolve.
    func testGoldenCorpusNoRawEntityToken() {
        for fixture in PromptGoldenCorpus.all {
            let prompts = pool(for: fixture.rawNote)
            for prompt in prompts {
                XCTAssertFalse(
                    prompt.contains("{entity}"),
                    "[\(fixture.name)] Raw entity token leaked: '\(prompt)' (note: '\(fixture.rawNote)')"
                )
            }
        }
    }

    /// No fixture may produce an empty prompt string.
    func testGoldenCorpusNoEmptyPrompts() {
        for fixture in PromptGoldenCorpus.all {
            let prompts = pool(for: fixture.rawNote)
            for prompt in prompts {
                XCTAssertFalse(
                    prompt.isEmpty,
                    "[\(fixture.name)] Empty prompt generated for '\(fixture.rawNote)'"
                )
            }
        }
    }
}
