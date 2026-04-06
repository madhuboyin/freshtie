import Foundation

/// Unified permission state for different iOS framework statuses.
enum PermissionState: String {
    case notDetermined
    case authorized
    case denied
    case restricted
    case limited // Relevant to Contacts in iOS 14+
    
    var label: String {
        switch self {
        case .notDetermined: return "Not requested"
        case .authorized:    return "Allowed"
        case .denied:        return "Denied"
        case .restricted:    return "Restricted"
        case .limited:       return "Limited"
        }
    }
    
    /// Returns true if the state allows for a "Settings" recovery path.
    var isDenied: Bool {
        self == .denied || self == .restricted
    }
}
