import Foundation

/// Local deterministic prompt engine.
///
/// Full pipeline per call (typically < 1 ms):
///   sortedNotes → NoteInterpreter → PromptMapper (for structured signals)
///   OR → KeywordExtractor → PromptCategorizer → TemporalLogic → PromptLibrary (weak signal fallback)
///
/// All methods are pure, synchronous, and safe to call on the main thread.
enum PromptEngine {

    static let promptCount = 3

    // MARK: - Public API

    /// Generates `promptCount` prompts for the given person and their sorted notes.
    static func prompts(for person: Person, sortedNotes: [Note]) -> [Prompt] {
        let pool = resolvedPool(from: sortedNotes)
        return pick(count: promptCount, from: pool, excluding: [])
    }

    /// Returns fresh prompts, avoiding the currently displayed set.
    /// If all pool entries have been shown, cycles back to the beginning.
    static func refreshedPrompts(
        for person: Person,
        sortedNotes: [Note],
        excluding current: [Prompt]
    ) -> [Prompt] {
        let pool = resolvedPool(from: sortedNotes)
        let shown = Set(current.map(\.text))
        let fresh = pool.filter { !shown.contains($0) }

        if fresh.count >= promptCount {
            return pick(count: promptCount, from: fresh, excluding: [])
        }
        // Full cycle — show anything from pool (including previously seen)
        return pick(count: promptCount, from: pool, excluding: shown)
    }

    // MARK: - Pipeline

    /// Visible for testing.
    static func resolvedPool(from sortedNotes: [Note]) -> [String] {
        guard let primary = sortedNotes.first else {
            return PromptLibrary.generic
        }

        // NoteInterpreter runs first — it catches relationship context, identity background,
        // and life events that keyword matching misclassifies.
        let interpreted = NoteInterpreter.interpret(primary)
        if interpreted.kind != .weakSignal {
            let raw = PromptMapper.pool(for: interpreted)
            if raw.isEmpty { return PromptLibrary.generic }
            // Apply entity substitution so {entity} tokens never reach the UI.
            let resolved = PromptTemplateLibrary.resolved(pool: raw, entity: interpreted.topEntity)
            return resolved.isEmpty ? PromptLibrary.generic : resolved
        }

        // Fallback: existing keyword pipeline for notes with no structured signal.
        let signals  = KeywordExtractor.extract(from: primary.rawText)
        let category = PromptCategorizer.categorize(signals: signals, rawText: primary.rawText)
        let temporal = TemporalLogic.state(for: primary.rawText, noteDate: primary.createdAt)
        let confidence = ConfidenceScorer.score(signals: signals, category: category, temporal: temporal, rawText: primary.rawText)

        // If the primary note gives no signal or low confidence, peek at the second note
        if confidence == .low, let secondary = sortedNotes.dropFirst().first {
            let secInterpreted = NoteInterpreter.interpret(secondary)
            if secInterpreted.kind != .weakSignal {
                let raw = PromptMapper.pool(for: secInterpreted)
                if !raw.isEmpty {
                    let resolved = PromptTemplateLibrary.resolved(pool: raw, entity: secInterpreted.topEntity)
                    if !resolved.isEmpty { return resolved }
                }
            }

            let sec  = KeywordExtractor.extract(from: secondary.rawText)
            let cat2 = PromptCategorizer.categorize(signals: sec, rawText: secondary.rawText)
            let state2 = TemporalLogic.state(for: secondary.rawText, noteDate: secondary.createdAt)
            let conf2 = ConfidenceScorer.score(signals: sec, category: cat2, temporal: state2, rawText: secondary.rawText)

            if conf2 > .low {
                return resolvedTemplates(category: cat2, state: state2, confidence: conf2, entity: sec.topEntity)
            }
        }

        return resolvedTemplates(category: category, state: temporal, confidence: confidence, entity: signals.topEntity)
    }

    private static func resolvedTemplates(
        category: PromptCategory,
        state: TemporalState,
        confidence: ConfidenceLevel,
        entity: String?
    ) -> [String] {
        let raw = PromptLibrary.pool(for: category, state: state, confidence: confidence)
        let resolved = PromptTemplateLibrary.resolved(pool: raw, entity: entity)
        return resolved.isEmpty ? PromptLibrary.generic : resolved
    }

    // MARK: - Selection

    /// Picks `count` strings from `pool`, skipping `excluded`.
    /// Falls back to the full pool (cycling) if not enough remain.
    private static func pick(count: Int, from pool: [String], excluding excluded: Set<String>) -> [Prompt] {
        let candidates = pool.filter { !excluded.contains($0) }
        // Supplement with excluded entries if we can't fill the count from fresh ones.
        let source: [String]
        if candidates.count >= count {
            source = candidates
        } else {
            source = candidates + pool.filter { excluded.contains($0) }
        }
        return Array(source.prefix(count)).map { Prompt(text: $0) }
    }
}
