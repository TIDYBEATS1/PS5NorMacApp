import Foundation
import Combine

class VersionFetcher: ObservableObject {
    @Published private(set) var version: String = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0"

    func fetchVersion() {
        guard let url = URL(string: "https://raw.githubusercontent.com/your-repo/your-project/main/version.txt") else {
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, error in
            guard error == nil,
                  let data = data,
                  let fetchedVersion = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
            else {
                return
            }

            DispatchQueue.main.async {
                if self.isVersion(fetchedVersion, newerThan: self.version) {
                    self.version = fetchedVersion
                }
            }
        }.resume()
    }

    private func isVersion(_ versionA: String, newerThan versionB: String) -> Bool {
        let partsA = versionA.split(separator: ".").compactMap { Int($0) }
        let partsB = versionB.split(separator: ".").compactMap { Int($0) }

        for i in 0..<max(partsA.count, partsB.count) {
            let a = i < partsA.count ? partsA[i] : 0
            let b = i < partsB.count ? partsB[i] : 0
            if a > b {
                return true
            } else if a < b {
                return false
            }
        }
        return false
    }
}
