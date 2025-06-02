//
//  Telemetry.swift
//  PS5NORMacApp
//
//  Created by Sam Stanwell on 02/06/2025.
//


import Foundation
import FirebaseCrashlytics

enum Telemetry {
    
    /// Logs a non-fatal error to Firebase Crashlytics.
    static func logError(_ error: Error, context: String? = nil) {
        if let context = context {
            Crashlytics.crashlytics().log("[Context] \(context)")
        }
        Crashlytics.crashlytics().record(error: error)
    }
    
    /// Logs a custom string message to Firebase Crashlytics.
    static func logMessage(_ message: String) {
        Crashlytics.crashlytics().log(message)
    }

    /// Adds a non-personal custom key-value pair to help with diagnostics.
    static func setValue(_ value: Any, forKey key: String) {
        Crashlytics.crashlytics().setCustomValue(value, forKey: key)
    }
    
    /// Force a crash (for testing only).
    static func triggerTestCrash() {
        fatalError("Test crash triggered intentionally.")
    }
}