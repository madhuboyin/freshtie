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
        await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }
}
