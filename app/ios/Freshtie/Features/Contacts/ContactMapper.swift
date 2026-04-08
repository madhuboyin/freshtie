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
        findOrCreate(
            contactIdentifier: contact.identifier,
            displayName: displayName(from: contact),
            creationSource: .contactPicker,
            in: context
        )
    }

    /// Returns an existing Person whose `contactIdentifier` matches, or creates a new one.
    /// Use this overload when you have an identifier + name but no CNContact (e.g. Share Extension).
    @discardableResult
    static func findOrCreate(
        contactIdentifier: String,
        displayName: String,
        creationSource: PersonCreationSource = .contactPicker,
        in context: ModelContext
    ) -> Person {
        var descriptor = FetchDescriptor<Person>(
            predicate: #Predicate { $0.contactIdentifier == contactIdentifier }
        )
        descriptor.fetchLimit = 1

        if let existing = (try? context.fetch(descriptor))?.first {
            print("📱 ContactMapper: Found existing person for contact \(contactIdentifier): \(existing.displayName)")
            return existing
        }

        print("📱 ContactMapper: Creating new person for contact \(contactIdentifier): \(displayName)")
        return PersonRepository.createPerson(
            displayName: displayName,
            contactIdentifier: contactIdentifier,
            creationSource: creationSource,
            in: context
        )
    }
}
