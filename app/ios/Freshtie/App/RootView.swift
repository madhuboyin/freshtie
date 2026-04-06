import SwiftUI

/// Top-level tab container.
///
/// Navigation model:
///   Home tab     — NavigationStack; pushes PersonView on person selection.
///   Capture tab  — Full-screen CaptureView (no sheet dismiss button needed).
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

            CaptureView()
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
}
