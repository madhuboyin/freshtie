import Foundation

/// Extracts lightweight signals from raw note text.
/// No NLP — vocabulary matching and regex only.
enum KeywordExtractor {

    // MARK: - Public

    static func extract(from text: String) -> TextSignals {
        let lower = text.lowercased()
        let rawWords = lower.components(separatedBy: .whitespacesAndNewlines)
        let tokens = Set(rawWords.filter { !$0.isEmpty && !stopWords.contains($0) })
        let entity  = extractTopEntity(from: text)
        return TextSignals(tokens: tokens, topEntity: entity)
    }

    // MARK: - Entity extraction

    /// Finds the first capitalized word (or two-word sequence) after a preposition.
    /// e.g. "Starting at Google" → "Google", "Moving to San Francisco" → "San Francisco"
    static func extractTopEntity(from text: String) -> String? {
        // Pattern: preposition then 1–2 title-case words
        let pattern = #"\b(?:at|to|in|for|from)\s+([A-Z][a-zA-Z]+(?:\s+[A-Z][a-zA-Z]+)?)"#
        if let regex  = try? NSRegularExpression(pattern: pattern),
           let match  = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
           let range  = Range(match.range(at: 1), in: text) {
            return String(text[range])
        }

        // Fallback: any non-initial capitalized word (likely a proper noun)
        let words = text.components(separatedBy: .whitespaces)
        for (i, word) in words.enumerated() {
            guard i > 0 else { continue }
            let clean = word.trimmingCharacters(in: .punctuationCharacters)
            if let first = clean.first, first.isUppercase, clean.count > 1 {
                return clean
            }
        }
        return nil
    }

    // MARK: - Stop words

    private static let stopWords: Set<String> = [
        "the","a","an","and","or","but","in","on","at","to","for","of","with",
        "by","from","up","about","into","through","during","is","are","was",
        "were","be","been","being","have","has","had","do","does","did","will",
        "would","could","should","may","might","it","its","he","she","they",
        "we","i","me","my","our","you","your","his","her","their","this",
        "that","these","those","just","really","very","so","also","too",
        "got","get","went","going","go","started","start","some","any",
        "new","next","last","first","same","other","more","all","no","not",
    ]
}
