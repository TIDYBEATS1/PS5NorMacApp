import SwiftUI

struct PS5ErrorLookupApp: App {
    var body: some Scene {
        WindowGroup {
        }
    }
}

class PS5ErrorCodes: ObservableObject {
    @Published private(set) var errorMap: [String: PS5ErrorCode] = [:]

    init() {
        loadErrors()
    }

    private func loadErrors() {
        guard let url = Bundle.main.url(forResource: "ps5_errors", withExtension: "json") else {
            print("Failed to find JSON file")
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode([PS5ErrorCode].self, from: data)
            DispatchQueue.main.async {
                // Create a dictionary keyed by error code
                self.errorMap = Dictionary(uniqueKeysWithValues: decoded.map { ($0.code, $0) })
            }
        } catch {
            print("Failed to load or decode JSON: \(error)")
        }
    }

    func description(for code: String) -> String {
        if let error = errorMap[code] {
            return error.description
        } else {
            return "Unknown error code"
        }
    }
}
