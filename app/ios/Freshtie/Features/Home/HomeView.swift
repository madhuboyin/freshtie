import SwiftUI

/// Entry point of the app. Calm, lightweight, immediate.
/// Shows a time-aware greeting, a search/pick row, and recent people.
///
/// Phase 3 will replace `recentPeople` with a live PersonStore query.
struct HomeView: View {

    // TODO: Phase 2 — inject PersonStore; replace with @Query or @ObservedObject
    private let recentPeople = PreviewData.recentPeople

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
                    }
                }
                .padding(.bottom, AppSpacing.xxl)
            }
            .background(AppColors.background)
            .toolbar(.hidden, for: .navigationBar)
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
            // TODO: Phase 3 — present CNContactPickerViewController
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
}
