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
        print("🔄 SHARE EXT: Starting contact extraction from \(items.count) items")
        
        for (index, item) in items.enumerated() {
            print("🔄 SHARE EXT: Processing item \(index)")
            guard let attachments = item.attachments else { 
                print("🔄 SHARE EXT: Item \(index) has no attachments")
                continue 
            }
            
            for (attachmentIndex, provider) in attachments.enumerated() {
                print("🔄 SHARE EXT: Checking attachment \(attachmentIndex)")
                
                // vCard is the standard for sharing contacts (public.vcard)
                if provider.hasItemConformingToTypeIdentifier(UTType.vCard.identifier) {
                    print("🔄 SHARE EXT: Found vCard attachment")
                    do {
                        let data = try await provider.loadItem(forTypeIdentifier: UTType.vCard.identifier)
                        
                        // provider.loadItem often returns a URL or Data
                        if let url = data as? URL {
                            print("🔄 SHARE EXT: Loading vCard from URL: \(url)")
                            let vCardData = try Data(contentsOf: url)
                            return try parseVCard(vCardData)
                        } else if let vCardData = data as? Data {
                            print("🔄 SHARE EXT: Processing vCard data directly")
                            return try parseVCard(vCardData)
                        } else {
                            print("🔄 SHARE EXT: Unexpected data type: \(type(of: data))")
                        }
                    } catch {
                        print("🔄 SHARE EXT: vCard extraction error: \(error)")
                    }
                } else {
                    print("🔄 SHARE EXT: Attachment \(attachmentIndex) is not a vCard")
                }
            }
        }
        
        print("🔄 SHARE EXT: No valid contact found in any items")
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
