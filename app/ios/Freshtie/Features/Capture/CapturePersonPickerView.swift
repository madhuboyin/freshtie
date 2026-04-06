import SwiftUI
import SwiftData
import Contacts

/// Entry view for the Capture tab.
///
/// Presents a list of recent people. Selecting one pushes directly into
/// CaptureView with that person pre-loaded, enabling the note-save flow
/// without leaving the tab. The "+" toolbar button allows adding someone
/// new — either from Contacts or by typing a name.
struct CapturePersonPickerView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allPeople: [Person]

    @State private var showPickerOptions = false
    @State private var showAddPerson = false
    @State private var showContactPicker = false
    @State private var showContactDenied = false
    @State private var navigateToCapturePerson: Person? = nil
    @State private var pendingPerson: Person? = nil

    private var recentPeople: [Person] {
        PersonRepository.sortedForHome(allPeople)
    }

    var body: some View {
        NavigationStack {
            Group {
                if recentPeople.isEmpty {
                    emptyState
                } else {
                    personList
                }
            }
            .background(AppColors.background)
            .navigationTitle("Capture")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showPickerOptions = true
                    } label: {
                        Image(systemName: "plus")
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(AppColors.accent)
                }
            }
            .navigationDestination(item: $navigateToCapturePerson) { person in
                CaptureView(person: person)
            }
        }
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
        .onChange(of: showContactPicker) { _, isShowing in
            guard !isShowing, let person = pendingPerson else { return }
            pendingPerson = nil
            navigateToCapturePerson = person
        }
    }

    // MARK: - Views

    private var personList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("Who are you about to talk to?")
                    .font(AppTypography.callout)
                    .foregroundStyle(AppColors.secondaryLabel)
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.top, AppSpacing.md)
                    .padding(.bottom, AppSpacing.lg)

                VStack(spacing: 0) {
                    ForEach(Array(recentPeople.enumerated()), id: \.element.id) { index, person in
                        NavigationLink(destination: CaptureView(person: person)) {
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
            .padding(.bottom, AppSpacing.xxl)
        }
    }

    private var emptyState: some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: "person.2")
                .font(.system(size: 40))
                .foregroundStyle(AppColors.tertiaryLabel)

            Text("No people yet")
                .font(AppTypography.subheadline)
                .foregroundStyle(AppColors.secondaryLabel)

            Button("Add someone") { showPickerOptions = true }
                .font(AppTypography.callout)
                .foregroundStyle(AppColors.accent)
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
                showContactPicker = true
            }
        }
    }
}

// MARK: - Preview

#Preview {
    CapturePersonPickerView()
        .modelContainer(.preview)
}
