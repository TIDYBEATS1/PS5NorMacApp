//
//  SettingsView.swift
//  PS5NORMacApp
//
//  Created by Sam Stanwell on 28/05/2025.
//


import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: AppSettings

    var body: some View {
        Form {
            Section(header: Text("UART Settings")) {
                Picker("Default Baud Rate", selection: $settings.defaultBaudRate) {
                    ForEach([9600, 19200, 38400, 57600, 115200], id: \.self) { rate in
                        Text("\(rate)").tag(rate)
                    }
                }

                Stepper(value: $settings.uartTimeout, in: 1...99) {
                    Text("UART Timeout: \(settings.uartTimeout * 100)ms")
                }

                Toggle("Auto-connect on launch", isOn: $settings.autoConnect)
                Toggle("Log received data to file", isOn: $settings.logToFile)
                Toggle("Show output in Hex format", isOn: $settings.showHexOutput)
            }

            Section(footer: Text("Changes take effect immediately unless noted.")) {
                EmptyView()
            }
        }
        .padding()
        .navigationTitle("Settings")
    }
}