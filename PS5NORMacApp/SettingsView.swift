import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: AppSettings
    
    @State private var isUpdating = false
    @State private var updateStatus = ""
    
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
                    
                    Button(action: {
                        checkForUpdates()
                    }) {
                        HStack {
                            Image(systemName: "arrow.down.circle")
                            Text("Check for Updates")
                        }
                    }
                    .disabled(isUpdating)
                    
                    if !updateStatus.isEmpty {
                        Text(updateStatus)
                            .foregroundColor(.secondary)
                            .font(.caption)
                            .padding(.top, 5)
                    }
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

    func checkForUpdates() {
        isUpdating = true
        updateStatus = "Checking for updates..."

        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
        let apiURL = URL(string: "https://api.github.com/repos/TIDYBEATS1/PS5NorMacApp/releases/latest")!

        URLSession.shared.dataTask(with: apiURL) { data, response, error in
            guard let data = data, error == nil else {
                DispatchQueue.main.async {
                    isUpdating = false
                    updateStatus = "Failed to fetch release info."
                }
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let latestVersion = json["tag_name"] as? String,
                   let assets = json["assets"] as? [[String: Any]],
                   let zipURLString = assets.first?["browser_download_url"] as? String {

                    if latestVersion.compare(currentVersion, options: .numeric) == .orderedDescending {
                        DispatchQueue.main.async {
                            updateStatus = "Update available: \(latestVersion). Downloading..."
                        }
                        downloadAndUnzip(from: zipURLString)
                    } else {
                        DispatchQueue.main.async {
                            isUpdating = false
                            updateStatus = "You're on the latest version (\(currentVersion))."
                        }
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    isUpdating = false
                    updateStatus = "Error parsing release info."
                }
            }
        }.resume()
    }

    func downloadAndUnzip(from urlString: String) {
        guard let url = URL(string: urlString) else {
            DispatchQueue.main.async {
                isUpdating = false
                updateStatus = "Invalid download URL."
            }
            return
        }

        let task = URLSession.shared.downloadTask(with: url) { tempURL, response, error in
            guard let tempURL = tempURL else {
                DispatchQueue.main.async {
                    isUpdating = false
                    updateStatus = "Download failed."
                }
                return
            }

            let fileManager = FileManager.default
            let downloads = fileManager.urls(for: .downloadsDirectory, in: .userDomainMask).first!
            let destinationURL = downloads.appendingPathComponent("PS5NORMacApp.zip")
            let appPath = downloads.appendingPathComponent("PS5NORMacApp.app")

            do {
                if fileManager.fileExists(atPath: destinationURL.path) {
                    try fileManager.removeItem(at: destinationURL)
                }
                try fileManager.moveItem(at: tempURL, to: destinationURL)

                if fileManager.fileExists(atPath: appPath.path) {
                    try fileManager.removeItem(at: appPath)
                }

                // Unzip
                let unzipTask = Process()
                unzipTask.launchPath = "/usr/bin/unzip"
                unzipTask.arguments = ["-o", destinationURL.path, "-d", downloads.path]
                unzipTask.launch()
                unzipTask.waitUntilExit()

                DispatchQueue.main.async {
                    isUpdating = false
                    updateStatus = "Update downloaded to Downloads folder."
                }
            } catch {
                DispatchQueue.main.async {
                    isUpdating = false
                    updateStatus = "Error during update: \(error.localizedDescription)"
                }
            }
        }

        task.resume()
    }
}
