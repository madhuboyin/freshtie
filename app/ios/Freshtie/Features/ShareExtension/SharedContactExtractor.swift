import Foundation
import Contacts
import UniformTypeIdentifiers

/// Extracts contact data from NSExtensionItem payloads.
enum SharedContactExtractor {
    
    /// Result structure for an extraction attempt.
    struct ExtractionResult {
        let displayName: String
        let contactIdentifier: String?
    }

    /// Attempts to extract contact info from the first valid item in an input list.
    static func extract(from items: [NSExtensionItem]) async -> ExtractionResult? {
        for item in items {
            guard let attachments = item.attachments else { continue }
            
            for provider in attachments {
                // vCard is the standard for sharing contacts (public.vcard)
                if provider.hasItemConformingToTypeIdentifier(UTType.vCard.identifier) {
                    do {
                        let data = try await provider.loadItem(forTypeIdentifier: UTType.vCard.identifier)
                        
                        // provider.loadItem often returns a URL or Data
                        if let url = data as? URL {
                            let vCardData = try Data(contentsOf: url)
                            return try parseVCard(vCardData)
                        } else if let vCardData = data as? Data {
                            return try parseVCard(vCardData)
                        }
                    } catch {
                        print("vCard extraction error: \(error)")
                    }
                }
            }
        }
        return nil
    }

    private static func parseVCard(_ data: Data) throws -> ExtractionResult? {
        let contacts = try CNContactVCardSerialization.contacts(with: data)
        guard let contact = contacts.first else { return nil }
        
        let name = CNContactFormatter.string(from: contact, style: .fullName) ?? "Shared Contact"
        return ExtractionResult(displayName: name, contactIdentifier: contact.identifier)
    }
}

// Extension to bridge NSItemProvider to async/await
extension NSItemProvider {
    func loadItem(forTypeIdentifier typeIdentifier: String) async throws -> NSSecureCoding? {
        try await withCheckedThrowingContinuation { continuation in
            self.loadItem(forTypeIdentifier: typeIdentifier, options: nil) { item, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: item)
                }
            }
        }
    }
}
