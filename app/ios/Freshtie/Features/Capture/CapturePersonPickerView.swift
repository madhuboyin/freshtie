import SwiftUI
import SwiftData

/// Entry view for the Capture tab.
///
/// Presents a list of recent people. Selecting one pushes directly into
/// CaptureView with that person pre-loaded, enabling the note-save flow
/// without leaving the tab.
struct CapturePersonPickerView: View {
    @Query private var allPeople: [Person]
    @State private var showAddPerson = false

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
                        showAddPerson = true
                    } label: {
                        Image(systemName: "plus")
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(AppColors.accent)
                }
            }
        }
        .sheet(isPresented: $showAddPerson) {
            AddPersonSheet()
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

            Button("Add someone") { showAddPerson = true }
                .font(AppTypography.callout)
                .foregroundStyle(AppColors.accent)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

#Preview {
    CapturePersonPickerView()
        .modelContainer(.preview)
}
