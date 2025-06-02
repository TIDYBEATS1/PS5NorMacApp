import SwiftUI

struct ErrorLookupView: View {
    @Binding var errorCodeInput: String
    @Binding var errorDescription: String
    @Binding var errorSolution: String
    @ObservedObject var viewModel: ErrorLookupViewModel
    @ObservedObject var uartViewModel: UARTViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Error Code Lookup")
                .font(.title2)
                .fontWeight(.bold)

            HStack {
                TextField("Enter PS5 error code (e.g., CE-10005-6)", text: $errorCodeInput)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 300)

                Button("Lookup") {
                    lookupErrorCode()
                }
                .buttonStyle(.borderedProminent)
            }

            // Description box
            VStack(alignment: .leading, spacing: 8) {
                Text("Description")
                    .font(.headline)
                Text(errorDescription.isEmpty ? "Enter an error code to see its description." : errorDescription)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 2)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(nsColor: NSColor.windowBackgroundColor))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(nsColor: NSColor.separatorColor), lineWidth: 0.5)
                    )
            )

            // Solution box
            VStack(alignment: .leading, spacing: 8) {
                Text("Solution")
                    .font(.headline)
                Text(errorSolution.isEmpty ? "Enter an error code to see its solution." : errorSolution)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 2)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(nsColor: NSColor.windowBackgroundColor))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(nsColor: NSColor.separatorColor), lineWidth: 0.5)
                    )
            )

            Divider()
                .padding(.vertical)

            Text("All Error Codes")
                .font(.headline)

            // Styled List
            VStack(spacing: 0) {
                List(viewModel.errorCodes) { error in
                    VStack(alignment: .leading) {
                        Text(error.code)
                            .fontWeight(.bold)
                        Text(error.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    .padding(.vertical, 4)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        errorCodeInput = error.code
                        errorDescription = error.description
                        errorSolution = error.solution ?? "No solution provided."
                    }
                }
                .listStyle(.plain)
                .listRowBackground(Color.clear)
                .background(Color.clear)
                .frame(minHeight: 200)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(nsColor: NSColor.windowBackgroundColor))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(nsColor: NSColor.separatorColor), lineWidth: 0.5)
                    )
            )
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
