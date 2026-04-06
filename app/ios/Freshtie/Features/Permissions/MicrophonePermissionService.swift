import AVFoundation

/// Thin wrapper for AVAudioSession record permission.
enum MicrophonePermissionService {
    
    static var status: PermissionState {
        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted:      return .authorized
        case .denied:       return .denied
        case .undetermined: return .notDetermined
        @unknown default:   return .notDetermined
        }
    }
    
    static var isAuthorized: Bool {
        status == .authorized
    }
    
    static func requestAccess() async -> Bool {
        AnalyticsService.shared.track(.microphone_permission_requested, metadata: [AnalyticsMetadata.sourceType: "microphone"])
        return await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                AnalyticsService.shared.track(.microphone_permission_granted, metadata: [
                    AnalyticsMetadata.sourceType: "microphone",
                    AnalyticsMetadata.status: String(granted)
                ])
                continuation.resume(returning: granted)
            }
        }
    }
}
