//
//  UARTScannerView.swift
//  PS5NORMacApp
//
//  Created by Sam Stanwell on 28/05/2025.
//


import SwiftUI

struct UARTScannerView: View {
    @StateObject private var uartManager = UARTManager()
    @State private var selectedPort: String = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Available UART Ports")
                .font(.headline)
            
            Picker("Select Port", selection: $selectedPort) {
                ForEach(uartManager.availablePorts, id: \.self) { port in
                    Text(port).tag(port)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .frame(maxWidth: 400)
            
            HStack(spacing: 20) {
                Button(uartManager.isConnected ? "Disconnect" : "Connect") {
                    if uartManager.isConnected {
                        uartManager.disconnect()
                    } else if !selectedPort.isEmpty {
                        uartManager.connect(to: selectedPort)
                    }
                }
                .disabled(selectedPort.isEmpty)
                
                Button("Start Scanning for Error Codes") {
                    uartManager.scanForErrorCodes()
                }
                .disabled(!uartManager.isConnected)
            }
            
            Divider()
            
            Text("Detected Error Codes:")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if uartManager.detectedErrorCodes.isEmpty {
                Text("No error codes detected yet.")
                    .foregroundColor(.secondary)
                    .italic()
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                List(uartManager.detectedErrorCodes, id: \.self) { code in
                    VStack(alignment: .leading) {
                        Text(code).bold()
                        if let errorInfo = uartManager.getErrorDescription(for: code) {
                            Text(errorInfo.description)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .listStyle(PlainListStyle())
                .frame(minHeight: 200)
            }
            
            Spacer()
        }
        .padding()
        .onAppear {
            uartManager.refreshPorts()
            uartManager.loadErrorCodes()
        }
    }
}