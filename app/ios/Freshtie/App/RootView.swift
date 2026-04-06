import SwiftUI

/// Top-level tab container.
///
/// Navigation model:
///   Home tab     — NavigationStack; pushes PersonView on person selection.
///   Capture tab  — CapturePersonPickerView; selects a person then pushes CaptureView.
///   Settings tab — NavigationStack; placeholder rows only.
///
/// PersonView also presents CaptureView as a sheet via its own @State.
struct RootView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }

            CapturePersonPickerView()
                .tabItem {
                    Label("Capture", systemImage: "waveform")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
        .tint(AppColors.accent)
    }
}

// MARK: - Preview

#Preview {
    RootView()
        .modelContainer(.preview)
}
