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
    @StateObject var updater = Updater.shared  // or your Updater instance

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settings)
                .environmentObject(updater)
                .onAppear {
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
}
