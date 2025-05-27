import Foundation
import Combine

class ErrorLookupViewModel: ObservableObject {
    @Published var errorCodes: [PS5ErrorCode] = []
    @Published var searchText: String = ""
    
    var filteredErrors: [PS5ErrorCode] {
        if searchText.isEmpty {
            return errorCodes
        } else {
            return errorCodes.filter { $0.code.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    init() {
        loadErrorCodes()
    }
    
    private func loadErrorCodes() {
        guard let url = Bundle.main.url(forResource: "errorCodes", withExtension: "json") else {
            print("errorCodes.json not found")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode([PS5ErrorCode].self, from: data)
            self.errorCodes = decoded
        } catch {
            print("Failed to load or decode errorCodes.json:", error)
        }
    }
}