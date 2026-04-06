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
                    AnalyticsService.shared.track(.app_opened)
                    handleSharedPayloads()
                    Task { await detectionService.performDetection() }
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                    handleSharedPayloads()
                    Task { await detectionService.performDetection() }
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
        guard !payloads.isEmpty else { return }

        for payload in payloads {
            process(payload)
        }
        
        ShareExtensionStore.clearAll()
    }

    private func process(_ payload: SharedPersonPayload) {
        // 1. Find or create person
        var person: Person?
        
        if let cid = payload.contactIdentifier {
            let descriptor = FetchDescriptor<Person>(predicate: #Predicate { $0.contactIdentifier == cid })
            person = (try? modelContext.fetch(descriptor))?.first
        }
        
        if person == nil {
            person = PersonRepository.createPerson(
                displayName: payload.displayName,
                contactIdentifier: payload.contactIdentifier,
                creationSource: .manual, // Shared counts as manual/intentional
                in: modelContext
            )
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
}
