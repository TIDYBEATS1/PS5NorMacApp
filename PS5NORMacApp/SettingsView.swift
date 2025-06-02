import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseCrashlytics
struct SettingsView: View {
    @EnvironmentObject var settings: AppSettings
    @State private var isUpdating = false
    @State private var updateStatus = ""
    @AppStorage("isDarkMode") private var isDarkMode: Bool = false
    @StateObject private var auth = AuthManager()
    // Reset password states
    @State private var resetEmail = ""
    @State private var resetMessage = ""
    @State private var resetIsError = false
    @EnvironmentObject var authManager: AuthManager

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
            HStack(alignment: .top, spacing: 20) {
                // Left Column: All settings except Telemetry Login
                VStack(alignment: .leading, spacing: 20) {
                    Text("App Settings")
                        .font(.largeTitle)
                        .bold()
                        .padding(.bottom, 10)
                    
                    GroupBoxView(title: "General") {
                        Toggle("Automatically check for updates", isOn: $settings.autoCheckUpdates)
                        Toggle("Enable Telemetry", isOn: $settings.enableTelemetry)
                        Toggle("Enable Dark Mode", isOn: $isDarkMode)
                        Button("Reset to Defaults") {
                            withAnimation {
                                settings.resetDefaults()
                                
                            }
                        }
                    }
                    
                    GroupBoxView(title: "Updates") {
                        Toggle("Enable auto-update", isOn: $settings.autoUpdateEnabled)
                        Button(action: {
                            checkForUpdates()
                        }) {
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
                    
                    GroupBoxView(title: "Hex Viewer") {
                        Toggle("Show advanced hex", isOn: $settings.showAdvancedHex)
                        Toggle("Highlight differences", isOn: $settings.highlightDifferences)
                        HStack {
                            Text("Hex font size:")
                            Slider(value: $settings.hexFontSize, in: 8...24, step: 1)
                            Text("\(Int(settings.hexFontSize)) pt")
                                .frame(width: 40, alignment: .leading)
                        }
                    }
                    
                    GroupBoxView(title: "Export") {
                        HStack {
                            Text("Export path:")
                            TextField("Enter export path", text: $settings.exportPath)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(maxWidth: 400)
                        }
                    }
                    
                    GroupBoxView(title: "UART Settings") {
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
                
                // Right Column: Only shown if telemetry is enabled
                if settings.enableTelemetry {
                    VStack(alignment: .leading) {
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
                                    
                                    Divider()
                                        .padding(.vertical, 10)
                                    
                                    Text("Forgot Password?")
                                        .font(.headline)
                                    
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
            }
            .padding()
        }
    }
    
    // MARK: - Update Methods
    
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
                   let assets = json["assets"] as? [[String: Any]],
                   let zipURLString = assets.first?["browser_download_url"] as? String {
                    
                    if latestVersion.compare(currentVersion, options: .numeric) == .orderedDescending {
                        DispatchQueue.main.async {
                            updateStatus = "Update available: \(latestVersion). Downloading..."
                        }
                        downloadAndUnzip(from: zipURLString)
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
                unzipTask.launchPath = "/usr/bin/unzip"
                unzipTask.arguments = ["-o", destinationURL.path, "-d", downloads.path]
                unzipTask.launch()
                unzipTask.waitUntilExit()
                
                DispatchQueue.main.async {
                    isUpdating = false
                    updateStatus = "Update downloaded to Downloads folder."
                }
            } catch {
                DispatchQueue.main.async {
                    isUpdating = false
                    updateStatus = "Error during update: \(authManager.errorMessage = error.localizedDescription)"
                    ErrorLogger.log(error, additionalInfo: ["source": "SettingsView Update Error"])  // change "login" to relevant function name
                }
            }
        }
        
        task.resume()
    }
    
    func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    // MARK: - Password Reset Method
    
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
}

struct GroupBoxView<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        GroupBox(label: Text(title).font(.headline)) {
            VStack(alignment: .leading, spacing: 10) {
                content
            }
            .padding()
        }
    }
}
