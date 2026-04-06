import SwiftUI
import SwiftData

/// Entry point of the app. Calm, lightweight, immediate.
/// Shows a time-aware greeting, a search/pick row, and recent people.
struct HomeView: View {

    @Query private var allPeople: [Person]
    @State private var showAddPerson = false

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
        }
        .sheet(isPresented: $showAddPerson) {
            AddPersonSheet()
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
            showAddPerson = true
            // TODO: Phase 3 — present CNContactPickerViewController alongside manual entry
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
                showAddPerson = true
            } label: {
                Text("Add someone")
                    .font(AppTypography.callout)
                    .foregroundStyle(AppColors.accent)
            }
        }
        .frame(maxWidth: .infinity)
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
