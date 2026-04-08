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
    @Query(sort: \Person.lastOpenedAt, order: .reverse) private var allPeople: [Person]

    @State private var showAddPerson      = false
    @State private var showContactPicker  = false
    @State private var showContactDenied  = false
    @State private var showPickerOptions  = false

    /// Inline search state — activates when the user taps the search row.
    @State private var isSearching  = false
    @State private var searchText   = ""

    /// Set by the contact picker callback; cleared after navigation fires.
    @State private var pendingPerson: Person?     = nil
    @State private var navigateToPerson: Person?  = nil

    /// Pinned first, then most recently opened. Capped at 6 in browse mode;
    /// uncapped and filtered by searchText while searching.
    private var recentPeople: [Person] {
        Array(allPeople.prefix(6))
    }

    private var searchResults: [Person] {
        guard !searchText.isEmpty else { return allPeople }
        return allPeople.filter {
            $0.displayName.localizedCaseInsensitiveContains(searchText)
        }
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
                        .animation(.easeInOut(duration: 0.2), value: isSearching)

                    if isSearching {
                        searchResultsSection
                            .padding(.top, AppSpacing.lg)
                    } else if recentPeople.isEmpty {
                        emptyState
                            .padding(.top, AppSpacing.xxl)
                    } else {
                        recentSection
                            .padding(.top, AppSpacing.lg)
                    }

                    if !isSearching {
                        discoverabilityTip
                            .padding(.horizontal, AppSpacing.md)
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
        .onAppear {
            handleSharedPayloads()
            Task { await detectionService.performDetection(modelContext: modelContext) }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            handleSharedPayloads()
            Task { await detectionService.performDetection(modelContext: modelContext) }
        }
        .confirmationDialog("Add someone", isPresented: $showPickerOptions) {
            Button("Pick from Contacts") { handlePickFromContacts() }
            Button("Add Manually")       { showAddPerson = true }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $showAddPerson) {
            AddPersonSheet()
        }
        .sheet(isPresented: $showContactPicker) {
            ContactPickerRepresentable(
                onSelect: { contact in
                    let person = ContactMapper.findOrCreate(contact: contact, in: modelContext)
                    AnalyticsService.shared.track(.contact_person_selected, metadata: [AnalyticsMetadata.personID: person.id.uuidString])
                    pendingPerson = person
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
                    AnalyticsService.shared.track(.contact_trigger_accepted, metadata: [AnalyticsMetadata.personID: trigger.contact.identifier])
                    let person = ContactMapper.findOrCreate(contact: trigger.contact, in: modelContext)
                    detectionService.dismissTrigger() // Clear it
                    navigateToPerson = person
                    showAddPerson = false // Just in case
                }
                .font(AppTypography.callout)
                .fontWeight(.bold)
                .foregroundStyle(AppColors.accent)
                
                Button("Not now") {
                    AnalyticsService.shared.track(.contact_trigger_dismissed, metadata: [AnalyticsMetadata.personID: trigger.contact.identifier])
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
        .onAppear {
            AnalyticsService.shared.track(.contact_trigger_shown, metadata: [AnalyticsMetadata.personID: trigger.contact.identifier])
        }
    }

    /// Primary question (dominant).
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xxs) {
            Text("Who are you talking to?")
                .font(AppTypography.title2)
                .foregroundStyle(AppColors.label)
        }
    }

    /// Primary entry control.
    /// - Browse mode: a tappable row that activates inline search.
    /// - Search mode: a live text field with a Cancel button.
    @ViewBuilder
    private var searchSection: some View {
        if isSearching {
            HStack(spacing: AppSpacing.sm) {
                HStack(spacing: AppSpacing.sm) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(AppColors.secondaryLabel)

                    TextField("Search", text: $searchText)
                        .font(AppTypography.body)
                        .autocorrectionDisabled()

                    if !searchText.isEmpty {
                        Button { searchText = "" } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(AppColors.tertiaryLabel)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, AppSpacing.md)
                .frame(height: AppSize.minTapTarget + AppSpacing.md)
                .background(AppColors.secondaryBackground)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                .overlay {
                    RoundedRectangle(cornerRadius: AppRadius.md)
                        .strokeBorder(AppColors.separator.opacity(0.5), lineWidth: 0.5)
                }

                Button("Cancel") {
                    isSearching = false
                    searchText  = ""
                }
                .font(AppTypography.body)
                .foregroundStyle(AppColors.accent)
            }
        } else {
            SearchSelectRow {
                if allPeople.isEmpty {
                    showPickerOptions = true
                } else {
                    isSearching = true
                }
            }
        }
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            SectionHeader("Recent")
                .padding(.horizontal, AppSpacing.md)

            personList(people: recentPeople)
        }
    }

    /// Shown while the inline search field is active.
    private var searchResultsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            if searchResults.isEmpty {
                Text("No match for \"\(searchText)\"")
                    .font(AppTypography.subheadline)
                    .foregroundStyle(AppColors.secondaryLabel)
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.top, AppSpacing.sm)
            } else {
                personList(people: searchResults)
            }

            // Add options — always accessible while searching
            addOptionsRow
                .padding(.top, AppSpacing.sm)
        }
    }

    /// Person rows grouped in an inset card — native iOS list feel.
    private func personList(people: [Person]) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(people.enumerated()), id: \.element.id) { index, person in
                NavigationLink(destination: PersonView(person: person)) {
                    PersonRow(person: person)
                }
                .buttonStyle(.plain)
                .simultaneousGesture(TapGesture().onEnded {
                    AnalyticsService.shared.track(.person_selected, metadata: [AnalyticsMetadata.personID: person.id.uuidString])
                })

                if index < people.count - 1 {
                    Divider()
                        .padding(.leading, AppSpacing.md + AppSize.avatarMD + AppSpacing.md)
                }
            }
        }
        .background(AppColors.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
        .padding(.horizontal, AppSpacing.md)
    }

    /// Secondary add-actions row — visible below search results.
    private var addOptionsRow: some View {
        VStack(spacing: 0) {
            Button {
                isSearching = false
                searchText  = ""
                handlePickFromContacts()
            } label: {
                addActionLabel(icon: "person.crop.circle.badge.plus", title: "Pick from Contacts")
            }
            .buttonStyle(.plain)

            Divider()
                .padding(.leading, AppSpacing.md + 28 + AppSpacing.sm)

            Button {
                isSearching = false
                searchText  = ""
                showAddPerson = true
            } label: {
                addActionLabel(icon: "square.and.pencil", title: "Add Manually")
            }
            .buttonStyle(.plain)
        }
        .background(AppColors.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
        .padding(.horizontal, AppSpacing.md)
    }

    private func addActionLabel(icon: String, title: String) -> some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 17))
                .foregroundStyle(AppColors.accent)
                .frame(width: 28)
            Text(title)
                .font(AppTypography.body)
                .foregroundStyle(AppColors.label)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AppColors.tertiaryLabel)
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm + AppSpacing.xs)
        .contentShape(Rectangle())
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
            case .authorized, .limited:
                showContactPicker = true
            case .notDetermined:
                AnalyticsService.shared.track(.contacts_permission_requested)
                let granted = await ContactPermissionService.requestAccess()
                AnalyticsService.shared.track(.contacts_permission_granted, metadata: [AnalyticsMetadata.status: String(granted)])
                if granted { showContactPicker = true } else { showContactDenied = true }
            case .denied, .restricted:
                showContactDenied = true
            }
        }
    }

    // MARK: - Helpers

    private func handleSharedPayloads() {
        print("📱 DEBUG: Checking for shared payloads...")
        let payloads = ShareExtensionStore.fetchAll()
        print("📱 DEBUG: Found \(payloads.count) shared payloads")
        guard !payloads.isEmpty else { 
            print("📱 DEBUG: No shared payloads to process")
            return 
        }

        for payload in payloads {
            print("📱 DEBUG: Processing shared contact: \(payload.displayName)")
            process(payload)
            AnalyticsService.shared.track(.share_extension_used)
        }

        ShareExtensionStore.clearAll()
        print("📱 DEBUG: Finished processing shared payloads")
    }

    private func process(_ payload: SharedPersonPayload) {
        print("📱 DEBUG: Processing payload for '\(payload.displayName)', contactID: \(payload.contactIdentifier ?? "none")")

        // 1. Find or create person — use ContactMapper when we have an identifier so
        //    deduplication is consistent with the contact-picker flow.
        let person: Person
        if let cid = payload.contactIdentifier {
            person = ContactMapper.findOrCreate(
                contactIdentifier: cid,
                displayName: payload.displayName,
                creationSource: .shareExtension,
                in: modelContext
            )
            print("📱 DEBUG: findOrCreate result: \(person.displayName)")
        } else {
            person = PersonRepository.createPerson(
                displayName: payload.displayName,
                contactIdentifier: nil,
                creationSource: .shareExtension,
                in: modelContext
            )
            print("📱 DEBUG: Created manual person: \(person.displayName)")
        }
        
        // 2. Add note if present
        if let noteText = payload.noteText {
            PersonRepository.addNote(
                rawText: noteText,
                sourceType: .manualText,
                to: person,
                in: modelContext
            )
            print("📱 DEBUG: Added text note to person: '\(noteText)'")
        }

        do {
            try modelContext.save()
            print("📱 DEBUG: Successfully saved person and notes to database")
        } catch {
            print("📱 DEBUG: Error saving to database: \(error)")
        }

        // If the user chose "Record in Freshtie", surface PersonView immediately
        // so the Capture CTA is one tap away.
        if payload.requiresCapture {
            navigateToPerson = person
        }
    }

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
