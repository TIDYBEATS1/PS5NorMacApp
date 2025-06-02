import SwiftUI

struct ContentView: View {
    @State private var message = "Preparing update..."

    var body: some View {
        VStack(spacing: 15) {
            Text("Updater")
                .font(.title)
                .bold()
            Text(message)
                .padding()
            
        }
        .frame(width: 300, height: 150)
        .onAppear {
            runUpdate()
        }
    }

    func runUpdate() {
        let args = CommandLine.arguments
        guard args.count > 1 else {
            message = "Update failed: No zip path provided."
            return
        }
        
        let zipPath = args[1]
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        
        do {
            try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
            message = "Extracting update..."
            
            let unzipTask = Process()
            unzipTask.launchPath = "/usr/bin/unzip"
            unzipTask.arguments = [zipPath, "-d", tempDir.path]
            try unzipTask.run()
            unzipTask.waitUntilExit()

            // Find the .app inside the unzipped folder
            let contents = try FileManager.default.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: nil)
            guard let newApp = contents.first(where: { $0.pathExtension == "app" }) else {
                message = "Update failed: No app found in archive."
                return
            }

            message = "Replacing old app..."
            
            let currentApp = Bundle.main.bundlePath
            let parentApp = (currentApp as NSString).deletingLastPathComponent
            
            // Replace app using rsync to preserve permissions
            let rsync = Process()
            rsync.launchPath = "/usr/bin/rsync"
            rsync.arguments = ["-a", "--delete", newApp.path + "/", parentApp + "/"]
            try rsync.run()
            rsync.waitUntilExit()
            
            message = "Update complete. Relaunching..."
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                let task = Process()
                task.launchPath = "/usr/bin/open"
                task.arguments = [parentApp]
                try? task.run()
                exit(0)
            }

        } catch {
            message = "Update failed: \(error.localizedDescription)"
        }
    }
}
