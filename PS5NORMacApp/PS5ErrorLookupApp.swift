import SwiftUI

@main
struct PS5ErrorLookupApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

class PS5ErrorCodes: ObservableObject {
    @Published private(set) var errorMap: [String: String] = [:]
    
    init() {
        loadErrors()
    }
    
    private func loadErrors() {
        guard let url = Bundle.main.url(forResource: "ps5_errors", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data, options: []),
              let dict = json as? [String: String] else {
            print("Failed to load PS5 error codes JSON")
            return
        }
        errorMap = dict
    }
    
    func description(for code: String) -> String {
        errorMap[code] ?? "Unknown error code"
    }
}

struct ContentView: View {
    @StateObject private var errorCodes = PS5ErrorCodes()
    @State private var inputCode: String = ""
    @State private var description: String = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("PS5 Error Code Lookup")
                .font(.largeTitle)
                .padding(.top)
            
            TextField("Enter error code (e.g. 80801001)", text: $inputCode)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
                .onChange(of: inputCode) { newValue in
                    description = errorCodes.description(for: newValue.uppercased())
                }
            
            Text(description)
                .font(.headline)
                .foregroundColor(description == "Unknown error code" ? .red : .primary)
                .padding()
            
            Spacer()
        }
        .padding()
        .frame(minWidth: 400, minHeight: 200)
    }
}