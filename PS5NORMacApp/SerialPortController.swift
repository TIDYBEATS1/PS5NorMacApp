//
//  SerialPortController.swift
//  PS5NORMacApp
//
//  Created by Sam Stanwell on 26/05/2025.
//


import Foundation
import ORSSerial

class SerialPortController: NSObject, ORSSerialPortDelegate, ObservableObject {
    @Published var uartStatus: String = "Disconnected"
    @Published var uartData: String = "..."
    @Published var availablePorts: [ORSSerialPort] = []
    
    var selectedPort: ORSSerialPort? {
        didSet {
            if let port = selectedPort, !port.isOpen {
                port.delegate = self
            }
        }
    }

    override init() {
        super.init()
        updateAvailablePorts()
    }

    func updateAvailablePorts() {
        availablePorts = ORSSerialPortManager.shared().availablePorts
    }

    func connectToPort(baudRate: Int) {
        if let port = selectedPort {
            if port.isOpen {
                port.close()
                uartStatus = "Disconnected"
                selectedPort = nil
            } else {
                port.baudRate = NSNumber(value: baudRate)
                port.delegate = self
                port.open()
                // Status updated via serialPortWasOpened
            }
        } else {
            uartStatus = "No port selected"
        }
    }

    // ORSSerialPortDelegate methods
    func serialPort(_ serialPort: ORSSerialPort, didReceive data: Data) {
        if let receivedString = String(data: data, encoding: .utf8) {
            DispatchQueue.main.async {
                self.uartData = receivedString.trimmingCharacters(in: .newlines)
            }
        }
    }

    func serialPortWasOpened(_ serialPort: ORSSerialPort) {
        DispatchQueue.main.async {
            self.uartStatus = "Connected to \(serialPort.name ?? "Unknown")"
        }
    }

    func serialPortWasClosed(_ serialPort: ORSSerialPort) {
        DispatchQueue.main.async {
            self.uartStatus = "Disconnected"
            self.selectedPort = nil
        }
    }

    func serialPortWasRemoved(fromSystem serialPort: ORSSerialPort) {
        DispatchQueue.main.async {
            self.uartStatus = "Disconnected"
            self.selectedPort = nil
            self.updateAvailablePorts()
        }
    }

    func serialPort(_ serialPort: ORSSerialPort, didEncounterError error: Error) {
        DispatchQueue.main.async {
            self.uartStatus = "Error: \(error.localizedDescription)"
        }
    }

    func serialPort(_ serialPort: ORSSerialPort, didReceiveResponse response: Data, to request: ORSSerialRequest) {
        // Handle request/response if needed; otherwise, leave empty
    }

    func serialPort(_ serialPort: ORSSerialPort, didReceivePacket packetData: Data, matching descriptor: ORSSerialPacketDescriptor) {
        // Handle packet data if using packet descriptors; otherwise, leave empty
    }
}