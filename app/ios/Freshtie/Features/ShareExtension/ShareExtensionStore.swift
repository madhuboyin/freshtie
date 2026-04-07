import Foundation

/// Lightweight payload handed off from Share Extension to Main App.
struct SharedPersonPayload: Codable, Identifiable {
    let id: UUID
    let displayName: String
    let contactIdentifier: String?
    let noteText: String?
    let timestamp: Date

    init(displayName: String, contactIdentifier: String? = nil, noteText: String? = nil) {
        self.id = UUID()
        self.displayName = displayName
        self.contactIdentifier = contactIdentifier
        self.noteText = noteText
        self.timestamp = Date()
    }
}

/// Shared persistence between Extension and Main App via App Group.
enum ShareExtensionStore {
    private static let appGroupId = "group.com.madhuboyin.Freshtie"
    private static let payloadKey = "pending_shared_people"

    private static var sharedDefaults: UserDefaults? {
        guard let defaults = UserDefaults(suiteName: appGroupId) else {
            print("🔄 SHARE EXT: Failed to create UserDefaults with suite name: \(appGroupId)")
            return nil
        }
        return defaults
    }

    /// Appends a new shared person payload.
    static func savePayload(_ payload: SharedPersonPayload) {
        guard let defaults = sharedDefaults else {
            print("🔄 SHARE EXT: Cannot access shared UserDefaults")
            return
        }
        
        var current = fetchAll()
        current.append(payload)
        
        do {
            let data = try JSONEncoder().encode(current)
            defaults.set(data, forKey: payloadKey)
            defaults.synchronize() // Force synchronization
            print("🔄 SHARE EXT: Payload saved to UserDefaults successfully")
        } catch {
            print("🔄 SHARE EXT: Failed to encode payload: \(error)")
        }
    }

    /// Fetches all pending payloads.
    static func fetchAll() -> [SharedPersonPayload] {
        guard let data = sharedDefaults?.data(forKey: payloadKey),
              let payloads = try? JSONDecoder().decode([SharedPersonPayload].self, from: data) else {
            return []
        }
        return payloads
    }

    /// Clears all pending payloads after they've been ingested.
    static func clearAll() {
        sharedDefaults?.removeObject(forKey: payloadKey)
    }
}
