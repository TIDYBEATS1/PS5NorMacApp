//
//  SparkleUpdaterController.swift
//  PS5NORMacApp
//
//  Created by Sam Stanwell on 29/05/2025.
//


import SwiftUI
import Sparkle

class SparkleUpdaterController: ObservableObject {
    @Published var checksForUpdatesAutomatically: Bool {
        didSet {
            SUUpdater.shared()?.automaticallyChecksForUpdates = checksForUpdatesAutomatically
        }
    }

    init() {
        self.checksForUpdatesAutomatically = SUUpdater.shared()?.automaticallyChecksForUpdates ?? true
    }
}

struct SettingsView: View {
    @StateObject private var updaterController = SparkleUpdaterController()

    var body: some View {
        Form {
            Toggle("Check Automatically for Updates", isOn: $updaterController.checksForUpdatesAutomatically)
        }
        .padding()
    }
}