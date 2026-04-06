import Contacts

/// Thin stateless wrapper around CNContactStore authorization.
/// All methods are safe to call from the main actor.
enum ContactPermissionService {

    static var status: PermissionState {
        switch CNContactStore.authorizationStatus(for: .contacts) {
        case .authorized:    return .authorized
        case .denied:        return .denied
        case .restricted:    return .restricted
        case .notDetermined: return .notDetermined
        case .limited:       return .limited
        @unknown default:    return .notDetermined
        }
    }

    /// `true` when the contact picker can be shown without requesting permission first.
    static var isAuthorized: Bool {
        status == .authorized || status == .limited
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
