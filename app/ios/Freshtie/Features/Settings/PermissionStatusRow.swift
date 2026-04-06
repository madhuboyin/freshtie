import SwiftUI

/// A settings list row showing the live status of a single system permission.
///
/// When the permission is denied or restricted, tapping opens the system
/// Settings app so the user can recover without being re-prompted in-app.
struct PermissionStatusRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let status: PermissionState

    var body: some View {
        Button {
            if status.isDenied { OpenSettingsButton.open() }
        } label: {
            HStack(spacing: AppSpacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 28, height: 28)
                    .background(iconColor)
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
    List {
        PermissionStatusRow(
            icon: "person.crop.circle", iconColor: .blue,
            title: "Contacts", status: .authorized
        )
        PermissionStatusRow(
            icon: "mic.fill", iconColor: .orange,
            title: "Microphone", status: .denied
        )
        PermissionStatusRow(
            icon: "waveform", iconColor: .purple,
            title: "Speech Recognition", status: .notDetermined
        )
    }
    .listStyle(.insetGrouped)
}
