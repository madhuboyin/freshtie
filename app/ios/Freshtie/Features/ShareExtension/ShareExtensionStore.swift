import Foundation

/// Lightweight payload handed off from Share Extension to Main App.
struct SharedPersonPayload: Codable, Identifiable {
    let id: UUID
    let displayName: String
    let contactIdentifier: String?
    let noteText: String?
    let audioFileName: String? // File name for recorded audio in App Group
    let timestamp: Date

    init(displayName: String, contactIdentifier: String? = nil, noteText: String? = nil, audioFileName: String? = nil) {
        self.id = UUID()
        self.displayName = displayName
        self.contactIdentifier = contactIdentifier
        self.noteText = noteText
        self.audioFileName = audioFileName
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
            print("🔄 SHARE EXT: Cannot access shared directory")
            return
        }
        
        var current = fetchAll()
        current.append(payload)
        
        do {
            let data = try JSONEncoder().encode(current)
            try data.write(to: fileURL)
            print("🔄 SHARE EXT: Payload saved to file successfully")
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
            // File might not exist yet, which is normal
            if (error as NSError).code != NSFileReadNoSuchFileError {
                print("🔄 SHARE EXT: Failed to read payloads: \(error)")
            }
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
    
    /// Saves audio data to the shared directory and returns the filename
    static func saveAudioData(_ data: Data) -> String? {
        guard let directory = sharedDirectory else { return nil }
        
        let fileName = "audio_\(UUID().uuidString).m4a"
        let fileURL = directory.appendingPathComponent(fileName)
        
        do {
            try data.write(to: fileURL)
            print("🔄 SHARE EXT: Audio saved to \(fileName)")
            return fileName
        } catch {
            print("🔄 SHARE EXT: Failed to save audio: \(error)")
            return nil
        }
    }
    
    /// Retrieves audio data from the shared directory
    static func getAudioData(fileName: String) -> Data? {
        guard let directory = sharedDirectory else { return nil }
        let fileURL = directory.appendingPathComponent(fileName)
        
        do {
            return try Data(contentsOf: fileURL)
        } catch {
            print("🔄 SHARE EXT: Failed to load audio \(fileName): \(error)")
            return nil
        }
    }
    
    /// Deletes audio file from shared directory
    static func deleteAudioFile(fileName: String) {
        guard let directory = sharedDirectory else { return }
        let fileURL = directory.appendingPathComponent(fileName)
        
        do {
            try FileManager.default.removeItem(at: fileURL)
            print("🔄 SHARE EXT: Deleted audio file \(fileName)")
        } catch {
            print("🔄 SHARE EXT: Failed to delete audio file \(fileName): \(error)")
        }
    }
}
