import Foundation

/// Category a note maps to — drives which template pool is used.
enum PromptCategory: Equatable {
    case professional   // job, work, career
    case travel         // trip, vacation, flight
    case move           // moving, relocating
    case family         // family members
    case lifeEvent      // wedding, baby, graduation, funeral
    case school         // exams, studying, degree
    case health         // surgery, recovery, illness
    case generic        // no strong signal — use fallback pool
}

/// Whether a note's referenced event is still upcoming or has already passed.
enum TemporalState: Equatable {
    case future         // event has not yet occurred
    case past           // event has likely already occurred
    case unknown        // no temporal signal detected
}

/// Lightweight signals extracted from raw note text.
struct TextSignals {
    let tokens: Set<String>     // significant lowercased words (stop words removed)
    let topEntity: String?      // best candidate for named-entity substitution
}
