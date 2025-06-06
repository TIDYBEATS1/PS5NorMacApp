//
//  ErrorCodeLookup.swift
//  PS5NORMacApp
//
//  Created by Sam Stanwell on 04/06/2025.
//


import Foundation

enum ErrorCodeLookup {
    static func codeDescription(for code: String) -> String {
        // Replace with your real known error codes and descriptions
        let known = [
            "09000080": "Power failure",
            "030302C0": "Unexpected shutdown"
        ]
        return known[code] ?? "Unknown Code"
    }
    
    static func seqDescription(for seqNo: String) -> String {
        let known = [
            "7921": "Power-on sequence",
            "9021": "Shutdown initiated"
        ]
        return known[seqNo] ?? "Unknown Seq"
    }
    
    static func powStateDescription(for value: UInt8) -> String {
        let known: [UInt8: String] = [
            0x20: "S0 (On)",
            0xFF: "Unknown State"
        ]
        return known[value] ?? "Unknown PowState"
    }
    
    static func upCauseFlags(for value: UInt8) -> [String] {
        let map: [UInt8: String] = [
            0: "Power Button",
            1: "Overheat",
            2: "Watchdog Timer"
        ]
        var result: [String] = []
        for (bit, desc) in map {
            if (value & (1 << bit)) != 0 {
                result.append(desc)
            }
        }
        return result.isEmpty ? ["No Boot Cause"] : result
    }
    
    static func devPmFlags(for value: UInt8) -> [String] {
        let map: [UInt8: String] = [
            0: "HDD",
            1: "LAN",
            2: "WiFi"
        ]
        var result: [String] = []
        for (bit, desc) in map {
            if (value & (1 << bit)) != 0 {
                result.append(desc)
            }
        }
        return result.isEmpty ? ["No Device Power"] : result
    }
    
    static func hexToCelsius(_ hex: String) -> Double {
        guard let intVal = Int(hex, radix: 16) else { return 0.0 }
        return Double(intVal) / 256.0
    }
    
    struct ErrorCodeLookup {
        static func getCodeDescription(_ code: String) -> String {
            return codeDatabase[code.uppercased()] ?? "Unknown Code"
        }
        
        static func getPowStateDescription(_ value: Int) -> String {
            return powStateMap[value] ?? "Unknown PowState"
        }
        
        static func getUpcauseFlags(_ value: Int) -> [String] {
            var flags: [String] = []
            for (bit, desc) in upcauseMap {
                if (value & (1 << bit)) != 0 {
                    flags.append(desc)
                }
            }
            return flags.isEmpty ? ["No Boot Cause"] : flags
        }
        
        static func getDevpmFlags(_ value: Int) -> [String] {
            var flags: [String] = []
            for (bit, desc) in devpmMap {
                if (value & (1 << bit)) != 0 {
                    flags.append(desc)
                }
            }
            return flags.isEmpty ? ["No Device Power"] : flags
        }
        
        static func convertHexTempToCelsius(_ hex: String) -> Double? {
            guard let intVal = Int(hex, radix: 16) else { return nil }
            return Double(intVal) / 256.0
        }
        
        // These are legacy helpers used in parseHexWordsToEntries
        static func codeDescription(for code: String) -> String {
            return getCodeDescription(code)
        }
        
        static func seqDescription(for seq: String) -> String {
            return seqDatabase[seq.uppercased()] ?? "Unknown Seq"
        }
        
        static func powStateDescription(for value: String) -> String {
            guard let byte = UInt8(value.suffix(2), radix: 16) else { return "Invalid" }
            return getPowStateDescription(Int(byte))
        }
        
        static func upCauseFlags(for value: String) -> [String] {
            guard let byte = UInt8(value.suffix(2), radix: 16) else { return [] }
            return getUpcauseFlags(Int(byte))
        }
        
        static func devPmFlags(for value: String) -> [String] {
            guard let byte = UInt8(value.suffix(2), radix: 16) else { return [] }
            return getDevpmFlags(Int(byte))
        }
        
        static func hexToCelsius(hex: String) -> String {
            guard let c = convertHexTempToCelsius(hex) else { return "?" }
            return String(format: "%.1f", c)
        }
        
        // Mock databases (replace with your real data)
        static let codeDatabase: [String: String] = [
            "09000080": "Power Failure",
            "030302C0": "Watchdog Timeout"
        ]
        
        static let seqDatabase: [String: String] = [
            "7921": "Bootloader Init",
            "9021": "System Shutdown",
            "7B21": "User Power Off"
        ]
        
        static let powStateMap: [Int: String] = [
            0x12: "Suspend",
            0x20: "Idle",
            0xFF: "Unknown"
        ]
        
        static let upcauseMap: [Int: String] = [
            0: "Power Button",
            1: "Remote Wake",
            2: "Overheat"
        ]
        
        static let devpmMap: [Int: String] = [
            0: "WiFi",
            1: "LAN",
            2: "Bluetooth"
        ]
    }
}
