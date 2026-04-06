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
    
    @MainActor
    static func requestAccess() async -> Bool {
        AnalyticsService.shared.track(.microphone_permission_requested, metadata: [AnalyticsMetadata.sourceType: "speech_recognition"])
        return await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                let granted = status == .authorized
                Task { @MainActor in
                    AnalyticsService.shared.track(.microphone_permission_granted, metadata: [
                        AnalyticsMetadata.sourceType: "speech_recognition",
                        AnalyticsMetadata.status: String(granted)
                    ])
                }
                continuation.resume(returning: granted)
            }
        }
    }
}
