import Foundation
import SwiftData

/// Support for prototype validation sessions.
/// Allows resetting state and preparing specific test scenarios.
@MainActor
final class ValidationSupport {
    static let shared = ValidationSupport()
    
    /// Completely resets the app state for a new tester.
    func resetEverything(modelContext: ModelContext) {
        // 1. Clear People and Notes
        do {
            try modelContext.delete(model: Person.self)
            try modelContext.delete(model: Note.self)
            try modelContext.save()
        } catch {
            print("❌ ValidationSupport: failed to reset data — \(error)")
        }
        
        // 2. Clear Analytics
        // Analytics use a different container in AnalyticsEventStore, 
        // but for MVP validation we can just let it persist or add a clear there.
        // For now, we clear the main data which is most important for tester flow.
        
        // 3. Clear Contact Snapshot & Suppression
        UserDefaults.standard.removeObject(forKey: "freshtie_contact_snapshot")
        UserDefaults.standard.removeObject(forKey: "freshtie_last_contact_check")
        UserDefaults.standard.removeObject(forKey: "freshtie_suppressed_triggers")
        
        print("✅ ValidationSupport: App state reset complete.")
    }
    
    /// Seeds a rich context scenario for demonstration.
    func seedRichScenario(modelContext: ModelContext) {
        let sarah = Person(displayName: "Sarah Chen", creationSource: .manual)
        sarah.lastOpenedAt = Calendar.current.date(byAdding: .day, value: -2, to: Date())
        modelContext.insert(sarah)
        
        let notes = [
            "Met at the coffee shop on Tuesday",
            "Working on a new AI project for healthcare",
            "Moving to New York next month",
            "Has a golden retriever named Luna"
        ]
        
        for text in notes {
            let note = Note(rawText: text, sourceType: .manualText)
            note.person = sarah
            modelContext.insert(note)
        }
        
        try? modelContext.save()
        print("✅ ValidationSupport: Rich scenario seeded.")
    }
}
