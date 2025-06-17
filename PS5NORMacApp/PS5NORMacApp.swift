import SwiftUI
import Firebase
import FirebaseCore
import FirebaseAuth
import UpdateKit

@main
struct PS5NORMacApp: App {
    @StateObject private var settings       = AppSettings()
    @StateObject private var auth           = AuthManager()
    @AppStorage("isDarkMode") private var isDarkMode: Bool = false
    @StateObject private var authManager    = AuthManager()
    @State private   var selectedBinFile: URL? = nil
    @StateObject private var updateManager = UpdateManager(repo: "TIDYBEATS1/PS5NorMacApp")

    // ↓ New UpdateKit properties ↓
    @State private var updateInfo: UpdateInfo?
    
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
                .environmentObject(updateManager)   // if you want to inject it
                .onAppear {
                    updateManager.checkForUpdates()
                }
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
            let tempPlistURL = FileManager.default
                .temporaryDirectory
                .appendingPathComponent("GoogleService-Info.plist")
            do {
                try data.write(to: tempPlistURL)
                if let options = FirebaseOptions(contentsOfFile: tempPlistURL.path) {
                    FirebaseApp.configure(options: options)
                    print("✅ Firebase configured successfully")
                } else {
                    print("❌ Could not create FirebaseOptions")
                }
            } catch {
                print("❌ Failed to write decrypted plist:", error)
            }
        } else {
            print("❌ Could not decrypt plist")
        }
    }
}
