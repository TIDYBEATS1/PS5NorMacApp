import Foundation

struct UpdateInfo: Codable {
    let latestVersion: String
    let downloadURL: String
    let releaseNotes: String
}