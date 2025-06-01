//
//  SerialPortManager.swift
//  PS5NORMacApp
//
//  Created by Sam Stanwell on 30/05/2025.
//


import SwiftUI
import Combine
import Foundation
import IOKit.serial
import CryptoKit

class SerialPortManager: ObservableObject {
    @Published var availablePorts: [String] = []
    @Published var selectedPort: String? = nil
    @Published var statusLog: String = ""
    @Published var progress: Double = 0.0 // 0.0 to 1.0
    @Published var md5Hash: String? = nil
    @Published var isDumping: Bool = false
    
    private var fd: Int32 = -1
    private let dumpSize = 512 * 1024
    private let blockSize = 1024
    
    init() {
        refreshPorts()
    }
    
    func refreshPorts() {
        availablePorts = listSerialPorts()
        if selectedPort == nil, let first = availablePorts.first {
            selectedPort = first
        }
    }
    
    func listSerialPorts() -> [String] {
        var result: [String] = []
        let matchingDict = IOServiceMatching(kIOSerialBSDServiceValue)
        var iterator: io_iterator_t = 0
        let kernResult = IOServiceGetMatchingServices(kIOMasterPortDefault, matchingDict, &iterator)
        
        if kernResult == KERN_SUCCESS {
            var service: io_object_t = IOIteratorNext(iterator)
            while service != 0 {
                if let bsdPathAsCFstring = IORegistryEntryCreateCFProperty(service, kIOCalloutDeviceKey as CFString, kCFAllocatorDefault, 0) {
                    let bsdPath = bsdPathAsCFstring.takeUnretainedValue() as! String
                    // Filter for CH340 or usbserial devices
                    if bsdPath.contains("usbserial") || bsdPath.contains("tty.usbserial") || bsdPath.contains("CH340") {
                        result.append(bsdPath)
                    }
                }
                IOObjectRelease(service)
                service = IOIteratorNext(iterator)
            }
        }
        IOObjectRelease(iterator)
        return result
    }
    
    func openPort() -> Bool {
        guard let port = selectedPort else { return false }
        fd = open(port, O_RDWR | O_NOCTTY | O_EXLOCK)
        if fd == -1 {
            appendStatus("Failed to open \(port)")
            return false
        }
        
        var options = termios()
        tcgetattr(fd, &options)
        cfsetspeed(&options, speed_t(B115200))
        options.c_cflag |= (CLOCAL | CREAD)
        options.c_cflag &= ~CSIZE
        options.c_cflag |= CS8
        options.c_cflag &= ~PARENB
        options.c_cflag &= ~CSTOPB
        options.c_cflag &= ~CRTSCTS
        
        options.c_lflag = 0
        options.c_oflag = 0
        options.c_iflag = 0
        
        options.c_cc.16 /* VMIN */ = 0
        options.c_cc.17 /* VTIME */ = 50 // 5 seconds timeout
        
        tcsetattr(fd, TCSANOW, &options)
        
        appendStatus("Port \(port) opened")
        return true
    }
    
    func closePort() {
        if fd != -1 {
            close(fd)
            fd = -1
            appendStatus("Port closed")
        }
    }
    
    private func writeByte(_ byte: UInt8) -> Bool {
        var b = byte
        let written = write(fd, &b, 1)
        return written == 1
    }
    
    private func readByte() -> UInt8? {
        var buffer = [UInt8](repeating: 0, count: 1)
        let readCount = read(fd, &buffer, 1)
        if readCount == 1 {
            return buffer[0]
        }
        return nil
    }
    
    private func appendStatus(_ text: String) {
        DispatchQueue.main.async {
            self.statusLog += text + "\n"
        }
    }
    
    // MARK: Dumping process
    func startDump() {
        guard !isDumping else { return }
        guard openPort() else { return }
        
        isDumping = true
        statusLog = ""
        progress = 0
        md5Hash = nil
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.dumpSyscon()
        }
    }
    
    private func dumpSyscon() {
        defer {
            DispatchQueue.main.async {
                self.isDumping = false
                self.closePort()
            }
        }
        
        appendStatus("Starting dump...")
        
        if !writeByte(0x00) {
            appendStatus("Failed to send start byte")
            return
        }
        
        var started = false
        while let resp = readByte() {
            if resp == 0x91 {
                appendStatus("Received 0x91, starting dump")
                started = true
                break
            } else if resp == 0xEE {
                appendStatus("Chip unresponsive (0xEE)")
                return
            } else if resp == 0x00 {
                appendStatus("Glitching (0x00), retrying...")
            }
        }
        
        if !started {
            appendStatus("Did not receive start signal")
            return
        }
        
        // Wait for 0x94 before starting data read
        while let resp = readByte() {
            if resp == 0x94 {
                appendStatus("Received 0x94, beginning data dump")
                break
            }
        }
        
        // Prepare file to save dump
        let fileUrl = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("syscon_dump.bin")
        FileManager.default.createFile(atPath: fileUrl.path, contents: nil, attributes: nil)
        guard let fileHandle = try? FileHandle(forWritingTo: fileUrl) else {
            appendStatus("Failed to open file for writing")
            return
        }
        
        var bytesRead = 0
        while bytesRead < dumpSize {
            var buffer = [UInt8](repeating: 0, count: blockSize)
            let n = read(fd, &buffer, blockSize)
            if n <= 0 {
                appendStatus("Read error or timeout during dump")
                break
            }
            fileHandle.write(Data(buffer[0..<n]))
            bytesRead += n
            
            DispatchQueue.main.async {
                self.progress = Double(bytesRead) / Double(self.dumpSize)
            }
        }
        
        try? fileHandle.close()
        
        appendStatus("Dump complete. Saved to \(fileUrl.path)")
        
        // Compute MD5 hash
        if let data = try? Data(contentsOf: fileUrl) {
            let hash = Insecure.MD5.hash(data: data)
            let hashString = hash.map { String(format: "%02X", $0) }.joined()
            DispatchQueue.main.async {
                self.md5Hash = hashString
                self.appendStatus("MD5: \(hashString)")
            }
        }
    }
}