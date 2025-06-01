import SwiftUI

struct PS4TerminalView: View {
    @StateObject private var viewModel = PS4ViewModel()
    @State private var input: String = ""
    @State private var selectedPort: String = "/dev/cu.usbserial"

    var body: some View {
        VStack {
            HStack {
                TextField("Serial Port", text: $selectedPort)
                Button("Connect") {
                    viewModel.connect(to: selectedPort)
                }
                Button("Disconnect") {
                    viewModel.disconnect()
                }
            }
            .padding()

            ScrollView {
                Text(viewModel.log)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.black.opacity(0.05))
                    .font(.system(.body, design: .monospaced))
            }

            HStack {
                TextField("Enter command", text: $input)
                    .onSubmit {
                        viewModel.sendCommand(input)
                        input = ""
                    }
                Button("Send") {
                    viewModel.sendCommand(input)
                    input = ""
                }
            }
            .padding()
        }
        .navigationTitle("PS4 UART Terminal")
    }
}