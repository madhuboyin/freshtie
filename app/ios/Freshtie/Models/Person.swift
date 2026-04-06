import Foundation
import SwiftData

// MARK: - Supporting enums

enum PersonCreationSource: String, Codable {
    case manual
    case contactPicker   // Phase 3
    case shareExtension  // Phase 8
}

// MARK: - Person model

@Model
final class Person {

    @Attribute(.unique) var id: UUID
    var displayName: String
    var contactIdentifier: String?
    var createdAt: Date
    var lastOpenedAt: Date?
    var lastInteractionAt: Date?
    var creationSource: PersonCreationSource
    var isPinned: Bool

    @Relationship(deleteRule: .cascade, inverse: \Note.person)
    var notes: [Note] = []

    // MARK: Computed

    var initials: String { Person.makeInitials(from: displayName) }

    /// The most recent note's text. Used as "Last time" context in the UI.
    var lastContext: String? {
        notes.max(by: { $0.createdAt < $1.createdAt })?.rawText
    }

    /// Relative label for when this person was last opened or interacted with.
    var lastInteractionLabel: String? {
        guard let date = lastOpenedAt ?? lastInteractionAt else { return nil }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    // MARK: Init

    init(
        displayName: String,
        contactIdentifier: String? = nil,
        creationSource: PersonCreationSource = .manual
    ) {
        self.id = UUID()
        self.displayName = displayName
        self.contactIdentifier = contactIdentifier
        self.createdAt = Date()
        self.lastOpenedAt = nil
        self.lastInteractionAt = nil
        self.creationSource = creationSource
        self.isPinned = false
    }

    private static func makeInitials(from name: String) -> String {
        name.split(separator: " ")
            .compactMap(\.first)
            .prefix(2)
            .map { String($0).uppercased() }
            .joined()
    }
}
