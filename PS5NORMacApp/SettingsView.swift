//  SettingsView.swift
//  PS5NORMacApp
//
//  Created by Sam Stanwell on 28/05/2025.
//

import SwiftUI
import Combine
import ZIPFoundation   // ← Make sure ZIPFoundation is added via SPM

struct SettingsView: View {
    @EnvironmentObject var settings: AppSettings

    // MARK: – URLs / Constants
    private let latestReleaseAPI = URL(string: "https://api.github.com/repos/TIDYBEATS1/PS5NORMacApp/releases/latest")!
    private let downloadBaseURLString = "https://github.com/TIDYBEATS1/PS5NORMacApp/releases/download/"

    @State private var isUpdating     = false
    @State private var updateMessage  = ""
    @State private var showUpdateAlert = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("App Settings")
                .font(.largeTitle).bold()
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
                        Task {
                            await performUpdate()
                        }
                    }) {
                        HStack {
                            if isUpdating {
                                ProgressView()
                                    .scaleEffect(0.75)
                                    .padding(.trailing, 4)
                            }
                            Text("Update App")
                        }
                    }
                    .disabled(isUpdating)
                }

                Button("Reset to Defaults") {
                    settings.resetDefaults()
                }
                .padding(.top, 20)
                .foregroundColor(.red)
            }
            .padding()
            .alert("Update Status", isPresented: $showUpdateAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(updateMessage)
            }

            Spacer()
        }
        .padding()
        .frame(minWidth: 500, minHeight: 600)
    }

    // MARK: – Update Logic

    /// 1. Fetch “latest” release info from GitHub API
    /// 2. Download the ZIP into a temp file
    /// 3. Unzip to a temp folder
    /// 4. Locate the .app inside and replace the one in /Applications
    /// 5. Relaunch the new copy
    private func performUpdate() async {
        guard settings.autoUpdateEnabled else {
            updateMessage = "Auto-update is disabled."
            showUpdateAlert = true
            return
        }

        isUpdating = true
        updateMessage = ""
        showUpdateAlert = false

        do {
            // 1) Get latest release info
            let (data, _) = try await URLSession.shared.data(from: latestReleaseAPI)
            let decoder = JSONDecoder()
            struct Release: Decodable {
                let tag_name: String
            }
            let release = try decoder.decode(Release.self, from: data)
            let versionTag = release.tag_name   // e.g. “2.2.0”

            // 2) Build download URL (assumes the .zip is named “PS5NORMacApp.app.zip”)
            guard let zipURL = URL(string: "\(downloadBaseURLString)\(versionTag)/PS5NORMacApp.app.zip") else {
                throw NSError(domain: "Updater", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid download URL"])
            }

            // 3) Download into temp file
            let tempZip = FileManager.default.temporaryDirectory
                .appendingPathComponent("PS5NORMacApp_\(versionTag).zip")
            let (tempData, _) = try await URLSession.shared.data(from: zipURL)
            try tempData.write(to: tempZip)

            // 4) Unzip into a temp folder
            let tempUnzipFolder = FileManager.default.temporaryDirectory
                .appendingPathComponent("PS5NORMacApp_\(versionTag)_unzipped", isDirectory: true)
            // Clean up old folder if exists
            if FileManager.default.fileExists(atPath: tempUnzipFolder.path) {
                try FileManager.default.removeItem(at: tempUnzipFolder)
            }
            try FileManager.default.createDirectory(at: tempUnzipFolder, withIntermediateDirectories: true)
            // unzip
            try FileManager.default.unzipItem(at: tempZip, to: tempUnzipFolder)

            // 5) Locate the .app bundle inside
            let contents = try FileManager.default.contentsOfDirectory(at: tempUnzipFolder, includingPropertiesForKeys: nil)
            guard let newAppURL = contents.first(where: { $0.pathExtension == "app" }) else {
                throw NSError(domain: "Updater", code: 2, userInfo: [NSLocalizedDescriptionKey: "No .app found in archive"])
            }

            // 6) Destination (Applications folder)
            let destinationURL = URL(fileURLWithPath: "/Applications")
                .appendingPathComponent(newAppURL.lastPathComponent)

            // 7) Remove existing copy in /Applications (if any)
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }

            // 8) Move the unzipped .app into /Applications
            try FileManager.default.moveItem(at: newAppURL, to: destinationURL)

            updateMessage = "Update to \(versionTag) installed. Relaunching..."
            showUpdateAlert = true

            // 9) Relaunch
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                let bundleID = Bundle.main.bundleIdentifier!
                let task = Process()
                task.launchPath = "/usr/bin/open"
                task.arguments = ["-b", bundleID]
                try? task.run()

                // Quit current app
                NSApp.terminate(nil)
            }

        } catch {
            updateMessage = "Update failed: \(error.localizedDescription)"
            showUpdateAlert = true
        }

        isUpdating = false
    }
}

#if DEBUG
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(AppSettings())
    }
}
#endif
