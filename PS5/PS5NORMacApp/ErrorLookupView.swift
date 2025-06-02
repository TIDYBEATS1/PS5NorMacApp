import SwiftUI

struct ErrorLookupView: View {
    @Binding var errorCodeInput: String
    @Binding var errorDescription: String
    @Binding var errorSolution: String
    @ObservedObject var viewModel: ErrorLookupViewModel
    @ObservedObject var uartViewModel: UARTViewModel // Fixed
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Error Code Lookup")
                .font(.title2)
                .fontWeight(.bold)
            
            HStack {
                TextField("Enter PS5 error code (e.g., CE-10005-6)", text: $errorCodeInput)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 300)
                    .scrollIndicators(.visible)

                Button("Lookup") {
                    lookupErrorCode()
                }
                .buttonStyle(.borderedProminent)
            }
            
            GroupBox(label: Text("Description").font(.headline)) {
                Text(errorDescription.isEmpty ? "Enter an error code to see its description." : errorDescription)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            GroupBox(label: Text("Solution").font(.headline)) {
                Text(errorSolution.isEmpty ? "Enter an error code to see its solution." : errorSolution)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            Divider()
                .padding(.vertical)
            
            Text("All Error Codes")
                .font(.headline)
            
            List(viewModel.errorCodes) { error in
                VStack(alignment: .leading) {
                    Text(error.code)
                        .fontWeight(.bold)
                    Text(error.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                .contentShape(Rectangle()) // Makes the whole cell tappable
                .onTapGesture {
                    errorCodeInput = error.code
                    errorDescription = error.description
                    errorSolution = error.solution ?? "No solution provided."
                }
            }
            .frame(minHeight: 200)
        }
        .padding()
    }
    
    private func lookupErrorCode() {
        let trimmed = errorCodeInput.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !trimmed.isEmpty else {
            errorDescription = "Error: Please enter an error code."
            errorSolution = ""
            return
        }
        
        if let error = viewModel.errorCodes.first(where: { $0.code.uppercased() == trimmed }) {
            errorDescription = error.description
            errorSolution = error.solution ?? "No solution provided."
        } else {
            errorDescription = "Error code not found: \(trimmed)"
            errorSolution = "No solution available. Verify the error code or update the database."
        }
    }
}
