import Foundation

/// Timing thresholds and message variants for contact triggers.
enum TriggerTimingState: Equatable {
    case fresh   // 0–15 mins
    case warm    // 15m – 6h
    case stale   // 6h – 48h
    case expired // > 48h (suppressed)

    /// Returns the state based on time difference from current.
    static func state(for date: Date) -> Self {
        let diff = abs(date.timeIntervalSinceNow)
        
        switch diff {
        case 0 ..< (15 * 60):           return .fresh
        case (15 * 60) ..< (6 * 3600):  return .warm
        case (6 * 3600) ..< (48 * 3600): return .stale
        default:                         return .expired
        }
    }

    /// Primary call-to-action message for the trigger.
    func message(for name: String) -> String {
        switch self {
        case .fresh:
            return "You just met \(name) — add one thing before you forget."
        case .warm:
            return "You recently met \(name) — add something while it’s fresh."
        case .stale:
            return "You added \(name) yesterday — anything you remember?"
        case .expired:
            return ""
        }
    }
}
