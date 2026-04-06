import Foundation

/// Primary entry point for local-first behavioral tracking.
/// Usage: `AnalyticsService.shared.track(.person_selected, metadata: ["id": "123"])`
final class AnalyticsService {
    static let shared = AnalyticsService()
    
    /// Records an event to local storage.
    @MainActor
    func track(_ name: AnalyticsEventName, metadata: [String: String]? = nil) {
        let event = AnalyticsEvent(name: name, metadata: metadata)
        AnalyticsEventStore.shared.log(event)
    }
}
