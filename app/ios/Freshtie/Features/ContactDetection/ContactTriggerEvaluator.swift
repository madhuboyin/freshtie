import Foundation
import SwiftData

/// Centralized eligibility rules for new-contact trigger display.
///
/// All conditions must pass for a trigger to be surfaced. Keeping these
/// checks in one place makes the suppression policy easy to audit and tune.
@MainActor
enum ContactTriggerEvaluator {

    /// Returns `true` if the candidate contact should produce a visible trigger.
    ///
    /// - Parameters:
    ///   - contactID:     Stable CNContact identifier.
    ///   - firstName:     Contact's given name (may be empty).
    ///   - familyName:    Contact's family name (may be empty).
    ///   - state:         Timing state computed from first-seen date.
    ///   - suppressedIDs: Contacts the user has already dismissed.
    ///   - modelContext:  SwiftData context for checking existing Person records.
    static func isEligible(
        contactID: String,
        firstName: String,
        familyName: String,
        state: TriggerTimingState,
        suppressedIDs: [String],
        modelContext: ModelContext?
    ) -> Bool {
        // 1. Expired triggers are never shown.
        guard state != .expired else { return false }

        // 2. Contact must have a usable display name.
        //    An empty or whitespace-only name would produce a broken message.
        let hasName = !firstName.trimmingCharacters(in: .whitespaces).isEmpty
                   || !familyName.trimmingCharacters(in: .whitespaces).isEmpty
        guard hasName else { return false }

        // 3. Contact must not have been dismissed before.
        guard !suppressedIDs.contains(contactID) else { return false }

        // 4. Skip if a local Person is already linked and has notes captured.
        //    The user has clearly already done something with this contact —
        //    triggering again would feel redundant and noisy.
        if let ctx = modelContext {
            var descriptor = FetchDescriptor<Person>(
                predicate: #Predicate { $0.contactIdentifier == contactID }
            )
            descriptor.fetchLimit = 1
            if let existing = (try? ctx.fetch(descriptor))?.first,
               !existing.notes.isEmpty {
                return false
            }
        }

        return true
    }
}
