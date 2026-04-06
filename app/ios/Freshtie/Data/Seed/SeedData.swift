import Foundation
import SwiftData

/// Dev-only seed data used by the preview container.
/// Never called in production.
enum SeedData {

    static func populate(into context: ModelContext) {
        let entries: [(name: String, noteText: String?, daysAgo: Int)] = [
            ("Sarah Chen",  "Starting new job at Google next Monday", 14),
            ("Marcus Webb", "Mentioned moving to Austin soon",         30),
            ("Jamie Torres", nil,                                      90),
            ("Alex Kim",    "Studying for the bar exam",               1),
        ]

        for entry in entries {
            let person = Person(displayName: entry.name)
            person.lastOpenedAt = Calendar.current.date(
                byAdding: .day,
                value: -entry.daysAgo,
                to: Date()
            )
            context.insert(person)

            if let text = entry.noteText {
                let note = Note(rawText: text)
                note.person = person
                context.insert(note)
            }
        }

        try? context.save()
    }
}
