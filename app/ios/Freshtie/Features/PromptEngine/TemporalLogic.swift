import Foundation

/// Determines whether a note's referenced event is future or past
/// using deterministic date arithmetic — no ML, no ambiguity.
///
/// Strategy:
///   1. Scan note text for future indicator phrases.
///   2. Estimate the event date by adding an offset to the note's `createdAt`.
///   3. Compare the estimated event date to `now`.
///   4. When no indicator is found, return `.unknown`.
enum TemporalLogic {

    /// Visible for testing.
    static func state(for text: String, noteDate: Date, now: Date = Date()) -> TemporalState {
        let lower = text.lowercased()
        guard let offset = bestOffset(in: lower, from: noteDate) else { return .unknown }
        let estimatedEventDate = Calendar.current.date(byAdding: .day, value: offset, to: noteDate)
                               ?? noteDate
        return estimatedEventDate < now ? .past : .future
    }

    // MARK: - Private

    /// Returns the best day-offset estimate for the event described in `text`, or nil.
    private static func bestOffset(in text: String, from noteDate: Date) -> Int? {
        // Named weekdays — compute actual days ahead from noteDate
        let weekdays: [(phrase: String, weekday: Int)] = [
            ("monday", 2), ("tuesday", 3), ("wednesday", 4), ("thursday", 5),
            ("friday",  6), ("saturday", 7), ("sunday",   1),
        ]
        // Check "next <weekday>" first (more explicit), then bare weekday
        for (phrase, targetWeekday) in weekdays {
            if text.contains("next \(phrase)") || text.contains(phrase) {
                return daysUntilWeekday(targetWeekday, from: noteDate)
            }
        }

        // Fixed-phrase offsets — longer strings checked before any that are substrings of them
        let fixed: [(String, Int)] = [
            ("next year",    365),
            ("next month",    30),
            ("next week",      7),
            ("this weekend",   4),
            ("tomorrow",       1),
            ("upcoming",      21),
            ("soon",          14),
        ]
        for (phrase, offset) in fixed {
            if text.contains(phrase) { return offset }
        }

        return nil
    }

    /// Days from `date` to the next occurrence of `weekday` (1 = Sunday … 7 = Saturday).
    /// Returns 7 if `date` falls on that weekday (interpret as "next week's <day>").
    private static func daysUntilWeekday(_ weekday: Int, from date: Date) -> Int {
        let cal = Calendar.current
        let current = cal.component(.weekday, from: date)
        let ahead = (weekday - current + 7) % 7
        return ahead == 0 ? 7 : ahead
    }
}
