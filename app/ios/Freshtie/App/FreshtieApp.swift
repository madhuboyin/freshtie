import SwiftUI
import SwiftData

@main
struct FreshtieApp: App {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @State private var detectionService = ContactDetectionService()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(detectionService)
                .onAppear {
                    checkPermissions() // Add this debug call
                    AnalyticsService.shared.track(.app_opened)
                    handleSharedPayloads()
                    Task { await detectionService.performDetection(modelContext: modelContext) }
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                    handleSharedPayloads()
                    Task { await detectionService.performDetection(modelContext: modelContext) }
                }
                .onChange(of: scenePhase) { _, newPhase in
                    switch newPhase {
                    case .active:
                        AnalyticsService.shared.track(.session_started)
                    case .background:
                        AnalyticsService.shared.track(.session_ended)
                    default:
                        break
                    }
                }
        }
        .modelContainer(.freshtie)
    }

    private func handleSharedPayloads() {
        let payloads = ShareExtensionStore.fetchAll()
        print("📱 DEBUG: Found \(payloads.count) shared payloads")
        guard !payloads.isEmpty else { return }

        for payload in payloads {
            print("📱 DEBUG: Processing shared contact: \(payload.displayName)")
            process(payload)
            AnalyticsService.shared.track(.share_extension_used)
        }

        ShareExtensionStore.clearAll()
    }

    private func process(_ payload: SharedPersonPayload) {
        print("📱 DEBUG: Processing payload for '\(payload.displayName)', contactID: \(payload.contactIdentifier ?? "none")")
        
        // 1. Find or create person
        var person: Person?
        
        if let cid = payload.contactIdentifier {
            let descriptor = FetchDescriptor<Person>(predicate: #Predicate { $0.contactIdentifier == cid })
            person = (try? modelContext.fetch(descriptor))?.first
            print("📱 DEBUG: Found existing person: \(person?.displayName ?? "none")")
        }
        
        if person == nil {
            person = PersonRepository.createPerson(
                displayName: payload.displayName,
                contactIdentifier: payload.contactIdentifier,
                creationSource: .manual, // Shared counts as manual/intentional
                in: modelContext
            )
            print("📱 DEBUG: Created new person: \(person?.displayName ?? "failed")")
        }
        
        // 2. Add note if present
        if let person = person, let noteText = payload.noteText {
            PersonRepository.addNote(
                rawText: noteText,
                sourceType: .manualText,
                to: person,
                in: modelContext
            )
        }
        
        try? modelContext.save()
    }

    private func checkPermissions() {
        let micStatus = MicrophonePermissionService.status
        let speechStatus = SpeechPermissionService.status
        print("🔍 PERMISSION CHECK:")
        print("   Microphone: \(micStatus) (isDenied: \(micStatus.isDenied))")
        print("   Speech: \(speechStatus) (isDenied: \(speechStatus.isDenied))")
    }
}
