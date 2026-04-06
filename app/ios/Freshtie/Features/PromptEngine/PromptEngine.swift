import Foundation

/// Local deterministic prompt engine.
///
/// Full pipeline per call (typically < 1 ms):
///   sortedNotes → KeywordExtractor → PromptCategorizer → TemporalLogic
///   → PromptTemplateLibrary.pool → entity substitution → pick 2
///
/// All methods are pure, synchronous, and safe to call on the main thread.
enum PromptEngine {

    static let promptCount = 2

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
            return PromptTemplateLibrary.generic
        }

        let signals  = KeywordExtractor.extract(from: primary.rawText)
        let category = PromptCategorizer.categorize(signals: signals)
        let state    = TemporalLogic.state(for: primary.rawText, noteDate: primary.createdAt)

        // If the primary note gives no signal, peek at the second note before falling back.
        if category == .generic, let secondary = sortedNotes.dropFirst().first {
            let sec  = KeywordExtractor.extract(from: secondary.rawText)
            let cat2 = PromptCategorizer.categorize(signals: sec)
            if cat2 != .generic {
                let state2 = TemporalLogic.state(for: secondary.rawText, noteDate: secondary.createdAt)
                return resolvedTemplates(category: cat2, state: state2, entity: sec.topEntity)
            }
        }

        return resolvedTemplates(category: category, state: state, entity: signals.topEntity)
    }

    private static func resolvedTemplates(
        category: PromptCategory,
        state: TemporalState,
        entity: String?
    ) -> [String] {
        let raw = PromptTemplateLibrary.pool(for: category, state: state)
        let resolved = PromptTemplateLibrary.resolved(pool: raw, entity: entity)
        return resolved.isEmpty ? PromptTemplateLibrary.generic : resolved
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
