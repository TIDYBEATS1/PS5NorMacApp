import SwiftUI

struct ErrorLookupView: View {
    @StateObject private var errorCodeModel = PS5ErrorCode()
    @State private var inputCode = ""

    var body: some View {
        VStack(spacing: 20) {
            Text("PS5 Error Code Lookup")
                .font(.headline)

            TextField("Enter error code", text: $inputCode)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)

            Text(errorCodeModel.description(for: inputCode))
                .padding()
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding()
        .frame(minWidth: 300, minHeight: 200)
    }
}