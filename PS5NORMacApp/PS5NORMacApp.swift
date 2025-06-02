//
//  PS5NORMacAppApp.swift
//  PS5NORMacApp
//
//  Created by Sam Stanwell on 25/05/2025.
//

import SwiftUI
import AppKit

@main
struct PS5NORMacApp: App {
    @StateObject private var settings = AppSettings()


    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settings)
                .onAppear {
                    // Check for updates when app launches
                    Updater.shared.checkForUpdate { downloadURL, latestVersion in
                        if let latestVersion = latestVersion,
                           Updater.shared.isUpdateAvailable(latestVersion: latestVersion) {
                            DispatchQueue.main.async {
                                promptUpdate(downloadURL: downloadURL, version: latestVersion)
                            }
                        }
                    }
                }
        }

        // Add a separate window group for Settings window
        WindowGroup("Settings") {
            SettingsView()
                .environmentObject(settings)
        }
        .commands {
            CommandGroup(replacing: .appSettings) {
                Button("Settings…") {
                    NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }
    }

    func promptUpdate(downloadURL: URL?, version: String) {
        let alert = NSAlert()
        alert.messageText = "Update Available"
        alert.informativeText = "Version \(version) is available. Do you want to download it now?"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Download")
        alert.addButton(withTitle: "Later")

        if alert.runModal() == .alertFirstButtonReturn {
            if let url = downloadURL {
                Updater.shared.downloadUpdate(from: url) { localURL in
                    DispatchQueue.main.async {
                        if let localURL = localURL {
                            NSWorkspace.shared.activateFileViewerSelecting([localURL])
                            let doneAlert = NSAlert()
                            doneAlert.messageText = "Download Complete"
                            doneAlert.informativeText = "Please open the downloaded file to install the update."
                            doneAlert.runModal()
                        } else {
                            let errorAlert = NSAlert()
                            errorAlert.messageText = "Download Failed"
                            errorAlert.runModal()
                        }
                    }
                }
            }
        }
    }
}
