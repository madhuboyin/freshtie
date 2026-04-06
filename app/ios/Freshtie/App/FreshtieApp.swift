import SwiftUI
import SwiftData

@main
struct FreshtieApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(.freshtie)
    }
}
