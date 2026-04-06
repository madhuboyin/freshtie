import SwiftUI
import SwiftData
import Contacts

/// Entry point of the app — value-first, friction-free.
///
/// Layout (top → bottom):
///   Greeting (quiet context) → Primary question (dominant copy)
///   → Search/pick control → Recent people (capped at 6) or empty state
///
/// The Home screen is an entry point, not a destination.
/// Product value lives on the Person screen — get there in ≤ 2 taps.
struct HomeView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(ContactDetectionService.self) private var detectionService
    @Query private var allPeople: [Person]

    @State private var showAddPerson     = false
    @State private var showContactPicker = false
    @State private var showContactDenied = false
    @State private var showPickerOptions = false

    /// Set by the contact picker callback; cleared after navigation fires.
    @State private var pendingPerson: Person?     = nil
    @State private var navigateToPerson: Person?  = nil

    /// Pinned first, then most recently opened. Capped at 6 so Home
    /// stays lightweight — it's a quick-pick list, not a full directory.
    private var recentPeople: [Person] {
        Array(PersonRepository.sortedForHome(allPeople).prefix(6))
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if let trigger = detectionService.activeTrigger {
                        triggerBanner(trigger)
                            .padding(.horizontal, AppSpacing.md)
                            .padding(.top, AppSpacing.md)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    headerSection
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.top, AppSpacing.lg)

                    searchSection
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.top, AppSpacing.lg)

                    if recentPeople.isEmpty {
                        emptyState
                            .padding(.top, AppSpacing.xxl)
                    } else {
                        recentSection
                            .padding(.top, AppSpacing.lg)
                    }

                    discoverabilityTip
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.top, AppSpacing.xxl)
                }
                .padding(.bottom, AppSpacing.xxl)
            }
            .background(AppColors.background)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(item: $navigateToPerson) { person in
                PersonView(person: person)
            }
        }
        // Person picker options
        .confirmationDialog("Add someone", isPresented: $showPickerOptions) {
            Button("Pick from Contacts") { handlePickFromContacts() }
            Button("Add Manually")        { showAddPerson = true      }
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
                onCancel: { showContactPicker = false }
            )
            .ignoresSafeArea()
        }
        .sheet(isPresented: $showContactDenied) {
            ContactDeniedView { showAddPerson = true }
        }
        // Navigate only after the sheet dismiss animation completes.
        .onChange(of: showContactPicker) { _, isShowing in
            guard !isShowing, let person = pendingPerson else { return }
            pendingPerson = nil
            navigateToPerson = person
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private func triggerBanner(_ trigger: ContactDetectionService.CandidateTrigger) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack(alignment: .top, spacing: AppSpacing.sm) {
                Image(systemName: "sparkles")
                    .foregroundStyle(AppColors.accent)
                    .font(.system(size: 18, weight: .semibold))
                
                Text(trigger.message)
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.label)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            HStack(spacing: AppSpacing.md) {
                Button("Add") {
                    let person = ContactMapper.findOrCreate(contact: trigger.contact, in: modelContext)
                    detectionService.dismissTrigger() // Clear it
                    navigateToPerson = person
                    showAddPerson = false // Just in case
                }
                .font(AppTypography.callout)
                .fontWeight(.bold)
                .foregroundStyle(AppColors.accent)
                
                Button("Not now") {
                    withAnimation {
                        detectionService.dismissTrigger()
                    }
                }
                .font(AppTypography.callout)
                .foregroundStyle(AppColors.secondaryLabel)
            }
            .padding(.leading, 26) // Align with text start
        }
        .padding(AppSpacing.md)
        .background(AppColors.accent.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
    }

    /// Greeting line (quiet, temporal) + primary product question (dominant).
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xxs) {
            Text(greetingText)
                .font(AppTypography.subheadline)
                .foregroundStyle(AppColors.tertiaryLabel)

            Text("Who are you talking to?")
                .font(AppTypography.title2)
                .foregroundStyle(AppColors.label)
        }
    }

    /// Primary entry control — the most important tap on this screen.
    private var searchSection: some View {
        SearchSelectRow { showPickerOptions = true }
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            SectionHeader("Recent")
                .padding(.horizontal, AppSpacing.md)

            personList
        }
    }

    /// Person rows grouped in an inset card — native iOS list feel.
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
        .background(AppColors.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
        .padding(.horizontal, AppSpacing.md)
    }

    private var emptyState: some View {
        HomeEmptyState { showPickerOptions = true }
    }

    private var discoverabilityTip: some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: "lightbulb.fill")
                .foregroundStyle(AppColors.accent)
                .font(.system(size: 20))

            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text("Did you know?")
                    .font(AppTypography.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(AppColors.label)

                Text("You can also share a contact directly to Freshtie from your Contacts app.")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.secondaryLabel)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(AppSpacing.md)
        .background(AppColors.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
    }

    // MARK: - Contacts flow

    private func handlePickFromContacts() {
        Task {
            switch ContactPermissionService.status {
            case .authorized:
                showContactPicker = true
            case .notDetermined:
                let granted = await ContactPermissionService.requestAccess()
                if granted { showContactPicker = true } else { showContactDenied = true }
            case .denied, .restricted:
                showContactDenied = true
            @unknown default:
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

#Preview("With people") {
    HomeView()
        .modelContainer(.preview)
}

#Preview("Empty") {
    HomeView()
        .modelContainer(try! ModelContainer(
            for: Person.self, Note.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        ))
}
