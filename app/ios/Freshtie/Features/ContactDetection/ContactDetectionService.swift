import Foundation
import Contacts
import Observation

/// Foreground-only contact detection and trigger orchestrator.
@MainActor
@Observable
final class ContactDetectionService {
    
    struct CandidateTrigger: Identifiable {
        let id = UUID()
        let contact: CNContact
        let state: TriggerTimingState
        
        var message: String { state.message(for: contact.givenName) }
    }

    /// The current active trigger to be shown in UI.
    var activeTrigger: CandidateTrigger?
    
    private let store = CNContactStore()
    private static let suppressedKey = "freshtie_suppressed_triggers"

    /// Performs the foreground detection pass.
    func performDetection() async {
        guard ContactPermissionService.isAuthorized else { return }
        
        // 1. Fetch current minimal snapshot from system
        let keys = [CNContactIdentifierKey as CNKeyDescriptor,
                    CNContactGivenNameKey as CNKeyDescriptor,
                    CNContactFamilyNameKey as CNKeyDescriptor]
        
        let request = CNContactFetchRequest(keysToFetch: keys)
        var currentSnapshot: [String: Date] = [:]
        var allContacts: [String: CNContact] = [:]

        do {
            try store.enumerateContacts(with: request) { contact, _ in
                // We use first-seen-date as a proxy if no creationDate is in SDK
                currentSnapshot[contact.identifier] = Date() 
                allContacts[contact.identifier] = contact
            }
        } catch {
            return
        }

        // 2. Load previous snapshot
        let previous = ContactSnapshotStore.fetch()
        
        // 3. Identification: identifiers in 'current' but not in 'previous'
        let newIDs = currentSnapshot.keys.filter { previous[$0] == nil }
        
        // 4. Update snapshot immediately to avoid repeated detection of same items
        // We merge previous dates with new ones to keep the original first-seen date.
        var merged = previous
        for id in newIDs { merged[id] = Date() }
        ContactSnapshotStore.save(merged)

        // 5. Pick candidate for trigger (Most recent one only for MVP)
        guard let firstNewID = newIDs.first,
              let contact = allContacts[firstNewID],
              !isSuppressed(id: firstNewID) else {
            return
        }
        
        // 6. Apply Timing Model
        let firstSeenDate = merged[firstNewID] ?? Date()
        let state = TriggerTimingState.state(for: firstSeenDate)
        
        if state != .expired {
            self.activeTrigger = CandidateTrigger(contact: contact, state: state)
        }
    }

    func dismissTrigger() {
        if let id = activeTrigger?.contact.identifier {
            suppress(id: id)
        }
        activeTrigger = nil
    }

    // MARK: - Suppression

    private func isSuppressed(id: String) -> Bool {
        let list = UserDefaults.standard.stringArray(forKey: Self.suppressedKey) ?? []
        return list.contains(id)
    }

    private func suppress(id: String) {
        var list = UserDefaults.standard.stringArray(forKey: Self.suppressedKey) ?? []
        if !list.contains(id) {
            list.append(id)
            UserDefaults.standard.set(list, forKey: Self.suppressedKey)
        }
    }
}
