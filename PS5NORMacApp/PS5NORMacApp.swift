import SwiftUI
import Firebase
import FirebaseAuth

@main
struct PS5NORMacApp: App {
    @StateObject private var settings = AppSettings()
    @StateObject private var auth = AuthManager()
    @StateObject var updater = Updater.shared
    @AppStorage("isDarkMode") private var isDarkMode: Bool = false
    @StateObject private var authManager = AuthManager()

    init() {
        FirebaseApp.configure()
        Auth.auth().useAppLanguage()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(isDarkMode ? .dark : .light)
                .environmentObject(settings)
                .environmentObject(auth)
                .environmentObject(updater)
        }

        WindowGroup("Settings") {
            SettingsView()
              .environmentObject(authManager)
              .environmentObject(AppSettings.shared)
                .environmentObject(settings)
        }
        .commands {
            CommandGroup(replacing: .appSettings) {
                Button("Settings…") {
                    NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }
    }
}
