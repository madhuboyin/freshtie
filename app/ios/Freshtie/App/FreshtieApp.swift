import SwiftUI
import SwiftData

@main
struct FreshtieApp: App {
    @State private var detectionService = ContactDetectionService()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(detectionService)
                .onAppear {
                    checkPermissions() // Add this debug call
                    AnalyticsService.shared.track(.app_opened)
                }
        }
        .modelContainer(.freshtie)
    }

    private func checkPermissions() {
        let micStatus = MicrophonePermissionService.status
        let speechStatus = SpeechPermissionService.status
        print("🔍 PERMISSION CHECK:")
        print("   Microphone: \(micStatus) (isDenied: \(micStatus.isDenied))")
        print("   Speech: \(speechStatus) (isDenied: \(speechStatus.isDenied))")
    }
}
