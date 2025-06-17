import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseCrashlytics
import FirebaseRemoteConfig
import AppKit
import UpdateKit

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
    @State private var isShowingPatchNotes = false
    @State private var pendingPatchNotes: String = ""
    @State private var patchNotesURL: String = ""
    @State private var updateInfo: UpdateInfo?
    @State private var showError: String?
    @EnvironmentObject private var updateManager: UpdateManager
    @StateObject private var updater = UpdateManager(repo: "TIDYBEATS1/PS5NorMacApp")
    @AppStorage("autoCheckForUpdates") private var autoCheck = false
    @State private var showPrompt = false
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                headerSection
                generalSettingsSection
                emcToolSection
                updateSection
                hexViewerSection
                exportPathSection
                uartSettingsSection
                telemetryLoginSection
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 24)
        }
    }
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("App Settings")
                .font(.largeTitle)
                .bold()
            Text("Customise your PS5 NOR Tool preferences below.")
                .foregroundColor(.secondary)
        }
    }
    
    private var generalSettingsSection: some View {
        GroupBox(label: Label("General", systemImage: "gearshape")) {
            VStack(alignment: .leading, spacing: 14) {
                Toggle("Automatically check for updates", isOn: $settings.autoCheckUpdates)
                Toggle("Enable Telemetry", isOn: $settings.enableTelemetry)
                Toggle("Enable Dark Mode", isOn: $isDarkMode)
                Button("Reset to Defaults", role: .destructive) {
                    withAnimation { settings.resetDefaults() }
                }
                .padding(.top, 6)
            }
        }
    }
    
    private var emcToolSection: some View {
        GroupBox(label: Label("EMC Log Decoder CLI Tool By apewalkers", systemImage: "terminal")) {
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
        }
    }
    
    private var updateSection: some View {
        GroupBox(label: Label("Updates", systemImage: "arrow.triangle.2.circlepath")) {
            VStack(alignment: .leading, spacing: 14) {
                Toggle("Automatically check for updates", isOn: $autoCheck)
                    .onChange(of: autoCheck) { newValue in
                        if newValue {
                            updater.checkForUpdates()
                        } else {
                            updater.pendingUpdate = nil
                        }
                    }
                
                Button("Check for Updates") {
                    updater.checkForUpdates()
                }
                Text(updateManager.status)
                    .font(.caption)
                    .foregroundColor(.secondary)
            
                // drive a prompt sheet from the fetched UpdateInfo
                .sheet(item: $updater.pendingUpdate) { info in
                    UpdatePromptView(
                        info:      info,
                        manager:   updater,
                        onInstall: {
                            updater.startUpdate(from: info)
                            updater.pendingUpdate = nil
                        },
                        onCancel: {
                            updater.pendingUpdate = nil
                        }
                    )
                }
            }
        }
    }
    

    private var hexViewerSection: some View {
        GroupBox(label: Label("Hex Viewer", systemImage: "eye")) {
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
        }
    }

    private var exportPathSection: some View {
        GroupBox(label: Label("Export", systemImage: "square.and.arrow.up")) {
            HStack {
                Text("Export path:")
                TextField("Enter export path", text: $settings.exportPath)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(maxWidth: 220)
            }
        }
    }

    private var uartSettingsSection: some View {
        GroupBox(label: Label("UART Settings", systemImage: "cable.connector")) {
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
        }
    }

    private var telemetryLoginSection: some View {
        Group {
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
                }
            }
        }
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

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }

    private func exportEMCToolToFolder() {
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
}
