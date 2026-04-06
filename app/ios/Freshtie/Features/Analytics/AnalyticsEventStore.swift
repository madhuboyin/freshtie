import Foundation
import SwiftData

/// Thread-safe persistence layer for analytics events.
@MainActor
final class AnalyticsEventStore {
    static let shared = AnalyticsEventStore()
    
    /// Dedicated persistent container for analytics data.
    private let container: ModelContainer = {
        let schema = Schema([AnalyticsEvent.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Freshtie Analytics: failed to create container — \(error)")
        }
    }()
    
    private var context: ModelContext {
        container.mainContext
    }

    /// Persists a new event to local storage.
    func log(_ event: AnalyticsEvent) {
        context.insert(event)
        try? context.save()
        
        // Debug visibility as required by Phase 11
        #if DEBUG
        print("📊 [Analytics] \(event.eventName) — metadata: \(event.metadataJSON ?? "none")")
        #endif
        
        // Keep storage lightweight (e.g., cap at 1000 events as suggested)
        cleanupOldEventsIfNeeded()
    }
    
    /// Returns the most recent N events for validation.
    func fetchRecent(limit: Int = 100) -> [AnalyticsEvent] {
        var descriptor = FetchDescriptor<AnalyticsEvent>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        return (try? context.fetch(descriptor)) ?? []
    }

    /// Caps storage to avoid excessive disk usage over time.
    private func cleanupOldEventsIfNeeded() {
        let maxEvents = 1000
        let descriptor = FetchDescriptor<AnalyticsEvent>(sortBy: [SortDescriptor(\.timestamp, order: .reverse)])
        
        guard let count = try? context.fetchCount(descriptor), count > maxEvents else { return }
        
        // Simple cleanup: delete anything older than the 1000th newest event
        let events = try? context.fetch(descriptor)
        if let toDelete = events?.dropFirst(maxEvents) {
            for event in toDelete {
                context.delete(event)
            }
            try? context.save()
        }
    }
}
