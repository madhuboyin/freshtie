import SwiftData

extension ModelContainer {

    /// Production container — persistent SQLite store on device.
    static let freshtie: ModelContainer = {
        let schema = Schema([Person.self, Note.self])
        do {
            return try ModelContainer(for: schema)
        } catch {
            fatalError("Freshtie: failed to create ModelContainer — \(error)")
        }
    }()

    /// In-memory container pre-populated with seed data.
    /// Use `.modelContainer(.preview)` in SwiftUI previews.
    @MainActor
    static let preview: ModelContainer = {
        let schema = Schema([Person.self, Note.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        do {
            let container = try ModelContainer(for: schema, configurations: [config])
            SeedData.populate(into: container.mainContext)
            return container
        } catch {
            fatalError("Freshtie: failed to create preview ModelContainer — \(error)")
        }
    }()
}
