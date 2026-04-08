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
    @State private var showDuplicateAlert = false
    @State private var duplicateMessage = ""

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
        .alert("Duplicate Contacts Found", isPresented: $showDuplicateAlert) {
            Button("Force Clean") {
                forceCleanupDuplicates()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(duplicateMessage)
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
        
        // Group by displayName for manual entries (normalized)
        var byName: [String: [Person]] = [:]
        for person in allPeople {
            guard person.contactIdentifier == nil else { continue }
            let normalizedName = person.displayName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            byName[normalizedName, default: []].append(person)
        }
        
        // Also check for similar names across ALL people (with and without contact IDs)
        var bySimilarName: [String: [Person]] = [:]
        for person in allPeople {
            let normalizedName = person.displayName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            bySimilarName[normalizedName, default: []].append(person)
        }
        
        let duplicatesByIdentifier = byIdentifier.values.filter { $0.count > 1 }
        let duplicatesByName = byName.values.filter { $0.count > 1 }
        let duplicatesBySimilarName = bySimilarName.values.filter { $0.count > 1 }
        
        let totalDuplicateGroups = duplicatesByIdentifier.count + duplicatesByName.count
        
        if totalDuplicateGroups > 0 || !duplicatesBySimilarName.isEmpty {
            print("🔍 DUPLICATE CONTACTS FOUND:")
            
            var alertMessage = "Found duplicates:\n"
            
            for group in duplicatesByIdentifier {
                let contactId = group.first?.contactIdentifier ?? "nil"
                print("📱 Contact ID \(contactId): \(group.count) duplicates")
                alertMessage += "Contact ID: \(group.count) entries\n"
                for person in group {
                    print("  - \(person.displayName) (ID: \(person.id), created: \(person.createdAt), source: \(person.creationSource))")
                }
            }
            
            for group in duplicatesByName {
                let name = group.first?.displayName ?? "nil"
                print("👤 Manual name '\(name)': \(group.count) duplicates")
                alertMessage += "Manual '\(name)': \(group.count) entries\n"
                for person in group {
                    print("  - ID: \(person.id) (created: \(person.createdAt), source: \(person.creationSource))")
                }
            }
            
            print("🔍 SIMILAR NAMES (potential duplicates):")
            for group in duplicatesBySimilarName {
                let normalizedName = group.first?.displayName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) ?? "nil"
                if group.count > 1 {
                    print("👥 Similar name '\(normalizedName)': \(group.count) people")
                    for person in group {
                        let contactInfo = person.contactIdentifier != nil ? "Contact ID: \(person.contactIdentifier!)" : "Manual"
                        print("  - '\(person.displayName)' (ID: \(person.id), source: \(person.creationSource), \(contactInfo))")
                    }
                }
            }
            
            duplicateMessage = alertMessage
            showDuplicateAlert = true
            
        } else {
            print("✅ No duplicate contacts found")
        }
        
        print("📊 Total people: \(allPeople.count)")
    }
    
    private func forceCleanupDuplicates() {
        // Reset the UserDefaults flag to force merger to run again
        UserDefaults.standard.removeObject(forKey: "didRunDuplicateMerge_v4")
        DuplicateContactMerger.runIfNeeded(in: modelContext)
        debugPrintDuplicates()
    }
}

// MARK: - Preview

#Preview {
    RootView()
        .modelContainer(.preview)
}
