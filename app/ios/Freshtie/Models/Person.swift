import Foundation

struct Person: Identifiable, Hashable {
    let id: UUID
    let displayName: String
    let initials: String
    let lastContext: String?
    let lastInteractionLabel: String?

    init(
        id: UUID = UUID(),
        displayName: String,
        lastContext: String? = nil,
        lastInteractionLabel: String? = nil
    ) {
        self.id = id
        self.displayName = displayName
        self.initials = Self.makeInitials(from: displayName)
        self.lastContext = lastContext
        self.lastInteractionLabel = lastInteractionLabel
    }

    private static func makeInitials(from name: String) -> String {
        name.split(separator: " ")
            .compactMap(\.first)
            .prefix(2)
            .map { String($0).uppercased() }
            .joined()
    }
}
