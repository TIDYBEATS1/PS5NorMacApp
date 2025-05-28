//
//  UARTViewModel 2.swift
//  PS5NORMacApp
//
//  Created by Sam Stanwell on 28/05/2025.
//


import Foundation

class UARTViewModel: ObservableObject {
    @Published var terminalOutput: String = "UART Terminal Ready\n"
    @Published var isConnected: Bool = false
    @Published var errorLogs: [(code: String, description: String, timestamp: Date)] = []
    
    private let responses: [String: String] = [
        "errlog 0": "OK 00000000\nError Codes: 80C00136 (WiFi/BT Failure), E0000001 (Southbridge Issue)",
        "errlog clear": "OK 00000000\nError Log Cleared",
        "status": "OK 00000000:3A $$ [MANU] UART CMD READY:36"
    ]
    
    private let errorDescriptions: [String: String] = [
        "80C00136": "WiFi/BT Failure",
        "E0000001": "Southbridge Issue",
        "86000005": "Corrupted NOR"
    ]
    
    func sendCommand(_ command: String) {
        let trimmedCommand = command.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedCommand.isEmpty {
            terminalOutput += "Error: Empty command\n"
            return
        }
        
        terminalOutput += "> \(trimmedCommand)\n"
        if let response = responses[trimmedCommand.lowercased()] {
            terminalOutput += "\(response)\n"
            if trimmedCommand.lowercased() == "errlog 0" {
                parseErrorCodes(from: response)
            }
        } else {
            terminalOutput += "Error: Unknown command '\(trimmedCommand)'\n"
        }
    }
    
    func clearTerminal() {
        terminalOutput = "UART Terminal Ready\n"
        errorLogs.removeAll()
    }
    
    func toggleConnection() {
        isConnected.toggle()
        terminalOutput += isConnected ? "Connected to UART\n" : "Disconnected from UART\n"
    }
    
    private func parseErrorCodes(from response: String) {
        let lines = response.components(separatedBy: .newlines)
        for line in lines where line.contains("Error Codes:") {
            let codes = line
                .replacingOccurrences(of: "Error Codes: ", with: "")
                .components(separatedBy: ",")
                .map { $0.trimmingCharacters(in: .whitespaces).components(separatedBy: " ").first ?? "" }
                .filter { !$0.isEmpty }
            
            for code in codes {
                let description = errorDescriptions[code] ?? "Unknown Error"
                errorLogs.append((code, description, Date.now))
            }
        }
    }
}
