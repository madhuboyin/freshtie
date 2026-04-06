import SwiftUI
import Contacts

/// Minimal settings screen. Reflects live permission status and offers
/// recovery paths via system Settings when permissions are denied.
struct SettingsView: View {

    @Environment(\.modelContext) private var modelContext
    @State private var showValidationMenu = false

    @State private var contactStatus = ContactPermissionService.status
    @State private var micStatus     = MicrophonePermissionService.status
    @State private var speechStatus  = SpeechPermissionService.status

    private let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
    private let build   = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—"

    var body: some View {
        NavigationStack {
            List {
                // ── Access ───────────────────────────────────────────────────
                Section(
                    header: Text("Access"),
                    footer: Text("Permissions are only requested when you use a feature that needs them.")
                ) {
                    PermissionStatusRow(
                        icon: "person.crop.circle",
                        iconColor: .blue,
                        title: "Contacts",
                        status: contactStatus
                    )
                    PermissionStatusRow(
                        icon: "mic.fill",
                        iconColor: .orange,
                        title: "Microphone",
                        status: micStatus
                    )
                    PermissionStatusRow(
                        icon: "waveform",
                        iconColor: .purple,
                        title: "Speech Recognition",
                        status: speechStatus
                    )
                }

                // ── Tips ─────────────────────────────────────────────────────
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

                // ── Privacy ──────────────────────────────────────────────────
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

                // ── About ────────────────────────────────────────────────────
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
                    .contentShape(Rectangle())
                    .onLongPressGesture(minimumDuration: 2.0) {
                        showValidationMenu = true
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Settings")
            .sheet(isPresented: $showValidationMenu) {
                validationMenu
            }
            // Refresh permission labels whenever this screen appears or the
            // user returns from the system Settings app.
            .onAppear(perform: refreshStatuses)
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                refreshStatuses()
            }
        }
    }

    // MARK: - Helpers

    private func refreshStatuses() {
        contactStatus = ContactPermissionService.status
        micStatus     = MicrophonePermissionService.status
        speechStatus  = SpeechPermissionService.status
    }

    // MARK: - Validation menu (tester only, long-press on version row)

    private var validationMenu: some View {
        NavigationStack {
            List {
                Section("Tester Actions") {
                    Button("Reset Everything", role: .destructive) {
                        ValidationSupport.shared.resetEverything(modelContext: modelContext)
                        showValidationMenu = false
                    }
                    Button("Seed Rich Scenario") {
                        ValidationSupport.shared.seedRichScenario(modelContext: modelContext)
                        showValidationMenu = false
                    }
                }

                Section(header: Text("Recent Events"), footer: Text("Inspect local behavior for validation.")) {
                    ForEach(AnalyticsEventStore.shared.fetchRecent(limit: 10)) { event in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(event.eventName)
                                .font(AppTypography.caption)
                                .fontWeight(.bold)
                            Text(event.timestamp.formatted(date: .omitted, time: .shortened))
                                .font(.system(size: 10))
                                .foregroundStyle(AppColors.tertiaryLabel)
                        }
                    }
                }
            }
            .navigationTitle("Validation Support")
            .toolbar {
                Button("Done") { showValidationMenu = false }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
}
