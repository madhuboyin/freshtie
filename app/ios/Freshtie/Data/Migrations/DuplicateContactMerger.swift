import SwiftData
import Foundation

/// One-time migration that collapses duplicate Person records caused by the
/// share-extension deduplication bug (pre-fix). Runs at most once per install,
/// gated by a UserDefaults flag.
///
/// Strategy: for every contactIdentifier that appears on more than one Person,
/// keep the oldest record (by createdAt) as the canonical one, re-parent all
/// notes from the duplicates onto it, then delete the duplicates.
enum DuplicateContactMerger {

    private static let didRunKey = "didRunDuplicateMerge_v1"

    /// Call this once at app launch. Safe to call unconditionally — it skips
    /// immediately after the first successful run.
    @MainActor
    static func runIfNeeded(in context: ModelContext) {
        guard !UserDefaults.standard.bool(forKey: didRunKey) else { return }

        do {
            try merge(in: context)
            UserDefaults.standard.set(true, forKey: didRunKey)
            print("🔧 DuplicateContactMerger: complete")
        } catch {
            // Leave the flag unset so we retry next launch.
            print("🔧 DuplicateContactMerger: failed — \(error)")
        }
    }

    // MARK: - Private

    private static func merge(in context: ModelContext) throws {
        let allPeople = try context.fetch(FetchDescriptor<Person>())

        // Group by contactIdentifier, ignoring persons without one (manual adds).
        var byIdentifier: [String: [Person]] = [:]
        for person in allPeople {
            guard let cid = person.contactIdentifier else { continue }
            byIdentifier[cid, default: []].append(person)
        }

        // Only act on groups that actually have duplicates.
        let duplicateGroups = byIdentifier.values.filter { $0.count > 1 }
        guard !duplicateGroups.isEmpty else {
            print("🔧 DuplicateContactMerger: no duplicates found")
            return
        }

        print("🔧 DuplicateContactMerger: merging \(duplicateGroups.count) duplicate group(s)")

        for group in duplicateGroups {
            // Oldest record is canonical — it's the one the user interacted with first.
            let sorted = group.sorted { $0.createdAt < $1.createdAt }
            let canonical = sorted[0]
            let duplicates = sorted.dropFirst()

            for duplicate in duplicates {
                // Re-parent notes. Assign directly to canonical; SwiftData will
                // update the inverse relationship and cascade correctly on delete.
                for note in duplicate.notes {
                    note.person = canonical
                }

                // Preserve the earliest interaction/open timestamps.
                if let dupInteraction = duplicate.lastInteractionAt {
                    if let canonInteraction = canonical.lastInteractionAt {
                        canonical.lastInteractionAt = min(canonInteraction, dupInteraction)
                    } else {
                        canonical.lastInteractionAt = dupInteraction
                    }
                }

                // isPinned: if any duplicate was pinned, keep it pinned.
                if duplicate.isPinned {
                    canonical.isPinned = true
                }

                context.delete(duplicate)
                print("🔧 DuplicateContactMerger: merged '\(duplicate.displayName)' (\(duplicate.id)) → canonical \(canonical.id)")
            }
        }

        try context.save()
    }
}
