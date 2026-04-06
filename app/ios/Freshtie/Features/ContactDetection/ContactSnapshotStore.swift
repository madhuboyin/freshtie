import Foundation

/// Lightweight snapshot of a contact's core identity for detection.
struct ContactEntry: Codable {
    let identifier: String
    let creationDate: Date? // Some iOS versions/sources provide this; fallback to 'now' if first-seen.
}

/// Local persistence for previously seen contacts snapshot.
enum ContactSnapshotStore {
    private static let snapshotKey = "freshtie_contact_snapshot"
    private static let lastSeenKey = "freshtie_last_contact_check"

    private static var defaults: UserDefaults { UserDefaults.standard }

    /// Returns the full list of identifiers from the last snapshot.
    static func fetch() -> [String: Date] {
        guard let data = defaults.data(forKey: snapshotKey),
              let dict = try? JSONDecoder().decode([String: Date].self, from: data) else {
            return [:]
        }
        return dict
    }

    /// Persists a new snapshot of contact identifiers.
    static func save(_ snapshot: [String: Date]) {
        if let data = try? JSONEncoder().encode(snapshot) {
            defaults.set(data, forKey: snapshotKey)
            defaults.set(Date(), forKey: lastSeenKey)
        }
    }

    /// Returns the timestamp of the last successful detection pass.
    static var lastCheckDate: Date? {
        defaults.object(forKey: lastSeenKey) as? Date
    }
}
