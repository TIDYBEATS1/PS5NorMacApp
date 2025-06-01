//
//  PS4ViewModel.swift
//  PS5NORMacApp
//
//  Created by Sam Stanwell on 30/05/2025.
//


import Foundation
import Combine

class PS4View: ObservableObject {
    @Published var log: AttributedString = ""
    @Published var isConnected = false

    private var port: SerialPort?
    private var selectedPortPath: String = ""
    
    func connect(to path: String) {
        port = SerialPort()
        port?.onDataReceived = { [weak self] data in
            guard let self = self, let string = String(data: data, encoding: .utf8) else { return }
            self.appendLog(string)
        }
        if port?.open(portPath: path) == true {
            selectedPortPath = path
            isConnected = true
        }
    }
    
    func disconnect() {
        port?.close()
        isConnected = false
    }

    func sendCommand(_ command: String) {
        guard let data = "\(command)\r\n".data(using: .utf8) else { return }
        port?.send(data)
    }
    
    func appendLog(_ line: String) {
        DispatchQueue.main.async {
            self.log += AttributedString(line)
        }
    }
}
