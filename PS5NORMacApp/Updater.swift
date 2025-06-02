//
//  Updater 2.swift
//  PS5NORMacApp
//
//  Created by Sam Stanwell on 02/06/2025.
//


import Foundation

class Updater {
    static let shared = Updater()
    
    private let repo = "TIDYBEATS1/PS5NORMacApp" // Your GitHub repo
    
    var latestVersion: String?
    var downloadURL: URL?
    
    private init() {}
    
    // Fetch latest release info from GitHub
    func checkForUpdate(completion: @escaping (_ downloadURL: URL?, _ latestVersion: String?) -> Void) {
        let urlString = "https://api.github.com/repos/\(repo)/releases/latest"
        guard let url = URL(string: urlString) else {
            completion(nil, nil)
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            guard error == nil, let data = data else {
                completion(nil, nil)
                return
            }
            
            if
                let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                let tagName = json["tag_name"] as? String {
                
                self.latestVersion = tagName
                
                // Try to get the download URL for the asset (optional)
                if let assets = json["assets"] as? [[String: Any]],
                   let firstAsset = assets.first,
                   let downloadURLString = firstAsset["browser_download_url"] as? String,
                   let url = URL(string: downloadURLString) {
                    self.downloadURL = url
                } else {
                    self.downloadURL = nil
                }
                
                completion(self.downloadURL, tagName)
            } else {
                completion(nil, nil)
            }
        }.resume()
    }
    
    // Compare current vs latest version string (numeric comparison)
    func isUpdateAvailable(latestVersion: String) -> Bool {
        let currentVersion = AppInfo.currentVersion
        return currentVersion.compare(latestVersion, options: .numeric) == .orderedAscending
    }
}
