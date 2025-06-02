import Foundation
import AppKit

struct UpdaterHelper {
    static func runUpdate(completion: @escaping (Bool) -> Void) {
        let arguments = CommandLine.arguments

        guard arguments.count >= 3 else {
            print("Missing arguments.")
            completion(false)
            return
        }

        let newAppPath = arguments[1]
        let currentAppPath = arguments[2]

        let tempFolder = (newAppPath as NSString).deletingLastPathComponent

        // Wait for the main app to quit
        sleep(2)

        // Remove existing app
        do {
            try FileManager.default.removeItem(atPath: currentAppPath)
        } catch {
            print("Failed to delete old app: \(error)")
            completion(false)
            return
        }

        // Copy new app
        do {
            try FileManager.default.copyItem(atPath: newAppPath, toPath: currentAppPath)
        } catch {
            print("Failed to copy new app: \(error)")
            completion(false)
            return
        }

        // Delete temp folder
        try? FileManager.default.removeItem(atPath: tempFolder)

        // Relaunch main app
        let task = Process()
        task.launchPath = "/usr/bin/open"
        task.arguments = [currentAppPath]
        task.launch()

        completion(true)
    }
}
