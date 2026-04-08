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

    // v2: bumped from v1 to force a re-run for installs where v1 ran before
    // the cascade-delete ordering bug was fixed.
    private static let didRunKey = "didRunDuplicateMerge_v2"

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
                // Snapshot notes into a plain array before mutating the relationship,
                // to avoid iterating a live collection that SwiftData is modifying.
                let notesToMove = Array(duplicate.notes)

                // Re-parent each note onto the canonical person.
                for note in notesToMove {
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
            }
        }

        // Save note reassignments BEFORE deleting duplicates. This ensures SwiftData
        // commits the new person→note links before the cascade-delete rule fires,
        // so notes are not swept up in the cascade.
        try context.save()

        for group in duplicateGroups {
            let sorted = group.sorted { $0.createdAt < $1.createdAt }
            for duplicate in sorted.dropFirst() {
                print("🔧 DuplicateContactMerger: deleting duplicate '\(duplicate.displayName)' (\(duplicate.id))")
                context.delete(duplicate)
            }
        }

        try context.save()
    }
}
