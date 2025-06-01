//
//  AppSettings.swift
//  PS5NORMacApp
//
//  Created by Sam Stanwell on 28/05/2025.
//


import Foundation

class AppSettings: ObservableObject {
    @Published var defaultBaudRate: Int = 115200 {
        didSet {
            print("defaultBaudRate changed to: \(defaultBaudRate)")
        }
    }
        @Published var autoConnect: Bool = false
        @Published var logToFile: Bool = false
        @Published var showHexOutput: Bool = true
        @Published var uartTimeout: Int = 10  // In deciseconds (100ms = 1)
        
    }

