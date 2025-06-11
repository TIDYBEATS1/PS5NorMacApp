import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseCrashlytics
import AppKit

struct SettingsView: View {
    @EnvironmentObject var settings: AppSettings
    @State private var isUpdating = false
    @State private var updateStatus = ""
    @AppStorage("isDarkMode") private var isDarkMode: Bool = false
    @StateObject private var auth = AuthManager()
    @State private var resetEmail = ""
    @State private var resetMessage = ""
    @State private var resetIsError = false
    @EnvironmentObject var authManager: AuthManager
    @State private var selectedFile: URL? = nil
    @Binding var selectedBinFile: URL?
    @State private var showPatchNotes = false
    @State private var patchNotesContent = ""
    @State private var showingPatchNotes = false
    @State private var patchNotes: String = ""
    @State private var updateURL: String? = nil
    @State private var isShowingPatchNotes = false
    @State private var patchNotesURL: String? = nil
    @State private var pendingPatchNotes: String = ""
    func logError(_ error: Error) {
        Crashlytics.crashlytics().record(error: error)
    }
    
    static func configureFirebase() {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("App Settings")
                        .font(.largeTitle)
                        .bold()
                    Text("Customise your PS5 NOR Tool preferences below.")
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 6)
                
                HStack(alignment: .top, spacing: 28) {
                    VStack(alignment: .leading, spacing: 16) {
                        GroupBox {
                            VStack(alignment: .leading, spacing: 14) {
                                Toggle("Automatically check for updates", isOn: $settings.autoCheckUpdates)
                                Toggle("Enable Telemetry", isOn: $settings.enableTelemetry)
                                Toggle("Enable Dark Mode", isOn: $isDarkMode)
                            }
                        } label: {
                            Label("General", systemImage: "gearshape")
                        }
                        
                        Button(role: .destructive) {
                            withAnimation { settings.resetDefaults() }
                        } label: {
                            Text("Reset to Defaults")
                        }
                        .padding(.top, 6)
                    }
                    
                    VStack(alignment: .leading, spacing: 10) {
                        GroupBox {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Export and run the NOR EMC Log Decoder command-line tool.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                                Button("Export EMC Tool to Folder…") {
                                    exportEMCToolToFolder()
                                }
                                .buttonStyle(.borderedProminent)
                                if let file = selectedBinFile {
                                    HStack(spacing: 5) {
                                        Image(systemName: "doc.richtext")
                                        Text(file.lastPathComponent)
                                            .font(.footnote)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        } label: {
                            Label("EMC Log Decoder CLI Tool By apewalkers ", systemImage: "terminal")
                        }
                    }
                }
                .padding(.bottom, 10)
                
                HStack(alignment: .top, spacing: 28) {
                    VStack(alignment: .leading, spacing: 16) {
                        GroupBox {
                            VStack(alignment: .leading, spacing: 14) {
                                Toggle("Enable auto-update", isOn: $settings.autoUpdateEnabled)
                                Button(action: { checkForUpdates() }) {
                                    HStack {
                                        Image(systemName: "arrow.down.circle")
                                        Text("Check for Updates")
                                        if isUpdating {
                                            Spacer()
                                            ProgressView()
                                        }
                                    }
                                }
                                .disabled(isUpdating)
                                if !updateStatus.isEmpty {
                                    Text(updateStatus)
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                        .padding(.top, 5)
                                }
                            }
                        } label: {
                            Label("Updates", systemImage: "arrow.triangle.2.circlepath")
                        }
                    }
                    VStack(alignment: .leading, spacing: 16) {
                        GroupBox {
                            VStack(alignment: .leading, spacing: 14) {
                                Toggle("Show advanced hex", isOn: $settings.showAdvancedHex)
                                Toggle("Highlight differences", isOn: $settings.highlightDifferences)
                                HStack {
                                    Text("Hex font size:")
                                    Slider(value: $settings.hexFontSize, in: 8...24, step: 1)
                                    Text("\(Int(settings.hexFontSize)) pt")
                                        .frame(width: 40, alignment: .leading)
                                }
                            }
                        } label: {
                            Label("Hex Viewer", systemImage: "eye")
                        }
                    }
                    VStack(alignment: .leading, spacing: 16) {
                        GroupBox {
                            HStack {
                                Text("Export path:")
                                TextField("Enter export path", text: $settings.exportPath)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .frame(maxWidth: 220)
                            }
                        } label: {
                            Label("Export", systemImage: "square.and.arrow.up")
                        }
                    }
                    VStack(alignment: .leading, spacing: 16) {
                        GroupBox {
                            VStack(alignment: .leading, spacing: 12) {
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
                        } label: {
                            Label("UART Settings", systemImage: "cable.connector")
                        }
                    }
                }
                .padding(.bottom, 24)
                
                if settings.enableTelemetry {
                    GroupBox(label: Label("Telemetry Login", systemImage: "person.crop.circle")) {
                        VStack(alignment: .leading, spacing: 12) {
                            if authManager.isLoggedIn {
                                Text("Logged in as: \(authManager.username)")
                                    .foregroundColor(.green)
                                Button("Logout") {
                                    authManager.logout()
                                }
                                .foregroundColor(.red)
                            } else {
                                TextField("Email", text: $authManager.username)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .disableAutocorrection(true)
                                SecureField("Password", text: $authManager.password)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                Toggle("Register instead of Login", isOn: $authManager.isRegisterMode)
                                Image(systemName: "info.circle")
                                    .help("Telemetry only sends crash/error data to TIDYBEATS1.")
                                Button(action: {
                                    if authManager.isRegisterMode {
                                        authManager.register()
                                    } else {
                                        authManager.login()
                                    }
                                }) {
                                    Text(authManager.isRegisterMode ? "Register" : "Login")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.borderedProminent)
                                if !authManager.errorMessage.isEmpty {
                                    Text(authManager.errorMessage)
                                        .foregroundColor(.red)
                                }
                                Divider().padding(.vertical, 10)
                                Text("Forgot Password?").font(.headline)
                                TextField("Enter email for reset", text: $resetEmail)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .disableAutocorrection(true)
                                Button("Send Password Reset Email") {
                                    sendPasswordReset(email: resetEmail)
                                }
                                .buttonStyle(.bordered)
                                .disabled(resetEmail.isEmpty)
                                if !resetMessage.isEmpty {
                                    Text(resetMessage)
                                        .foregroundColor(resetIsError ? .red : .green)
                                        .font(.caption)
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 24)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .sheet(isPresented: $isShowingPatchNotes) {
            PatchNotesSheetView(
                notes: pendingPatchNotes,
                onUpdate: {
                    if let url = patchNotesURL {
                        downloadAndUnzip(from: url)
                    }
                    isShowingPatchNotes = false
                },
                onCancel: {
                    isShowingPatchNotes = false
                    isUpdating = false
                }
            )
        }
    }
    private func downloadAndUnzip(from urlString: String) {
        guard let url = URL(string: urlString) else {
            DispatchQueue.main.async {
                isUpdating = false
                updateStatus = "Invalid download URL."
            }
            return
        }

        let task = URLSession.shared.downloadTask(with: url) { tempURL, response, error in
            guard let tempURL = tempURL else {
                DispatchQueue.main.async {
                    isUpdating = false
                    updateStatus = "Download failed."
                }
                return
            }

            let fileManager = FileManager.default
            let downloads = fileManager.urls(for: .downloadsDirectory, in: .userDomainMask).first!
            let destinationURL = downloads.appendingPathComponent("PS5NORMacApp.zip")
            let appPath = downloads.appendingPathComponent("PS5NORMacApp.app")

            do {
                if fileManager.fileExists(atPath: destinationURL.path) {
                    try fileManager.removeItem(at: destinationURL)
                }
                try fileManager.moveItem(at: tempURL, to: destinationURL)

                if fileManager.fileExists(atPath: appPath.path) {
                    try fileManager.removeItem(at: appPath)
                }

                let unzipTask = Process()
                unzipTask.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
                unzipTask.arguments = ["-o", destinationURL.path, "-d", downloads.path]

                try unzipTask.run()
                unzipTask.waitUntilExit()

                DispatchQueue.main.async {
                    isUpdating = false
                    updateStatus = "Update downloaded to Downloads folder."
                }
            } catch {
                DispatchQueue.main.async {
                    isUpdating = false
                    updateStatus = "Error during update: \(error.localizedDescription)"
                    ErrorLogger.log(error, additionalInfo: ["source": "SettingsView Update Error"])
                }
            }
        }

        task.resume()
    }
    private func checkForUpdates() {
        isUpdating = true
        updateStatus = "Checking for updates..."

        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
        let apiURL = URL(string: "https://api.github.com/repos/TIDYBEATS1/PS5NorMacApp/releases/latest")!

        URLSession.shared.dataTask(with: apiURL) { data, response, error in
            guard let data = data, error == nil else {
                DispatchQueue.main.async {
                    isUpdating = false
                    updateStatus = "Failed to fetch release info."
                }
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let latestVersion = json["tag_name"] as? String,
                   let releaseNotes = json["body"] as? String,
                   let assets = json["assets"] as? [[String: Any]],
                   let zipURLString = assets.first?["browser_download_url"] as? String {

                    if latestVersion.compare(currentVersion, options: .numeric) == .orderedDescending {
                        DispatchQueue.main.async {
                            pendingPatchNotes = releaseNotes
                            patchNotesURL = zipURLString
                            isShowingPatchNotes = true
                        }
                    } else {
                        DispatchQueue.main.async {
                            isUpdating = false
                            updateStatus = "You're on the latest version (\(currentVersion))."
                        }
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    isUpdating = false
                    updateStatus = "Error parsing release info."
                }
            }
        }.resume()
    }
    
    private func sendPasswordReset(email: String) {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard isValidEmail(trimmedEmail) else {
            resetMessage = "Please enter a valid email address."
            resetIsError = true
            return
        }
        
        Auth.auth().sendPasswordReset(withEmail: trimmedEmail) { error in
            DispatchQueue.main.async {
                if let error = error {
                    resetMessage = error.localizedDescription
                    resetIsError = true
                } else {
                    resetMessage = "Password reset email sent successfully!"
                    resetIsError = false
                    resetEmail = ""
                }
            }
        }
    }
    
    
    func exportEMCToolToFolder() {
        let openPanel = NSOpenPanel()
        openPanel.title = "Choose a folder to export CLI and script"
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.allowsMultipleSelection = false
        openPanel.canCreateDirectories = true
        
        openPanel.begin { response in
            guard response == .OK, let folderURL = openPanel.url else { return }
            let fileManager = FileManager.default
            
            guard
                let cliURL = Bundle.main.url(forResource: "EmcLogGenerator", withExtension: nil),
                let pyURL = Bundle.main.url(forResource: "decode_emc", withExtension: "py")
            else {
                print("Missing CLI or Python script in app bundle")
                return
            }
            
            let destCLI = folderURL.appendingPathComponent("EmcLogGenerator")
            let destPY = folderURL.appendingPathComponent("decode_emc.py")
            
            do {
                if fileManager.fileExists(atPath: destCLI.path) {
                    try fileManager.removeItem(at: destCLI)
                }
                if fileManager.fileExists(atPath: destPY.path) {
                    try fileManager.removeItem(at: destPY)
                }
                try fileManager.copyItem(at: cliURL, to: destCLI)
                try fileManager.copyItem(at: pyURL, to: destPY)
                try fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: destCLI.path)
                print("✅ CLI and script exported to folder.")
            } catch {
                print("Export failed: \(error)")
            }
        }
    }
    
    func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
}
