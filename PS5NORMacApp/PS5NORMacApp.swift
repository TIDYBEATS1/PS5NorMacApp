//
//  PS5NORMacAppApp.swift
//  PS5NORMacApp
//
//  Created by Sam Stanwell on 25/05/2025.
//

import SwiftUI
@main
struct PS5NORMacApp: App {
    @StateObject private var appSettings = AppSettings()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appSettings)
        }
    }
}
