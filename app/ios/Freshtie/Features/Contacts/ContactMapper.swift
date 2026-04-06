import Contacts
import SwiftData

/// Maps a CNContact to a local Person record.
///
/// Deduplication: if a Person already exists with the same contactIdentifier,
/// that record is returned unchanged — no duplicate is created.
enum ContactMapper {

    // MARK: Display name

    /// Best-effort display name from a contact, falling back to organization then "Unknown".
    static func displayName(from contact: CNContact) -> String {
        if let full = CNContactFormatter.string(from: contact, style: .fullName),
           !full.trimmingCharacters(in: .whitespaces).isEmpty {
            return full
        }
        if !contact.organizationName.isEmpty {
            return contact.organizationName
        }
        return "Unknown"
    }

    // MARK: Find or create

    /// Returns an existing Person whose `contactIdentifier` matches, or creates a new one.
    ///
    /// The returned Person is already inserted and saved in the provided context.
    @discardableResult
    static func findOrCreate(contact: CNContact, in context: ModelContext) -> Person {
        let identifier = contact.identifier
        var descriptor = FetchDescriptor<Person>(
            predicate: #Predicate { $0.contactIdentifier == identifier }
        )
        descriptor.fetchLimit = 1

        if let existing = (try? context.fetch(descriptor))?.first {
            return existing
        }

        return PersonRepository.createPerson(
            displayName: displayName(from: contact),
            contactIdentifier: identifier,
            creationSource: .contactPicker,
            in: context
        )
    }
}
