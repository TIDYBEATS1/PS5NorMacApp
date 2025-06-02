import SwiftUI
import Combine

struct GitHubRelease: Decodable {
    let tag_name: String
}

class VersionFetcher: ObservableObject {
    @Published var currentVersion: String = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
    @Published var latestVersion: String = "N/A"
    @Published var updateAvailable: Bool = false
    @Published var checkingUpdate: Bool = false

    private var cancellables = Set<AnyCancellable>()
    
    init() {
        fetchLatestVersion()  // Always fetch latest version at startup
    }
    
    func fetchLatestVersion() {
        checkingUpdate = true
        let urlString = "https://api.github.com/repos/TIDYBEATS1/PS5NORMacApp/releases/latest"
        guard let url = URL(string: urlString) else {
            DispatchQueue.main.async {
                self.latestVersion = "Invalid URL"
                self.checkingUpdate = false
            }
            return
        }
        
        URLSession.shared.dataTaskPublisher(for: url)
            .map { $0.data }
            .decode(type: GitHubRelease.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                self.checkingUpdate = false
                if case let .failure(error) = completion {
                    self.latestVersion = "Error: \(error.localizedDescription)"
                }
            }, receiveValue: { release in
                self.latestVersion = release.tag_name
                self.updateAvailable = self.isVersion(release.tag_name, newerThan: self.currentVersion)
            })
            .store(in: &cancellables)
    }
    
    private func isVersion(_ versionA: String, newerThan versionB: String) -> Bool {
        let cleanA = versionA.trimmingCharacters(in: CharacterSet(charactersIn: "v"))
        let cleanB = versionB.trimmingCharacters(in: CharacterSet(charactersIn: "v"))
        
        let partsA = cleanA.split(separator: ".").compactMap { Int($0) }
        let partsB = cleanB.split(separator: ".").compactMap { Int($0) }
        
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
