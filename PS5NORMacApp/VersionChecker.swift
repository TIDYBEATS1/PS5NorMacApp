import Foundation
import FirebaseRemoteConfig
import Firebase

class VersionChecker: ObservableObject {
    private let remoteConfig = RemoteConfig.remoteConfig()

    @Published var latestVersion: String = ""
    @Published var releaseNotes: String = ""
    @Published var forceUpdate: Bool = false
    @Published var updateAvailable: Bool = false

    func fetchRemoteConfig() {
        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = 0
        remoteConfig.configSettings = settings

        remoteConfig.fetchAndActivate { [weak self] status, error in
            guard let self = self else { return }

            if let error = error {
                print("❌ RemoteConfig error: \(error)")
                return
            }

            self.latestVersion = self.remoteConfig["latest_version"].stringValue ?? "Unavailable"
            self.releaseNotes = self.remoteConfig["release_notes"].stringValue ?? "No release notes"
            self.forceUpdate = self.remoteConfig["force_update"].boolValue ?? false

            let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"

            if self.latestVersion.compare(currentVersion, options: .numeric) == .orderedDescending {
                DispatchQueue.main.async {
                    self.updateAvailable = true
                }
            }
        }
    }

    func downloadAndInstallUpdate() {
        guard let url = URL(string: "https://github.com/TIDYBEATS1/PS5NorMacApp/releases/download/4.6.0/PS5NORMacApp.zip") else { return }

        let task = URLSession.shared.downloadTask(with: url) { tempURL, _, error in
            guard let tempURL = tempURL, error == nil else {
                print("❌ Download failed: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            let unzipDir = FileManager.default.temporaryDirectory.appendingPathComponent("AppUpdate")
            try? FileManager.default.removeItem(at: unzipDir)
            try? FileManager.default.createDirectory(at: unzipDir, withIntermediateDirectories: true)

            let unzipTask = Process()
            unzipTask.launchPath = "/usr/bin/ditto"
            unzipTask.arguments = ["-x", "-k", tempURL.path, unzipDir.path]
            unzipTask.launch()
            unzipTask.waitUntilExit()

            let newAppPath = unzipDir.appendingPathComponent("YourApp.app") // or adjust if inside a subfolder

            // Prompt user to replace app manually or auto-replace (requires helper)
            DispatchQueue.main.async {
                NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: newAppPath.path)
                // You can show alert: "Unpacked new version. Quit the app and replace in /Applications"
            }
        }

        task.resume()
    }
}
