import Foundation
import SwiftUI
import ZIPFoundation

class Updater: ObservableObject {
    static let shared = Updater()
    
    @Published var isUpdating = false
    @Published var updateStatusMessage: String? = nil
    
    func downloadAndUpdateApp(from urlString: String) {
        guard let url = URL(string: urlString) else {
            updateStatusMessage = "Invalid update URL"
            return
        }
        
        isUpdating = true
        updateStatusMessage = "Starting download..."
        
        let tempDir = FileManager.default.temporaryDirectory
        let zipFileURL = tempDir.appendingPathComponent("PS5NORMacApp.app.zip")
        let unzipDestination = tempDir.appendingPathComponent("UnzippedApp")
        
        // Clean previous files if any
        try? FileManager.default.removeItem(at: zipFileURL)
        try? FileManager.default.removeItem(at: unzipDestination)
        
        let downloadTask = URLSession.shared.downloadTask(with: url) { localURL, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.updateStatusMessage = "Download error: \(error.localizedDescription)"
                    self.isUpdating = false
                    return
                }
                guard let localURL = localURL else {
                    self.updateStatusMessage = "Download error: no file"
                    self.isUpdating = false
                    return
                }
                
                do {
                    try FileManager.default.moveItem(at: localURL, to: zipFileURL)
                    self.updateStatusMessage = "Unzipping update..."
                    
                    try FileManager.default.unzipItem(at: zipFileURL, to: unzipDestination)
                    
                    let newAppURL = unzipDestination.appendingPathComponent("PS5NORMacApp.app")
                    let runningAppURL = Bundle.main.bundleURL
                    let backupURL = runningAppURL.deletingLastPathComponent().appendingPathComponent("PS5NORMacApp_backup.app")
                    
                    // Backup current app
                    if FileManager.default.fileExists(atPath: backupURL.path) {
                        try FileManager.default.removeItem(at: backupURL)
                    }
                    try FileManager.default.moveItem(at: runningAppURL, to: backupURL)
                    
                    // Replace app
                    try FileManager.default.moveItem(at: newAppURL, to: runningAppURL)
                    
                    // Cleanup
                    try FileManager.default.removeItem(at: zipFileURL)
                    try FileManager.default.removeItem(at: unzipDestination)
                    
                    self.updateStatusMessage = "Update succeeded! Please restart the app."
                } catch {
                    self.updateStatusMessage = "Update failed: \(error.localizedDescription)"
                }
                
                self.isUpdating = false
            }
        }
        downloadTask.resume()
    }
}
