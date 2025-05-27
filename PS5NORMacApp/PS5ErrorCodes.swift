struct PS5ErrorCodes: Codable, Identifiable {
    let id = UUID() // For SwiftUI
    let code: String
    let description: String
    let solution: String
    
    enum CodingKeys: String, CodingKey {
        case code
        case description
        case solution
    }
}