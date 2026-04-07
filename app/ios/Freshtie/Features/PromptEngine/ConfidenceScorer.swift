import Foundation

/// Heuristic-based scorer to determine classification confidence.
/// Determines if we should use intent-specific prompts or safe fallbacks.
enum ConfidenceScorer {

    /// Calculates a confidence score based on keyword strength, length, and signal alignment.
    static func score(signals: TextSignals, category: PromptCategory, temporal: TemporalState, rawText: String) -> ConfidenceLevel {
        // 1. Generic category is always low confidence
        guard category != .generic else { return .low }

        var score = 0

        // 2. Intent Keyword strength (Positive signal)
        // More tokens usually means more specific context
        let tokenCount = signals.tokens.count
        if tokenCount >= 2 { score += 2 }
        else if tokenCount == 1 { score += 1 }

        // 3. Named Entity presence (Positive signal)
        // If we found a proper noun (e.g., "Google", "NYC"), confidence increases
        if signals.topEntity != nil {
            score += 2
        }

        // 4. Temporal Clarity (Positive signal)
        // Future or Past signals provide better context than Unknown
        if temporal != .unknown {
            score += 1
        }

        // 5. Raw text length (Heuristic signal)
        // Very short notes (e.g., "job") are lower confidence than "Started new job at Google"
        let wordCount = rawText.components(separatedBy: .whitespaces).count
        if wordCount < 3 {
            score -= 2
        } else if wordCount > 5 {
            score += 1
        }

        // 6. Final Thresholding
        // Lowered thresholds to be less aggressive with generic fallbacks
        if score >= 3 {
            return .high
        } else if score >= 1 {
            return .medium
        } else {
            return .low
        }
    }
}
