import SwiftUI
import SwiftData

/// Top-level tab container.
///
/// Navigation model:
///   Home tab     — NavigationStack; pushes PersonView on person selection.
///   Capture tab  — CapturePersonPickerView; selects a person then pushes CaptureView.
///   Settings tab — NavigationStack; placeholder rows only.
///
/// PersonView also presents CaptureView as a sheet via its own @State.
struct RootView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }

            CapturePersonPickerView()
                .tabItem {
                    Label("Capture", systemImage: "waveform")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
        .tint(AppColors.accent)
        .onAppear {
            DuplicateContactMerger.runIfNeeded(in: modelContext)
            debugPrintDuplicates()
        }
        // Temporary: triple tap anywhere to force duplicate cleanup
        .onTapGesture(count: 3) {
            print("🔧 Force cleaning duplicates...")
            forceCleanupDuplicates()
        }
    }
    
    // MARK: - Debug
    
    private func debugPrintDuplicates() {
        let allPeople = (try? modelContext.fetch(FetchDescriptor<Person>())) ?? []
        
        // Group by contactIdentifier
        var byIdentifier: [String: [Person]] = [:]
        for person in allPeople {
            guard let cid = person.contactIdentifier else { continue }
            byIdentifier[cid, default: []].append(person)
        }
        
        // Group by displayName for manual entries
        var byName: [String: [Person]] = [:]
        for person in allPeople {
            guard person.contactIdentifier == nil else { continue }
            byName[person.displayName, default: []].append(person)
        }
        
        let duplicatesByIdentifier = byIdentifier.values.filter { $0.count > 1 }
        let duplicatesByName = byName.values.filter { $0.count > 1 }
        
        if !duplicatesByIdentifier.isEmpty || !duplicatesByName.isEmpty {
            print("🔍 DUPLICATE CONTACTS FOUND:")
            
            for group in duplicatesByIdentifier {
                print("📱 Contact ID \(group.first?.contactIdentifier ?? "nil"): \(group.count) duplicates")
                for person in group {
                    print("  - \(person.displayName) (created: \(person.createdAt), source: \(person.creationSource))")
                }
            }
            
            for group in duplicatesByName {
                print("👤 Manual name '\(group.first?.displayName ?? "nil")': \(group.count) duplicates")
                for person in group {
                    print("  - ID: \(person.id) (created: \(person.createdAt), source: \(person.creationSource))")
                }
            }
        } else {
            print("✅ No duplicate contacts found")
        }
        
        print("📊 Total people: \(allPeople.count)")
    }
    
    private func forceCleanupDuplicates() {
        // Reset the UserDefaults flag to force merger to run again
        UserDefaults.standard.removeObject(forKey: "didRunDuplicateMerge_v3")
        DuplicateContactMerger.runIfNeeded(in: modelContext)
        debugPrintDuplicates()
    }
}

// MARK: - Preview

#Preview {
    RootView()
        .modelContainer(.preview)
}
