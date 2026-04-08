import Foundation

// MARK: - Fixture Model

/// A single golden-fixture entry encoding a realistic note and its expected prompt behavior.
///
/// Each fixture is self-contained: it carries the raw note, what prompts are acceptable,
/// and what must never appear. Adding a new entry to `PromptGoldenCorpus.all` is all
/// that is needed when a new real-world failure is discovered.
struct PromptGoldenFixture {
    /// Short identifier — appears in test failure messages so you know exactly which fixture broke.
    let name: String
    /// Raw note text as a user might actually type it — messy, compressed, real.
    let rawNote: String
    /// Terms that must NOT appear in any generated prompt (case-insensitive substring match).
    /// A failure here means a trust-breaking prompt family has leaked in.
    let disallowedTerms: [String]
    /// At least one generated prompt must contain at least one of these terms.
    /// `nil` = no positive direction required; disallowed-only check is sufficient.
    let requiredDirection: [String]?
    /// Which recurring bug class this fixture guards against, and why it matters.
    let rationale: String
}

// MARK: - Corpus

/// Curated golden-fixture corpus of real-world note patterns.
///
/// Organisation:
///   A — Relationship identity / old classmate
///   B — Background / identity-only
///   C — Work activity vs work transition
///   D — Relocation / travel / life event
///   E — Weak / vague signal
///
/// To extend: append a new `PromptGoldenFixture` to `all`.
/// Run the suite after any prompt-engine change to validate real-world quality.
enum PromptGoldenCorpus {

