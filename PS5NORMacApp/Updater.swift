import Foundation
import FirebaseRemoteConfig
import AppKit
import Firebase


class UpdateChecker: ObservableObject {
    private let remoteConfig = RemoteConfig.remoteConfig()
    
    @Published var latestVersion: String = ""
    @Published var releaseNotes: String = ""
    @Published var forceUpdate: Bool = false
    @Published var updateAvailable: Bool = false
    @Published var showPatchNotes: Bool = false
    
    func checkForUpdate(currentVersion: String) {
        print("📡 Checking for updates...")
        
        // Debug check to ensure Firebase is configured
        print("🧪 Firebase Apps: \(FirebaseApp.allApps ?? [:])")
        
        remoteConfig.fetchAndActivate { [weak self] status, error in
            guard let self = self else { return }
            
            if let error = error {
                print("❌ RemoteConfig fetch error: \(error.localizedDescription)")
                return
            }
            
            self.latestVersion = self.remoteConfig["latest_version"].stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            self.releaseNotes = self.remoteConfig["release_notes"].stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            self.forceUpdate = self.remoteConfig["force_update"].boolValue
            
            print("✅ RemoteConfig fetch succeeded.")
            print("📦 Latest Version: \(self.latestVersion)")
            print("📝 Release Notes: \(self.releaseNotes)")
            print("🔒 Force Update: \(self.forceUpdate)")
            
            self.updateAvailable = self.latestVersion.compare(currentVersion, options: .numeric) == .orderedDescending
            
            if self.updateAvailable {
                print("🚀 Update available. Showing patch notes.")
                DispatchQueue.main.async {
                    self.showPatchNotes = true
                }
            } else {
                print("✅ App is up to date.")
            }
        }
    }
}
