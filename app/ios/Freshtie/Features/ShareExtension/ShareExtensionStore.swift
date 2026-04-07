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
    private static let payloadFileName = "pending_shared_people.json"

    private static var sharedDirectory: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupId)
    }
    
    private static var payloadFileURL: URL? {
        guard let directory = sharedDirectory else { return nil }
        return directory.appendingPathComponent(payloadFileName)
    }

    /// Appends a new shared person payload.
    static func savePayload(_ payload: SharedPersonPayload) {
        guard let fileURL = payloadFileURL else {
            return
        }
        
        var current = fetchAll()
        current.append(payload)
        
        do {
            let data = try JSONEncoder().encode(current)
            try data.write(to: fileURL)
        } catch {
            print("🔄 SHARE EXT: Failed to save payload: \(error)")
        }
    }

    /// Fetches all pending payloads.
    static func fetchAll() -> [SharedPersonPayload] {
        guard let fileURL = payloadFileURL else { return [] }
        
        do {
            let data = try Data(contentsOf: fileURL)
            let payloads = try JSONDecoder().decode([SharedPersonPayload].self, from: data)
            return payloads
        } catch {
            return []
        }
    }

    /// Clears all pending payloads after they've been ingested.
    static func clearAll() {
        guard let fileURL = payloadFileURL else { return }
        
        do {
            try FileManager.default.removeItem(at: fileURL)
        } catch {
            print("🔄 SHARE EXT: Failed to clear payloads: \(error)")
        }
    }
}
