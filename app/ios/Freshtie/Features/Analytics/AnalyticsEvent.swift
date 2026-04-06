import Foundation
import SwiftData

/// All MVP-critical event names for product validation.
enum AnalyticsEventName: String, Codable {
    // Core Value
    case app_opened
    case person_selected
    case prompt_viewed
    case prompt_refreshed

    // Capture Behavior
    case note_added
    case capture_started

    // Trigger System
    case contact_trigger_shown
    case contact_trigger_accepted
    case contact_trigger_dismissed

    // Entry Paths
    case share_extension_used
    case manual_person_added
    case contact_person_selected

    // Permissions
    case contacts_permission_requested
    case contacts_permission_granted
    case microphone_permission_requested
    case microphone_permission_granted

    // Retention
    case session_started
    case session_ended
}

/// Lightweight analytics event record stored locally in SwiftData.
@Model
final class AnalyticsEvent {
    @Attribute(.unique) var id: UUID
    var eventName: String
    var timestamp: Date
    
    /// Metadata stored as a JSON string for flexibility.
    var metadataJSON: String?

    init(name: AnalyticsEventName, timestamp: Date = Date(), metadata: [String: String]? = nil) {
        self.id = UUID()
        self.eventName = name.rawValue
        self.timestamp = timestamp
        
        if let metadata = metadata,
           let data = try? JSONEncoder().encode(metadata) {
            self.metadataJSON = String(data: data, encoding: .utf8)
        }
    }
    
    /// Convenience accessor for decoding metadata back into a dictionary.
    var metadata: [String: String]? {
        guard let json = metadataJSON,
              let data = json.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode([String: String].self, from: data)
    }
}
