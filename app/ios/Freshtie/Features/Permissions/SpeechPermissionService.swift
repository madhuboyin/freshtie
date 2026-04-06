import Speech

/// Thin wrapper for SFSpeechRecognizer authorization.
enum SpeechPermissionService {
    
    static var status: PermissionState {
        switch SFSpeechRecognizer.authorizationStatus() {
        case .authorized:    return .authorized
        case .denied:        return .denied
        case .restricted:    return .restricted
        case .notDetermined: return .notDetermined
        @unknown default:    return .notDetermined
        }
    }
    
    static var isAuthorized: Bool {
        status == .authorized
    }
    
    static func requestAccess() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }
}
