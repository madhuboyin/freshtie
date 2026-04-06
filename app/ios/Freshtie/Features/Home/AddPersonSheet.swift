import SwiftUI
import SwiftData

/// Lightweight sheet for creating a person from a typed name.
/// Phase 3 will add a contacts picker alongside this flow.
struct AddPersonSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var displayName = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: AppSpacing.xl) {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Who are you talking to?")
                        .font(AppTypography.title3)
                        .foregroundStyle(AppColors.label)

                    TextField("Name", text: $displayName)
                        .font(AppTypography.body)
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.vertical, AppSpacing.sm + AppSpacing.xs)
                        .background(AppColors.secondaryBackground)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                        .focused($isFocused)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.words)
                        .submitLabel(.done)
                        .onSubmit(save)
                }

                Spacer()
            }
            .padding(AppSpacing.md)
            .navigationTitle("New Person")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(AppColors.secondaryLabel)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add") { save() }
                        .font(AppTypography.headline)
                        .disabled(trimmedName.isEmpty)
                }
            }
            .onAppear { isFocused = true }
        }
    }

    private var trimmedName: String {
        displayName.trimmingCharacters(in: .whitespaces)
    }

    private func save() {
        guard !trimmedName.isEmpty else { return }
        let person = PersonRepository.createPerson(displayName: trimmedName, in: modelContext)
        AnalyticsService.shared.track(.manual_person_added, metadata: [AnalyticsMetadata.personID: person.id.uuidString])
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    AddPersonSheet()
        .modelContainer(.preview)
}
