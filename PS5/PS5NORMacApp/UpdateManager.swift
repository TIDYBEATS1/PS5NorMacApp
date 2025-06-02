//
//  UpdateManager.swift
//  PS5NORMacApp
//
//  Created by Sam Stanwell on 30/05/2025.
//


import Foundation

class UpdateManager: ObservableObject {
    @Published var updateAvailable: UpdateInfo?
    private let updateURL = URL(string: "https://github.com/TIDYBEATS1/PS5NorMacApp/blob/main/updates.json")!

    func checkForUpdates() {
        URLSession.shared.dataTask(with: updateURL) { data, response, error in
            guard let data = data, error == nil else {
                print("Update check failed: \(error?.localizedDescription ?? "No data")")
                return
            }
            do {
                let updateInfo = try JSONDecoder().decode(UpdateInfo.self, from: data)
                let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
                
                // Compare versions (simple string comparison or use a versioning library)
                if updateInfo.latestVersion.compare(currentVersion, options: .numeric) == .orderedDescending {
                    DispatchQueue.main.async {
                        self.updateAvailable = updateInfo
                    }
                } else {
                    DispatchQueue.main.async {
                        self.updateAvailable = nil
                    }
                }
            } catch {
                print("JSON decode error: \(error)")
            }
        }.resume()
    }
}
