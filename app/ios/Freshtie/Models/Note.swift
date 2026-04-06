import Foundation
import SwiftData

// MARK: - Supporting enum

enum NoteSourceType: String, Codable {
    case manualText
    case manualVoice  // Phase 7 will write real transcriptions here
}

// MARK: - Note model

@Model
final class Note {

    @Attribute(.unique) var id: UUID
    var rawText: String
    var createdAt: Date
    var sourceType: NoteSourceType

    /// Back-reference to the owning person.
    /// Declared here to satisfy the inverse requirement on Person.notes.
    var person: Person?

    // MARK: Init

    init(rawText: String, sourceType: NoteSourceType = .manualText) {
        self.id = UUID()
        self.rawText = rawText
        self.createdAt = Date()
        self.sourceType = sourceType
    }
}
