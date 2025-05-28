import SwiftUI

struct UARTView: View {
    @StateObject private var uart = UARTManager()
    @State private var selectedPort: String?
    @State private var commandToSend = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Available Serial Ports:")
                .font(.headline)
            
            Picker("Select Port", selection: $selectedPort) {
                ForEach(uart.availablePorts, id: \.self) { port in
                    Text(port).tag(Optional(port))
                }
            }
            .pickerStyle(MenuPickerStyle())
            
            HStack {
                Button("Refresh Ports") {
                    uart.refreshPorts()
                }
                
                if uart.isConnected {
                    Button("Disconnect") {
                        uart.disconnect()
                        selectedPort = nil
                    }
                    .foregroundColor(.red)
                } else {
                    Button("Connect") {
                        if let port = selectedPort {
                            uart.connect(to: port)
                        }
                    }
                    .disabled(selectedPort == nil)
                }
            }
            
            Divider()
            
            Text("Received Data:")
                .font(.headline)
            
            ScrollView {
                Text(uart.receivedData)
                    .font(.system(.body, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
                    .background(Color.black.opacity(0.1))
                    .cornerRadius(8)
            }
            .frame(height: 200)
            
            // Clear Button
            Button("Clear") {
                uart.receivedData = ""
            }
            .padding(.top, 4)
            .buttonStyle(.bordered)
            
            // New Scan for Error Codes Button
            Button("Scan for Error Codes") {
                uart.scanForErrorCodes()
            }
            .disabled(!uart.isConnected)
            .padding(.top, 8)
            .buttonStyle(.borderedProminent)
            
            // List detected error codes live
            if !uart.detectedErrorCodes.isEmpty {
                Text("Detected Error Codes:")
                    .font(.headline)
                    .padding(.top, 12)
                
                List(uart.detectedErrorCodes, id: \.self) { code in
                    VStack(alignment: .leading) {
                        Text(code)
                            .font(.system(.body, design: .monospaced))
                            .bold()
                        
                        if let errorDesc = uart.getErrorDescription(for: code) {
                            Text(errorDesc.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 2)
                }
                .frame(height: 150)
            }
            
            HStack {
                TextField("Enter command", text: $commandToSend)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button("Send") {
                    uart.send(command: commandToSend)
                    commandToSend = ""
                }
                .disabled(!uart.isConnected || commandToSend.isEmpty)
            }
            
            Spacer()
        }
        .padding()
        .onAppear {
            uart.refreshPorts()
            uart.loadErrorCodes()  // Also load error codes on appear
        }
        .frame(minWidth: 400, minHeight: 600) // Added more height to fit list
    }
}
