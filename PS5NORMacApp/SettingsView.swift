import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: AppSettings
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 20) {
            Text("App Settings")
                .font(.largeTitle)
                .bold()
                .padding(.bottom, 10)
            
            Form {
                Section(header: Text("General")) {
                    Toggle("Automatically check for updates", isOn: $settings.autoCheckUpdates)
                    Toggle("Enable telemetry", isOn: $settings.enableTelemetry)
                    Toggle("Dark mode", isOn: $settings.darkMode)
                }
                
                Section(header: Text("Hex Viewer")) {
                    Toggle("Show advanced hex", isOn: $settings.showAdvancedHex)
                    Toggle("Highlight differences", isOn: $settings.highlightDifferences)
                    HStack {
                        Text("Hex font size:")
                        Slider(value: $settings.hexFontSize, in: 8...24, step: 1)
                        Text("\(Int(settings.hexFontSize)) pt")
                            .frame(width: 40, alignment: .leading)
                    }
                }
                
                Section(header: Text("Export")) {
                    HStack {
                        Text("Export path:")
                        TextField("Enter export path", text: $settings.exportPath)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(maxWidth: 400)
                    }
                }
                
                Section(header: Text("UART Settings")) {
                    HStack {
                        Text("Default baud rate:")
                        TextField("Baud rate", value: $settings.defaultBaudRate, formatter: NumberFormatter())
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 100)
                    }
                    Toggle("Auto connect to UART device", isOn: $settings.autoConnect)
                    Toggle("Log UART output to file", isOn: $settings.logToFile)
                    Toggle("Show hex output in logs", isOn: $settings.showHexOutput)
                    HStack {
                        Text("UART timeout (deciseconds):")
                        TextField("Timeout", value: $settings.uartTimeout, formatter: NumberFormatter())
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 60)
                    }
                }
                
                Section(header: Text("Updates")) {
                    Toggle("Enable auto-update", isOn: $settings.autoUpdateEnabled)
                }
                
                Button("Reset to Defaults") {
                    settings.resetDefaults()
                }
                .padding(.top, 20)
                .foregroundColor(.red)
            }
            .padding()
            Spacer()
        }
        .padding()
        .frame(minWidth: 500, minHeight: 600)
    }
}
