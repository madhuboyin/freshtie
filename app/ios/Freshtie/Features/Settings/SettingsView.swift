import SwiftUI

/// Minimal settings shell. Permission rows are placeholders —
/// real permission logic arrives in Phase 10.
struct SettingsView: View {

    private let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
    private let build   = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—"

    var body: some View {
        NavigationStack {
            List {
                Section("Access") {
                    settingsRow(
                        icon: "person.crop.circle",
                        color: .blue,
                        title: "Contacts",
                        detail: "Not requested"
                    )
                    settingsRow(
                        icon: "bell",
                        color: .red,
                        title: "Notifications",
                        detail: "Not requested"
                    )
                }

                Section("About") {
                    settingsRow(
                        icon: "info.circle",
                        color: Color(.systemGray),
                        title: "Version",
                        detail: "\(version) (\(build))"
                    )
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Settings")
        }
    }

    // MARK: - Row builder

    private func settingsRow(icon: String, color: Color, title: String, detail: String) -> some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(color)
                .clipShape(RoundedRectangle(cornerRadius: 6))

            Text(title)
                .font(AppTypography.body)

            Spacer()

            Text(detail)
                .font(AppTypography.subheadline)
                .foregroundStyle(AppColors.tertiaryLabel)
        }
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
}
