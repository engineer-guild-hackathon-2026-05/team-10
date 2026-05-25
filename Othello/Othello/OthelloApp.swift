import FirebaseCore
import SwiftUI

@main
struct OthelloApp: App {
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