    static let all: [PromptGoldenFixture] = [

        // ── A. Relationship identity / old classmate ──────────────────────────────

        PromptGoldenFixture(
            name: "A1_degree_classmate_from_gudivada",
            rawNote: "He is from gudivada and he is my degree class mate",
            disallowedTerms: ["classes", "semester", "exam", "coursework", "courses"],
            requiredDirection: ["up to", "been", "life", "working on"],
            rationale: """
            Bug class: classmate mistaken for current education.
            "degree class mate" signals an old college connection, not an active student.
            Must produce catch-up prompts ("what have you been up to"), not school prompts
            ("how are classes going").
            """
        ),

        PromptGoldenFixture(
            name: "A2_ex_classmate_typo",
            rawNote: "he is from gudivada and he is my ex classsmate",
            disallowedTerms: ["classes", "semester", "exam", "coursework", "courses"],
            requiredDirection: nil,
            rationale: """
            Bug class: classmate mistaken for current education (typo variant).
            "ex classsmate" (3 s's) won't match the pattern — engine falls to generic.
            Generic output is acceptable; school prompts are never acceptable.
            Ensures typo-ridden notes degrade gracefully to generic rather than misfiring.
            """
        ),

        PromptGoldenFixture(
            name: "A3_ex_classmate_clean",
            rawNote: "he is my ex classmate",
            disallowedTerms: ["classes", "semester", "exam", "coursework", "courses"],
            requiredDirection: ["up to", "been", "lately"],
            rationale: """
            Bug class: classmate mistaken for current education.
            Clean "ex classmate" phrase must route to catch-up pool, not school pool.
            Protects against the fix regressing under future PromptLibrary or routing changes.
            """
        ),

        // ── B. Background / identity-only ─────────────────────────────────────────

        PromptGoldenFixture(
            name: "B4_is_from_dubai",
            rawNote: "he is from Dubai",
            disallowedTerms: [
                "family", "kids", "children", "wife", "husband",
                "new place", "packing", "new city",
                "trip", "travel", "flight",
            ],
            requiredDirection: ["there", "things", "new", "what's", "dubai"],
            rationale: """
            Location-background note with a named entity (Dubai).
            Must produce contextual-soft location-anchor prompts ("How have things been in Dubai?",
            "How's life been there lately?") — not travel, relocation, or family prompts.
            Previously fell back to generic; now expected to produce note-connected output.
            """
        ),

        PromptGoldenFixture(
            name: "B5_son_of_with_location",
            rawNote: "he is son of venkat alla and from dubai",
            disallowedTerms: [
                "family", "kids", "children", "wife", "husband", "everyone at home",
            ],
            requiredDirection: ["there", "things", "new", "what's"],
            rationale: """
            "son of X" is an identity note — not a conversation hook about family/kids.
            The "from Dubai" part provides a location entity, so the engine should produce
            contextual-soft location-anchor prompts rather than generic or family prompts.
            Family/kids/household prompts must never appear.
            """
        ),

        PromptGoldenFixture(
            name: "B6_cousin_of",
            rawNote: "he is cousin of sush",
            disallowedTerms: [
                "family", "kids", "children", "everyone at home", "wife", "husband", "spouse",
            ],
            requiredDirection: ["things", "new", "up to", "lately", "going"],
            rationale: """
            "cousin of sush" is a memory note — no family/household prompts allowed.
            No entity extracted (lowercase "sush"), so the engine uses the sharedConnectionAnchor
            handle and produces soft catch-up prompts.
            Previously fell back to generic; now expected to produce contextual-soft output.
            """
        ),

        // ── C. Work activity vs work transition ────────────────────────────────────

        PromptGoldenFixture(
            name: "C7_working_very_hard",
            rawNote: "Sushma has been working very hard",
            disallowedTerms: [
                "new role", "new company", "settling in", "onboarding",
                "new job", "new position", "at sushma",
            ],
            requiredDirection: ["work", "busy", "things", "how have"],
            rationale: """
            Bug class: work activity mistaken for job transition.
            "working very hard" signals busyness — not a new role or company change.
            Two failure modes guarded:
            1. "new role / settling in" prompts imply a transition that does not exist.
            2. "at Sushma" treats the subject's name as an organisation/entity.
            Must produce safe, effort-neutral prompts.
            """
        ),

        PromptGoldenFixture(
            name: "C8_started_at_google",
            rawNote: "started at Google",
            disallowedTerms: ["new place", "packing", "new city", "new home"],
            requiredDirection: ["work", "role", "job", "google"],
            rationale: """
            Positive fixture: genuine job change must produce professional prompts.
            Guards the other side of the C7 fix — job-change evidence must still route
            to the professional pool, not leak into relocation prompts.
            """
        ),

        PromptGoldenFixture(
            name: "C9_moved_to_different_company",
            rawNote: "moved to a different company",
            disallowedTerms: ["new place", "packing", "new city", "new home"],
            requiredDirection: ["work", "role", "job"],
            rationale: """
            Bug class: job/company change mistaken for physical relocation.
            "moved to a different company" is a career move, not a house move.
            Relocation prompts ("new place", "packing") must never appear.
            Professional prompts are the correct output.
            """
        ),

        // ── D. Relocation / travel / life event ───────────────────────────────────

        PromptGoldenFixture(
            name: "D10_moving_to_nyc_next_week",
            rawNote: "moving to NYC next week",
            disallowedTerms: [
                "new role", "new company", "onboarding", "new job", "new position",
            ],
            requiredDirection: ["move", "place", "set", "when", "packing"],
            rationale: """
            Positive fixture: physical relocation with a future temporal signal.
            Must produce move-before prompts ("when are you moving?", "all set for the move?").
            Job-transition prompts must not appear — "NYC" is a city, not a company.
            """
        ),

        PromptGoldenFixture(
            name: "D11_planning_trip_london",
            rawNote: "planning trip to London next month",
            disallowedTerms: [
                "new role", "new company", "family", "kids",
            ],
            requiredDirection: ["trip", "travel", "london", "leave", "excited"],
            rationale: """
            Positive fixture: travel with a future temporal signal.
            Must produce travel-before prompts. No job or family prompts.
            "London" should appear in the output as the entity (trip planning is specific).
            """
        ),

        PromptGoldenFixture(
            name: "D12_had_a_baby_boy",
            rawNote: "had a baby boy",
            disallowedTerms: ["new role", "classes", "semester", "new place"],
            requiredDirection: ["how did", "since", "big day", "everyone"],
            rationale: """
            Positive fixture: past-tense life event (baby born).
            "had a" is a past indicator — must route to life-event-after prompts
            ("How did it go?", "How have things been since then?").
            Must not leak job, school, or relocation prompts.
            """
        ),

        PromptGoldenFixture(
            name: "D13_daughters_wedding",
            rawNote: "daughter's wedding next month",
            disallowedTerms: ["new role", "classes", "semester"],
            requiredDirection: ["preparations", "excited", "big day", "ready", "coming"],
            rationale: """
            Positive fixture: future life event.
            "wedding next month" is a fresh future signal — must produce life-event-before
            prompts ("are you excited?", "how are the preparations?").
            """
        ),

        // ── F. Contextual-soft: new failing examples now fixed ────────────────────

        PromptGoldenFixture(
            name: "F16_my_cousin",
            rawNote: "he is my cousin",
            disallowedTerms: [
                "family", "kids", "children", "everyone at home", "wife", "husband",
                "how's the family", "how are the kids",
            ],
            requiredDirection: ["things", "new", "up to", "lately", "side"],
            rationale: """
            "my cousin" is a direct family-relation note.
            Must produce familyRelationSoft prompts ("How have things been with you lately?",
            "What's new with you these days?") — NOT family/kids/home prompts.
            Previously produced generic; now expected to produce contextual-soft output.
            """
        ),

        PromptGoldenFixture(
            name: "F17_got_operated",
            rawNote: "he got operated lately",
            disallowedTerms: [
                "family", "kids", "new role", "new company", "new place",
            ],
            requiredDirection: ["feeling", "recovery", "doing", "better", "holding"],
            rationale: """
            "got operated" signals a recent medical procedure.
            Must produce recovery check-in prompts ("How are you feeling now?",
            "How has recovery been going?") — not generic.
            Previously fell to weakSignal and generic; now routes through ongoingTopic/health.
            """
        ),

        PromptGoldenFixture(
            name: "F18_property_support",
            rawNote: "he is from bangalore. He looks after my place in bangalore property",
            disallowedTerms: [
                "family", "kids", "new role", "new company", "trip", "travel",
            ],
            requiredDirection: ["front", "place", "there", "holding", "side"],
            rationale: """
            "looks after my place" + "property" signals a property-support role.
            Must produce propertySupportCheckin prompts ("How have things been going on that front?",
            "How's everything going with the place there?") — not generic.
            Property support detection fires before "is from" identity-background swallows the note.
            """
        ),

        // ── E. Weak / vague signal ────────────────────────────────────────────────

        PromptGoldenFixture(
            name: "E14_met_at_cafe",
            rawNote: "met at cafe",
            disallowedTerms: [
                "new role", "new company", "family", "kids", "classes", "semester", "new place",
            ],
            requiredDirection: nil,
            rationale: """
            Weak signal: minimal context, no topic or relationship hook.
            Generic prompts are the correct and safe output.
            Guards against over-inference — no topic prompt should be generated from thin air.
            """
        ),

        PromptGoldenFixture(
            name: "E15_nice_guy",
            rawNote: "nice guy",
            disallowedTerms: [
                "new role", "new company", "family", "kids", "classes", "new place",
            ],
            requiredDirection: nil,
            rationale: """
            Weak signal: pure sentiment, zero topical content.
            Generic prompts are the only acceptable output.
            Protects against vague notes activating any specific prompt family.
            """
        ),
    ]
}
