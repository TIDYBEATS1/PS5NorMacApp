import Foundation

class Updater {
    static let shared = Updater()
    
    private init() { }
    
    // Change this to your GitHub repo API URL or your update JSON URL
    private let latestReleaseURL = URL(string: "https://api.github.com/repos/TIDYBEATS1/PS5NORMacApp/releases/latest")!
    
    // Current app version string from your app’s Info.plist
    var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0"
    }
    
    // Check for update - call completion with download URL and version string
    func checkForUpdate(completion: @escaping (URL?, String?) -> Void) {
        let task = URLSession.shared.dataTask(with: latestReleaseURL) { data, _, error in
            guard let data = data, error == nil else {
                completion(nil, nil)
                return
            }
            
            do {
                // GitHub release JSON decoding
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let tagName = json["tag_name"] as? String,
                   let assets = json["assets"] as? [[String: Any]],
                   let firstAsset = assets.first,
                   let downloadURLString = firstAsset["browser_download_url"] as? String,
                   let downloadURL = URL(string: downloadURLString) {
                    
                    completion(downloadURL, tagName)
                } else {
                    completion(nil, nil)
                }
            } catch {
                completion(nil, nil)
            }
        }
        task.resume()
    }
    
    // Compare latest version to current version
    func isUpdateAvailable(latestVersion: String) -> Bool {
        return latestVersion.compare(currentVersion, options: .numeric) == .orderedDescending
    }
    
    // Download the update installer file
    func downloadUpdate(from url: URL, completion: @escaping (URL?) -> Void) {
        let task = URLSession.shared.downloadTask(with: url) { tempLocalUrl, _, error in
            guard let tempLocalUrl = tempLocalUrl, error == nil else {
                completion(nil)
                return
            }
            
            // Move the file to a permanent location in your app's cache or temp folder
            let fileManager = FileManager.default
            let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            let destinationURL = cachesDirectory.appendingPathComponent(url.lastPathComponent)
            
            do {
                if fileManager.fileExists(atPath: destinationURL.path) {
                    try fileManager.removeItem(at: destinationURL)
                }
                try fileManager.moveItem(at: tempLocalUrl, to: destinationURL)
                completion(destinationURL)
            } catch {
                completion(nil)
            }
        }
        task.resume()
    }
}
