import SwiftUI

struct ErrorCodesView: View {
    var selectedCodes: [String]

    let errorCodesDatabase: [String: String] = [
        "CE-1000-1234": "General system error.",
        "CE-2000-5678": "Hardware failure detected.",
        "CE-3000-0001": "Network connection lost."
    ]

    var body: some View {
        List {
            if selectedCodes.isEmpty {
                Text("No PS5 error codes detected.")
                    .foregroundColor(.secondary)
            } else {
                ForEach(selectedCodes, id: \.self) { code in
                    VStack(alignment: .leading) {
                        Text(code)
                            .font(.headline)
                        Text(errorCodesDatabase[code] ?? "Unknown error.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Detected PS5 Error Codes")
    }
}
