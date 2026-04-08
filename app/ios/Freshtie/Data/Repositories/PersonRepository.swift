import Foundation
import SwiftData

/// Thin helper for operations that need more than @Query provides.
/// Keeps sort logic and mutation helpers DRY across views.
enum PersonRepository {

    // MARK: Queries

    /// Sorts people for the Home / Capture picker: pinned first, then most recently opened.
    static func sortedForHome(_ people: [Person]) -> [Person] {
        people.sorted {
            if $0.isPinned != $1.isPinned { return $0.isPinned }
            let d0 = $0.lastOpenedAt ?? $0.createdAt
            let d1 = $1.lastOpenedAt ?? $1.createdAt
            return d0 > d1
        }
    }

    // MARK: Mutations

    /// Stamps lastOpenedAt and persists the change.
    static func markOpened(_ person: Person, in context: ModelContext) {
        person.lastOpenedAt = Date()
        try? context.save()
    }

    /// Creates a Person, inserts it, and saves.
    @discardableResult
    static func createPerson(
        displayName: String,
        contactIdentifier: String? = nil,
        creationSource: PersonCreationSource = .manual,
        in context: ModelContext
    ) -> Person {
        let trimmedName = displayName.trimmingCharacters(in: .whitespaces)
        
        // Check for existing manual person with same name if no contactIdentifier
        if contactIdentifier == nil {
            let normalizedName = trimmedName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            
            // First try exact match
            var descriptor = FetchDescriptor<Person>(
                predicate: #Predicate { person in
                    person.contactIdentifier == nil && person.displayName == trimmedName
                }
            )
            descriptor.fetchLimit = 1
            
            if let existing = (try? context.fetch(descriptor))?.first {
                print("📱 PersonRepository: Found existing manual person with exact name '\(trimmedName)': \(existing.id)")
                return existing
            }
            
            // Then try normalized match for all manual entries
            let allManualPeople = (try? context.fetch(FetchDescriptor<Person>(
                predicate: #Predicate { $0.contactIdentifier == nil }
            ))) ?? []
            
            for person in allManualPeople {
                let existingNormalized = person.displayName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                if existingNormalized == normalizedName {
                    print("📱 PersonRepository: Found existing manual person with similar name '\(person.displayName)' (normalized match): \(person.id)")
                    return person
                }
            }
        }
        
        print("📱 PersonRepository: Creating new person '\(trimmedName)' with contactId: \(contactIdentifier ?? "nil")")
        let person = Person(
            displayName: trimmedName,
            contactIdentifier: contactIdentifier,
            creationSource: creationSource
        )
        context.insert(person)
        try? context.save()
        return person
    }

    /// Attaches a Note to a Person and saves.
    @discardableResult
    static func addNote(
        rawText: String,
        sourceType: NoteSourceType = .manualText,
        to person: Person,
        in context: ModelContext
    ) -> Note {
        let note = Note(rawText: rawText, sourceType: sourceType)
        note.person = person
        
        // Update recency
        person.lastInteractionAt = Date()
        person.lastOpenedAt = Date()
        
        context.insert(note)
        try? context.save()
        return note
    }
}
