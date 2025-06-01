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
