import Foundation
import SwiftData

extension ModelContainer {

    /// Production container — persistent SQLite store on device.
    static let freshtie: ModelContainer = {
        let schema = Schema([Person.self, Note.self])
        let appGroupId = "group.com.madhuboyin.Freshtie"
        let storeName = "Freshtie.sqlite"
        
        guard let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupId) else {
            fatalError("Freshtie: Failed to initialize App Group container for \(appGroupId)")
        }
        
        let fileURL = groupURL.appendingPathComponent("Library/Application Support/\(storeName)")
        
        // Ensure the directory exists before SwiftData tries to create the store
        let directoryURL = fileURL.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        
        let config = ModelConfiguration(url: fileURL)
        
        do {
            return try ModelContainer(for: schema, configurations: [config])
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
