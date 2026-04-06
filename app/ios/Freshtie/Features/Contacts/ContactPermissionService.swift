import Contacts

/// Thin stateless wrapper around CNContactStore authorization.
/// All methods are safe to call from the main actor.
enum ContactPermissionService {

    static var status: CNAuthorizationStatus {
        CNContactStore.authorizationStatus(for: .contacts)
    }

    /// `true` when the contact picker can be shown without requesting permission first.
    static var isAuthorized: Bool {
        status == .authorized
    }

    /// Requests access. If already determined, returns the existing grant immediately.
    /// Must be called from an async context; safe to call multiple times.
    static func requestAccess() async -> Bool {
        do {
            return try await CNContactStore().requestAccess(for: .contacts)
        } catch {
            return false
        }
    }
}
