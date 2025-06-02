//
//  PS5NORMacAppApp.swift
//  PS5NORMacApp
//
//  Created by Sam Stanwell on 25/05/2025.
//

import SwiftUI
import Sparkle


@main
struct PS5NORMacApp: App {
    @StateObject private var settings = AppSettings()
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settings)
            
        }
    }
}
class AppDelegate: NSObject, NSApplicationDelegate {
    var updaterController: SPUStandardUpdaterController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
    }
}
