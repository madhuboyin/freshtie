import SwiftUI
import SwiftData
import Contacts

/// Entry point of the app. Calm, lightweight, immediate.
/// Shows a time-aware greeting, a search/pick row, and recent people.
struct HomeView: View {

    @Environment(\.modelContext) private var modelContext
    @Query private var allPeople: [Person]

    // Sheet state
    @State private var showAddPerson = false
    @State private var showContactPicker = false
    @State private var showContactDenied = false
    @State private var showPickerOptions = false

    // Programmatic navigation after a contact is picked.
    // Set via onChange after the picker sheet fully dismisses.
    @State private var navigateToPerson: Person? = nil
    @State private var pendingPerson: Person? = nil

    private var recentPeople: [Person] {
        PersonRepository.sortedForHome(allPeople)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    headerSection
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.top, AppSpacing.lg)

                    searchSection
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.top, AppSpacing.xl)

                    if !recentPeople.isEmpty {
                        recentSection
                            .padding(.top, AppSpacing.xl)
                    } else {
                        emptyState
                            .padding(.top, AppSpacing.xxl)
                    }
                }
                .padding(.bottom, AppSpacing.xxl)
            }
            .background(AppColors.background)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(item: $navigateToPerson) { person in
                PersonView(person: person)
            }
        }
        // Options: pick from contacts or add manually
        .confirmationDialog("Add someone", isPresented: $showPickerOptions) {
            Button("Pick from Contacts") { handlePickFromContacts() }
            Button("Add Manually") { showAddPerson = true }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $showAddPerson) {
            AddPersonSheet()
        }
        .sheet(isPresented: $showContactPicker) {
            ContactPickerRepresentable(
                onSelect: { contact in
                    pendingPerson = ContactMapper.findOrCreate(contact: contact, in: modelContext)
                    showContactPicker = false
                },
                onCancel: {
                    showContactPicker = false
                }
            )
            .ignoresSafeArea()
        }
        .sheet(isPresented: $showContactDenied) {
            ContactDeniedView {
                showAddPerson = true
            }
        }
        // Navigate after the picker sheet finishes dismissing.
        .onChange(of: showContactPicker) { _, isShowing in
            guard !isShowing, let person = pendingPerson else { return }
            pendingPerson = nil
            navigateToPerson = person
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(greetingText)
                .font(AppTypography.largeTitle)
                .foregroundStyle(AppColors.label)

            Text("Who are you talking to?")
                .font(AppTypography.callout)
                .foregroundStyle(AppColors.secondaryLabel)
        }
    }

    private var searchSection: some View {
        SearchSelectRow {
            showPickerOptions = true
        }
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            SectionHeader("Recent")
                .padding(.horizontal, AppSpacing.md)

            personList
        }
    }

    private var personList: some View {
        VStack(spacing: 0) {
            ForEach(Array(recentPeople.enumerated()), id: \.element.id) { index, person in
                NavigationLink(destination: PersonView(person: person)) {
                    PersonRow(person: person)
                }
                .buttonStyle(.plain)

                if index < recentPeople.count - 1 {
                    Divider()
                        .padding(.leading, AppSpacing.md + AppSize.avatarMD + AppSpacing.md)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: "person.2")
                .font(.system(size: 40))
                .foregroundStyle(AppColors.tertiaryLabel)

            Text("No recent people yet")
                .font(AppTypography.subheadline)
                .foregroundStyle(AppColors.secondaryLabel)

            Button {
                showPickerOptions = true
            } label: {
                Text("Add someone")
                    .font(AppTypography.callout)
                    .foregroundStyle(AppColors.accent)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Contacts flow

    private func handlePickFromContacts() {
        Task {
            switch ContactPermissionService.status {
            case .authorized:
                showContactPicker = true
            case .notDetermined:
                let granted = await ContactPermissionService.requestAccess()
                if granted {
                    showContactPicker = true
                } else {
                    showContactDenied = true
                }
            case .denied, .restricted:
                showContactDenied = true
            @unknown default:
                // Treat any future limited-access states as accessible.
                showContactPicker = true
            }
        }
    }

    // MARK: - Helpers

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0 ..< 12: return "Good morning."
        case 12 ..< 17: return "Good afternoon."
        default:        return "Good evening."
        }
    }
}

// MARK: - Preview

#Preview {
    HomeView()
        .modelContainer(.preview)
}
