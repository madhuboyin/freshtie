import SwiftUI
import Contacts

/// Minimal settings shell. Reflects live authorization status for core features.
/// Allows recovery via System Settings when permissions are denied.
struct SettingsView: View {

    @State private var contactStatus = ContactPermissionService.status
    @State private var micStatus = MicrophonePermissionService.status
    @State private var speechStatus = SpeechPermissionService.status

    private let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
    private let build   = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—"

    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Access"), footer: Text("Permissions are only requested when you use a feature that needs them.")) {
                    settingsRow(
                        icon: "person.crop.circle",
                        color: .blue,
                        title: "Contacts",
                        status: contactStatus
                    )
                    
                    settingsRow(
                        icon: "mic.fill",
                        color: .orange,
                        title: "Microphone",
                        status: micStatus
                    )
                    
                    settingsRow(
                        icon: "waveform",
                        color: .purple,
                        title: "Speech Recognition",
                        status: speechStatus
                    )
                }

                Section("Tips") {
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text("Share from Contacts")
                            .font(AppTypography.body)
                        Text("You can also add people directly to Freshtie by sharing a contact from the iOS Contacts app.")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.secondaryLabel)
                    }
                    .padding(.vertical, AppSpacing.xxs)
                }

                Section("Privacy") {
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text("Your data stays on your device.")
                            .font(AppTypography.body)
                        Text("Freshtie does not upload your contacts or notes to any server.")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.secondaryLabel)
                    }
                    .padding(.vertical, AppSpacing.xxs)
                }

                Section("About") {
                    HStack {
                        Label {
                            Text("Version")
                                .font(AppTypography.body)
                        } icon: {
                            Image(systemName: "info.circle")
                                .foregroundStyle(Color(.systemGray))
                        }
                        Spacer()
                        Text("\(version) (\(build))")
                            .font(AppTypography.subheadline)
                            .foregroundStyle(AppColors.tertiaryLabel)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Settings")
            .onAppear(perform: refreshStatuses)
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                refreshStatuses()
            }
        }
    }

    // MARK: - Helpers

    private func refreshStatuses() {
        contactStatus = ContactPermissionService.status
        micStatus = MicrophonePermissionService.status
        speechStatus = SpeechPermissionService.status
    }

    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    // MARK: - Row builder

    private func settingsRow(icon: String, color: Color, title: String, status: PermissionState) -> some View {
        Button {
            if status.isDenied { openSettings() }
        } label: {
            HStack(spacing: AppSpacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 28, height: 28)
                    .background(color)
                    .clipShape(RoundedRectangle(cornerRadius: 6))

                Text(title)
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.label)

                Spacer()

                Text(status.label)
                    .font(AppTypography.subheadline)
                    .foregroundStyle(status.isDenied ? AppColors.accent : AppColors.tertiaryLabel)
                
                if status.isDenied {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(AppColors.tertiaryLabel)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
}
