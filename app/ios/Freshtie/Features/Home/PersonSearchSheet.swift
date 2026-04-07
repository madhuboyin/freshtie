import SwiftUI
import SwiftData

/// Sheet presented when the user taps "Search or pick someone" on Home.
///
/// Priority order:
///   1. Existing local people — live-filtered as the user types
///   2. "Pick from Contacts" and "Add Manually" — always visible as secondary actions
///
/// If no local people exist, skips the list and shows the add actions prominently.
struct PersonSearchSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Person.lastOpenedAt, order: .reverse) private var allPeople: [Person]

    let onSelectPerson: (Person) -> Void
    let onPickFromContacts: () -> Void
    let onAddManually: () -> Void

    @State private var searchText = ""

    private var filteredPeople: [Person] {
        guard !searchText.isEmpty else { return allPeople }
        return allPeople.filter {
            $0.displayName.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            searchField
                .padding(.horizontal, AppSpacing.md)
                .padding(.top, AppSpacing.md)
                .padding(.bottom, AppSpacing.sm)

            Divider()

            ScrollView {
                VStack(spacing: 0) {
                    if allPeople.isEmpty {
                        emptyPeopleState
                    } else if filteredPeople.isEmpty {
                        noMatchState
                    } else {
                        peopleList
                    }

                    addActionsSection
                        .padding(.top, allPeople.isEmpty ? AppSpacing.lg : AppSpacing.xl)
                }
                .padding(.bottom, AppSpacing.xxl)
            }
        }
        .background(AppColors.background)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Search field

    private var searchField: some View {
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
        .frame(height: AppSize.minTapTarget)
        .background(AppColors.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
    }

    // MARK: - People list

    private var peopleList: some View {
        VStack(spacing: 0) {
            ForEach(Array(filteredPeople.enumerated()), id: \.element.id) { index, person in
                Button {
                    dismiss()
                    onSelectPerson(person)
                } label: {
                    PersonRow(person: person)
                }
                .buttonStyle(.plain)

                if index < filteredPeople.count - 1 {
                    Divider()
                        .padding(.leading, AppSpacing.md + AppSize.avatarMD + AppSpacing.md)
                }
            }
        }
        .background(AppColors.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
        .padding(.horizontal, AppSpacing.md)
        .padding(.top, AppSpacing.md)
    }

    // MARK: - Empty / no-match states

    private var emptyPeopleState: some View {
        VStack(spacing: AppSpacing.sm) {
            Image(systemName: "person.2")
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(AppColors.tertiaryLabel)
                .padding(.top, AppSpacing.xxl)

            Text("No people yet")
                .font(AppTypography.subheadline)
                .foregroundStyle(AppColors.secondaryLabel)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, AppSpacing.sm)
    }

    private var noMatchState: some View {
        Text("No match for \"\(searchText)\"")
            .font(AppTypography.subheadline)
            .foregroundStyle(AppColors.secondaryLabel)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.top, AppSpacing.xxl)
            .padding(.bottom, AppSpacing.sm)
    }

    // MARK: - Add actions

    private var addActionsSection: some View {
        VStack(spacing: 0) {
            Button {
                dismiss()
                onPickFromContacts()
            } label: {
                addActionRow(
                    icon: "person.crop.circle.badge.plus",
                    label: "Pick from Contacts"
                )
            }
            .buttonStyle(.plain)

            Divider()
                .padding(.leading, AppSpacing.md + 28 + AppSpacing.sm)

            Button {
                dismiss()
                onAddManually()
            } label: {
                addActionRow(
                    icon: "square.and.pencil",
                    label: "Add Manually"
                )
            }
            .buttonStyle(.plain)
        }
        .background(AppColors.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
        .padding(.horizontal, AppSpacing.md)
    }

    private func addActionRow(icon: String, label: String) -> some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 17))
                .foregroundStyle(AppColors.accent)
                .frame(width: 28)

            Text(label)
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
}

// MARK: - Preview

#Preview("With people") {
    Text("Home")
        .sheet(isPresented: .constant(true)) {
            PersonSearchSheet(
                onSelectPerson: { _ in },
                onPickFromContacts: {},
                onAddManually: {}
            )
        }
        .modelContainer(.preview)
}

#Preview("Empty") {
    Text("Home")
        .sheet(isPresented: .constant(true)) {
            PersonSearchSheet(
                onSelectPerson: { _ in },
                onPickFromContacts: {},
                onAddManually: {}
            )
        }
        .modelContainer(try! ModelContainer(
            for: Person.self, Note.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        ))
}
