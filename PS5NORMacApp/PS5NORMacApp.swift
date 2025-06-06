import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseCore

@main
struct PS5NORMacApp: App {
    @StateObject private var settings = AppSettings()
    @StateObject private var auth = AuthManager()
    @StateObject var updater = Updater.shared
    @AppStorage("isDarkMode") private var isDarkMode: Bool = false
    @StateObject private var authManager = AuthManager()
    @State private var selectedBinFile: URL? = nil
    init() {
        setupFirebase()
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
            SettingsView(selectedBinFile: $selectedBinFile)
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
    
    private func setupFirebase() {
        if let data = PlistDecryptor.decryptedPlistData() {
            let tempPlistURL = FileManager.default.temporaryDirectory.appendingPathComponent("GoogleService-Info.plist")
            do {
                try data.write(to: tempPlistURL)
                if let options = FirebaseOptions(contentsOfFile: tempPlistURL.path) {
                    FirebaseApp.configure(options: options)
                    print("✅ Firebase configured successfully")
                } else {
                    print("❌ Could not create FirebaseOptions")
                }
            } catch {
                print("❌ Failed to write decrypted plist: \(error)")
            }
        } else {
            print("❌ Could not decrypt plist")
        }
    }
}
