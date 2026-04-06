import SwiftUI

/// Shown when contacts permission is denied or restricted.
///
/// Gives the user two calm exits:
///   • Open Settings — to grant access and retry from the picker.
///   • Add name manually — falls back to the typed-entry flow.
struct ContactDeniedView: View {
    /// Called when the user chooses to add a person without contacts access.
    let onAddManually: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    var body: some View {
        NavigationStack {
            VStack(spacing: AppSpacing.xl) {
                Spacer()

                Image(systemName: "person.crop.circle.badge.exclamationmark")
                    .font(.system(size: 52))
                    .foregroundStyle(AppColors.tertiaryLabel)

                VStack(spacing: AppSpacing.sm) {
                    Text("Contacts access needed")
                        .font(AppTypography.title3)
                        .foregroundStyle(AppColors.label)
                        .multilineTextAlignment(.center)

                    Text("Allow access in Settings to pick from your contacts,\nor add a name directly.")
                        .font(AppTypography.body)
                        .foregroundStyle(AppColors.secondaryLabel)
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: AppSpacing.sm) {
                    Button {
                        if let url = URL(string: "app-settings:") {
                            openURL(url)
                        }
                    } label: {
                        Text("Open Settings")
                            .font(AppTypography.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppSpacing.md)
                            .background(AppColors.accent)
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                    }

                    Button {
                        dismiss()
                        onAddManually()
                    } label: {
                        Text("Add name manually")
                            .font(AppTypography.callout)
                            .foregroundStyle(AppColors.accent)
                            .padding(.vertical, AppSpacing.sm)
                    }
                }

                Spacer()
            }
            .padding(.horizontal, AppSpacing.xl)
            .background(AppColors.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(AppColors.secondaryLabel)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ContactDeniedView(onAddManually: {})
}
