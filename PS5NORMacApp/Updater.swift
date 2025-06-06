// Updater.swift
import Foundation
import SwiftUI
import ZIPFoundation

class Updater: ObservableObject {
    static let shared = Updater()

    @Published var isUpdating = false
    @Published var updateStatusMessage: String? = nil
    @Published var showPatchNotes = false
    @Published var patchNotes: String? = nil

    func fetchLatestPatchNotes(completion: @escaping (String?) -> Void) {
        let url = URL(string: "https://api.github.com/repos/TIDYBEATS1/PS5NorMacApp/releases/latest")!

        URLSession.shared.dataTask(with: url) { data, _, error in
            if let data = data,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let body = json["body"] as? String {
                completion(body)
            } else {
                completion(nil)
            }
        }.resume()
    }

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

        try? FileManager.default.removeItem(at: zipFileURL)
        try? FileManager.default.removeItem(at: unzipDestination)

        let downloadTask = URLSession.shared.downloadTask(with: url) { localURL, _, error in
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

                    if FileManager.default.fileExists(atPath: backupURL.path) {
                        try FileManager.default.removeItem(at: backupURL)
                    }
                    try FileManager.default.moveItem(at: runningAppURL, to: backupURL)
                    try FileManager.default.moveItem(at: newAppURL, to: runningAppURL)

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
