import Foundation
import Combine



class ErrorLookupViewModel: ObservableObject {
    @Published var errorCodes: [PS5ErrorCode] = []
    
    init() {
        loadErrorCodes()
    }
    
    func loadErrorCodes() {
        guard let url = Bundle.main.url(forResource: "errorCodes", withExtension: "json") else {
            print("Failed to find errorCodes.json")
            return
        }
        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode([PS5ErrorCode].self, from: data)
            DispatchQueue.main.async {
                self.errorCodes = decoded
            }
        } catch {
            print("Failed to decode JSON: \(error)")
        }
        struct ErrorCode: Identifiable {
            let id = UUID()
            let code: String
            let description: String
            let solution: String?
        }
    }
}
