//
//  Updater.swift
//  PS5NORMacApp
//
//  Created by Sam Stanwell on 02/06/2025.
//


import Foundation

class Updater {
    static let shared = Updater()
    
    func checkForUpdateAndRunHelper() {
        guard let url = URL(string: "https://api.github.com/repos/TIDYBEATS1/PS5NORMacApp/releases/latest") else {
            print("Invalid URL")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let assets = json["assets"] as? [[String: Any]],
                  let zipAsset = assets.first(where: { ($0["name"] as? String)?.hasSuffix(".zip") == true }),
                  let zipURLString = zipAsset["browser_download_url"] as? String,
                  let zipURL = URL(string: zipURLString) else {
                print("Could not find update ZIP")
                return
            }

            self.downloadUpdateZip(from: zipURL)
        }.resume()
    }
    
    private func downloadUpdateZip(from url: URL) {
        let tempDirectory = FileManager.default.temporaryDirectory
        let destinationURL = tempDirectory.appendingPathComponent("update.zip")

        let task = URLSession.shared.downloadTask(with: url) { location, _, error in
            if let location = location {
                do {
                    try FileManager.default.moveItem(at: location, to: destinationURL)
                    print("Downloaded to: \(destinationURL.path)")
                    self.launchHelper(with: destinationURL.path)
                } catch {
                    print("Move failed: \(error)")
                }
            } else {
                print("Download failed: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
        task.resume()
    }
    
    private func launchHelper(with zipPath: String) {
        guard let helperApp = Bundle.main.url(forResource: "UpdaterHelperGUI", withExtension: "app", subdirectory: "Contents/Helpers") else {
            print("Helper app not found")
            return
        }
        
        let execURL = helperApp.appendingPathComponent("Contents/MacOS/UpdaterHelperGUI")
        let process = Process()
        process.executableURL = execURL
        process.arguments = [zipPath]
        
        do {
            try process.run()
        } catch {
            print("Failed to launch helper: \(error)")
        }
    }
}