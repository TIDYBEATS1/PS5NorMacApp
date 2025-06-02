import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: AppSettings
    @State private var showUpdateAlert = false
    @State private var latestVersion: String?
    @State private var downloadURL: URL?

    var body: some View {
        VStack {
            Text("App Version: \(AppInfo.currentVersion)")
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
                
                Section {
                    Button("Check for Updates") {
                        checkForUpdates()
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Settings")
        .alert(isPresented: $showUpdateAlert) {
            if let latest = latestVersion, let downloadURL = downloadURL {
                return Alert(
                    title: Text("Update Available"),
                    message: Text("Version \(latest) is available. Do you want to download it?"),
                    primaryButton: .default(Text("Download"), action: {
                        NSWorkspace.shared.open(downloadURL)
                    }),
                    secondaryButton: .cancel()
                )
            } else {
                return Alert(title: Text("No Updates"), message: Text("You're running the latest version."), dismissButton: .default(Text("OK")))
            }
        }
        .onAppear {
            checkForUpdates()
        }
    }
    
    private func checkForUpdates() {
        Updater.shared.checkForUpdate { url, latestVersion in
            DispatchQueue.main.async {
                if let latest = latestVersion,
                   Updater.shared.isUpdateAvailable(latestVersion: latest) {
                    self.latestVersion = latest
                    self.downloadURL = url
                    self.showUpdateAlert = true
                } else {
                    // Optional: you can notify user they're up to date or silently ignore
                    print("No updates available")
                }
            }
        }
    }
}
