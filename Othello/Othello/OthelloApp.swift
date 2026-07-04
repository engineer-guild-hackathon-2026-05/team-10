import FirebaseCore
import SwiftUI

/// テーマ設定。system は OS の外観設定に追従する。
enum ThemePreference: String {
    case system, light, dark

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    var next: ThemePreference {
        switch self {
        case .system: return .light
        case .light: return .dark
        case .dark: return .system
        }
    }

    var iconName: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }
}

@main
struct OthelloApp: App {
    @AppStorage("themePreference") var themePreference: ThemePreference = .system

    init() {
        FirebaseApp.configure()
        UITabBar.appearance().isHidden = true
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(themePreference.colorScheme)
        }
    }
}
