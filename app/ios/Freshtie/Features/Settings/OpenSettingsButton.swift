import SwiftUI

/// Opens the app's entry in the system Settings app.
///
/// Use only where it provides a clear recovery path from a denied permission —
/// not as a general navigation affordance.
struct OpenSettingsButton: View {
    var label: String = "Open Settings"

    var body: some View {
        Button(label) {
            Self.open()
        }
    }

    /// Imperatively opens app Settings. Callable without a view context.
    static func open() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}
