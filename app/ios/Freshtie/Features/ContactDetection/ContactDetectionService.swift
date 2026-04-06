import Foundation
import Contacts
import Observation
import SwiftData

/// Foreground-only contact detection and trigger orchestrator.
///
/// Called on every app foreground / resume. Compares the current system
/// contact list against a locally stored snapshot to identify genuinely
/// new contacts, then evaluates whether a trigger should be shown.
///
/// Design constraints:
/// - Runs only in the foreground; no background monitoring.
/// - Shows at most one trigger per detection pass.
/// - Each contact gets at most one trigger opportunity (suppressed on dismiss).
/// - Rapid foreground/background cycling is guarded by a global cooldown.
/// - First launch is treated as snapshot initialisation only — no trigger.
@MainActor
@Observable
final class ContactDetectionService {

    // MARK: - Trigger model

    struct CandidateTrigger: Identifiable {
        let id = UUID()
        let contact: CNContact
        let state: TriggerTimingState

        /// Short first-name for use in trigger messages.
        /// Falls back to family name, then "someone" if both are empty.
        var displayNameForMessage: String {
            if !contact.givenName.isEmpty  { return contact.givenName  }
            if !contact.familyName.isEmpty { return contact.familyName }
            return "someone"
        }

        var message: String { state.message(for: displayNameForMessage) }
    }

    // MARK: - Public state

    /// The current active trigger. HomeView observes this to show the banner.
    var activeTrigger: CandidateTrigger?

    // MARK: - Private

    private let store = CNContactStore()

    private static let suppressedKey  = "freshtie_suppressed_triggers"
    private static let lastTriggerKey = "freshtie_last_trigger_shown"

    /// Minimum gap between any two trigger presentations, regardless of contact.
    /// Prevents rapid cycling from surfacing back-to-back triggers.
    private static let triggerCooldown: TimeInterval = 30 * 60  // 30 minutes

    // MARK: - Detection

    /// Performs a foreground detection pass.
    ///
    /// - Parameter modelContext: SwiftData context used to check whether a
    ///   matching local Person already exists. Pass `nil` only in tests.
    func performDetection(modelContext: ModelContext? = nil) async {
        guard ContactPermissionService.isAuthorized else { return }

        // Fetch minimal contact fields — identifier + name only.
        let keys: [CNKeyDescriptor] = [
            CNContactIdentifierKey  as CNKeyDescriptor,
            CNContactGivenNameKey   as CNKeyDescriptor,
            CNContactFamilyNameKey  as CNKeyDescriptor,
        ]

        var allContacts: [String: CNContact] = [:]
        do {
            let request = CNContactFetchRequest(keysToFetch: keys)
            try store.enumerateContacts(with: request) { contact, _ in
                allContacts[contact.identifier] = contact
            }
        } catch {
            return  // Permission may have been revoked mid-session; fail silently.
        }

        let previous = ContactSnapshotStore.fetch()
        let now = Date()

        // ── First-run guard ──────────────────────────────────────────────────
        // If there is no existing snapshot, this is the user's first detection
        // pass. Save the current contacts as the baseline and return without
        // triggering — every contact in the book would otherwise appear "new".
        if previous.isEmpty {
            let initial = allContacts.keys.reduce(into: [String: Date]()) { $0[$1] = now }
            ContactSnapshotStore.save(initial)
            return
        }

        // ── Identify new contacts ────────────────────────────────────────────
        // Contacts present now but absent in the previous snapshot.
        // Sorted for deterministic ordering across detection passes.
        let newIDs = allContacts.keys
            .filter { previous[$0] == nil }
            .sorted()

        guard !newIDs.isEmpty else { return }

        // Persist merged snapshot immediately so these IDs are not re-detected
        // on the next foreground pass, even if we end up suppressing the trigger.
        var merged = previous
        for id in newIDs { merged[id] = now }
        ContactSnapshotStore.save(merged)

        // ── Global cooldown ──────────────────────────────────────────────────
        // If a trigger was surfaced within the last 30 minutes, do not surface
        // another one — even for a different contact.
        if let lastShown = UserDefaults.standard.object(forKey: Self.lastTriggerKey) as? Date,
           now.timeIntervalSince(lastShown) < Self.triggerCooldown {
            return
        }

        // ── Active trigger guard ─────────────────────────────────────────────
        // Do not replace a trigger the user has not yet seen or acted on.
        guard activeTrigger == nil else { return }

        // ── Evaluate candidates ──────────────────────────────────────────────
        let suppressedIDs = UserDefaults.standard.stringArray(forKey: Self.suppressedKey) ?? []

        for candidateID in newIDs {
            guard let contact = allContacts[candidateID] else { continue }

            let firstSeenDate = merged[candidateID] ?? now
            let state = TriggerTimingState.state(for: firstSeenDate)

            let eligible = ContactTriggerEvaluator.isEligible(
                contactID: candidateID,
                firstName: contact.givenName,
                familyName: contact.familyName,
                state: state,
                suppressedIDs: suppressedIDs,
                modelContext: modelContext
            )

            if eligible {
                activeTrigger = CandidateTrigger(contact: contact, state: state)
                UserDefaults.standard.set(now, forKey: Self.lastTriggerKey)
                return  // One trigger per detection pass.
            }
        }
    }

    // MARK: - Trigger actions

    /// Dismisses the active trigger and suppresses the contact.
    /// The contact will not trigger again in future detection passes.
    func dismissTrigger() {
        if let id = activeTrigger?.contact.identifier {
            suppress(id: id)
        }
        activeTrigger = nil
    }

    // MARK: - Suppression

    private func suppress(id: String) {
        var list = UserDefaults.standard.stringArray(forKey: Self.suppressedKey) ?? []
        guard !list.contains(id) else { return }
        list.append(id)
        UserDefaults.standard.set(list, forKey: Self.suppressedKey)
    }
}
