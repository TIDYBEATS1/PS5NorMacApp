import SwiftUI
import AppKit
import Combine
import FirebaseAuth
import UniformTypeIdentifiers
import FirebaseRemoteConfig
import UpdateKit

struct ContentView: View {
    @EnvironmentObject var versionChecker: VersionChecker
    @State private var disableEditing: Bool = false
    @State private var fileData: Data = Data()
    @State private var selectedFile: URL? = nil
    @State private var serialNumber: String = "..."
    @State private var motherboardSerial: String = "..."
    @State private var boardVariant: String = "..."
    @State private var ps5Model: String = "..."
    @State private var fileSize: String = "..."
    @State private var wifiMacAddress: String = "..."
    @State private var lanMacAddress: String = "..."
    @State private var modifiedSerialNumber: String = ""
    @State private var modifiedBoardVariant: String = ""
    @State private var modifiedPs5Model: String = ""
    @State private var modifiedWifiMacAddress: String = ""
    @State private var modifiedLanMacAddress: String = ""
    @State private var showSaveConfirmation: Bool = false
    @State private var showDisclaimer: Bool = true
    @State private var selectedModelTab: ResultsView.PS5ModelTab = .phat
    @State private var selectedSidebarItem: SidebarItem? = .results
    @EnvironmentObject var settings: AppSettings
    @State private var githubLatestVersion: String = "Checking..."
    @StateObject private var authManager = AuthManager()
    @StateObject private var errorLookupViewModel = ErrorLookupViewModel()
    @StateObject private var uartViewModel = UARTViewModel()
    @State private var editingDisabled: Bool = false
    @StateObject var updateChecker = UpdateChecker()
    @State private var showUpdateSheet = false
    @State private var showUpdatePrompt = false
    @State private var currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    private let groupedBoardVariantOptions: [(header: String, models: [String])] = [
        ("PS5 (FAT/Standard)", [
            "CFI-1000A - Japan (Disc Edition)",
            "CFI-1000B - Japan (Digital Edition)",
            "CFI-1002A - Australia (Disc Edition)",
            "CFI-1002B - Australia (Digital Edition)",
            "CFI-1003A - UK/Ireland (Disc Edition)",
            "CFI-1003B - UK/Ireland (Digital Edition)",
            "CFI-1004A - Europe/Middle East/Africa (Disc Edition)",
            "CFI-1004B - Europe/Middle East/Africa (Digital Edition)",
            "CFI-1008A - Russia, Ukraine, India, Central Asia (Disc Edition)",
            "CFI-1008B - Russia, Ukraine, India, Central Asia (Digital Edition)",
            "CFI-1009A - China (Disc Edition)",
            "CFI-1009B - China (Digital Edition)",
            "CFI-1014A - South America (Disc Edition)",
            "CFI-1014B - South America (Digital Edition)",
            "CFI-1015A - US/Canada/Mexico (Disc Edition)",
            "CFI-1015B - US/Canada/Mexico (Digital Edition)",
            "CFI-1016A - Europe/Middle East/Africa (Disc Edition)",
            "CFI-1016B - Europe/Middle East/Africa (Digital Edition)",
            "CFI-1018A - Southeast Asia/HK/Macau/TW/S.Korea (Disc Edition)",
            "CFI-1018B - Southeast Asia/HK/Macau/TW/S.Korea (Digital Edition)",
            "CFI-1100A - Japan (Disc Edition)",
            "CFI-1100B - Japan (Digital Edition)",
            "CFI-1102A - Australia (Disc Edition)",
            "CFI-1102B - Australia (Digital Edition)",
            "CFI-1108A - Russia, Ukraine, India, Central Asia (Disc Edition)",
            "CFI-1108B - Russia, Ukraine, India, Central Asia (Digital Edition)",
            "CFI-1109A - China (Disc Edition)",
            "CFI-1109B - China (Digital Edition)",
            "CFI-1114A - South America (Disc Edition)",
            "CFI-1114B - South America (Digital Edition)",
            "CFI-1115A - US/Canada/Mexico (Disc Edition)",
            "CFI-1115B - US/Canada/Mexico (Digital Edition)",
            "CFI-1116A - Europe/Middle East/Africa (Disc Edition)",
            "CFI-1116B - Europe/Middle East/Africa (Digital Edition)",
            "CFI-1118A - Southeast Asia/HK/Macau/TW/S.Korea (Disc Edition)",
            "CFI-1118B - Southeast Asia/HK/Macau/TW/S.Korea (Digital Edition)",
            "CFI-1200A - Japan (Disc Edition)",
            "CFI-1200B - Japan (Digital Edition)",
            "CFI-1208A - Russia, Ukraine, India, Central Asia (Disc Edition)",
            "CFI-1208B - Russia, Ukraine, India, Central Asia (Digital Edition)",
            "CFI-1215A - US/Canada/Mexico (Disc Edition)",
            "CFI-1215B - US/Canada/Mexico (Digital Edition)",
            "CFI-1216A - Europe (Disc Edition)",
            "CFI-1216B - Europe (Digital Edition)",
            "CFI-1218A - Southeast Asia/HK/Macau/TW/S.Korea (Disc Edition)",
            "CFI-1218B - Southeast Asia/HK/Macau/TW/S.Korea (Digital Edition)"
        ]),
        ("PS5 Slim", [
            "CFI-2000A - Japan (Disc Edition)",
            "CFI-2000B - Japan (Digital Edition)",
            "CFI-2002A - Australia (Disc Edition)",
            "CFI-2002B - Australia (Digital Edition)",
            "CFI-2015A - US/Canada/Mexico (Disc Edition)",
            "CFI-2015B - US/Canada/Mexico (Digital Edition)",
            "CFI-2016A - Europe (Disc Edition)",
            "CFI-2016B - Europe (Digital Edition)",
            "CFI-2018A - Southeast Asia/HK/Macau/TW/S.Korea (Disc Edition)",
            "CFI-2018B - Southeast Asia/HK/Macau/TW/S.Korea (Digital Edition)"
        ]),
        ("PS5 Pro", [
            "CFI-7000B - Japan (Digital Edition)",
            "CFI-7002B - Australia (Digital Edition)",
            "CFI-7014B - South America (Digital Edition)",
            "CFI-7019B - US/Canada/Mexico (Digital Edition)",
            "CFI-7020B - Mexico (Digital Edition)",
            "CFI-7021B - Europe/Arab Emirates (Digital Edition)",
            "CFI-7022B - Southeast Asia/HK/Macau/TW/S.Korea (Digital Edition)"
        ]),
        ("Special/Limited Editions", [
            "CFI-1016A - Europe (Disc Edition, Ratchet & Clank)",
            "CFI-1116A - Europe (Disc Edition, Horizon Forbidden West)",
            "CFI-1216A - Europe (Disc Edition, Call of Duty MWII)",
            "CFI-20XXB - Global (Digital Edition, 30th Anniversary)",
            "CFI-70XXB - Global (Digital Edition, 30th Anniversary Limited Edition)"
        ]),
        ("TestKit/DevKit", [
            "DFI-T1000AA - Global (TestKit)",
            "DFI-D1000AA - Global (DevKit)"
        ])
    ]
    
    enum SidebarItem: String, CaseIterable, Identifiable {
        case results = "Results"
        case errorCodes = "Error Codes"
        case settings = "Settings"
        case hexEditor = "Hex Editor"
        case uart = "UART"
        case errorLog = "Compare"
        var id: String { rawValue }
        var iconName: String {
            switch self {
            case .results: return "doc.text.magnifyingglass"
            case .errorCodes: return "exclamationmark.triangle"
            case .settings: return "gearshape"
            case .hexEditor: return "chevron.left.slash.chevron.right"
            case .uart: return "terminal"
            case .errorLog: return "ladybug"
            }
        }
    }
    
    var body: some View {
        NavigationSplitView {
            List(SidebarItem.allCases, selection: $selectedSidebarItem) { item in
                NavigationLink(value: item) {
                    Label(item.rawValue, systemImage: item.iconName)
                        .padding(.vertical, 2)
                }
            }
            .listStyle(.sidebar)
            .frame(minWidth: 150, idealWidth: 180)
            .navigationTitle("PS5 NOR Modifier")
        } detail: {
            detailView
        }
        
        // MARK: Disclaimer Sheet
        .sheet(isPresented: $showDisclaimer) {
            DisclaimerView(isPresented: $showDisclaimer)
                .interactiveDismissDisabled(true)
                .frame(width: 400, height: 200)
        }
        
        // MARK: Patch Notes Sheet (Sparkle)
        
        // MARK: On Appear
        .onAppear {
            showDisclaimer = true
            showUpdateSheet = false // 👈 shows update prompt on launch
        }
        .onAppear {
            showDisclaimer = true
            
            GitHubReleaseChecker.fetchLatestRelease(repo: "TIDYBEATS1/PS5NorMacApp") { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let release):
                        githubLatestVersion = release.version      // ← use .version
                    case .failure:
                        githubLatestVersion = "Unavailable"
                    }
                }
            }
        }
    }
        
        
        @ViewBuilder
        var detailView: some View {
            switch selectedSidebarItem {
            case .results:
                ResultsView(
                    githubLatestVersion: githubLatestVersion, fileData: $fileData,
                    selectedFile: $selectedFile,
                    serialNumber: $serialNumber,
                    motherboardSerial: $motherboardSerial,
                    boardVariant: $boardVariant,
                    ps5Model: $ps5Model,
                    fileSize: $fileSize,
                    wifiMacAddress: $wifiMacAddress,
                    lanMacAddress: $lanMacAddress,
                    modifiedSerialNumber: $modifiedSerialNumber,
                    modifiedBoardVariant: $modifiedBoardVariant,
                    modifiedPs5Model: $modifiedPs5Model,
                    modifiedWifiMacAddress: $modifiedWifiMacAddress,
                    modifiedLanMacAddress: $modifiedLanMacAddress,
                    showSaveConfirmation: $showSaveConfirmation,
                    selectedModelTab: $selectedModelTab,
                    editingDisabled: $editingDisabled,
                    groupedBoardVariantOptions: groupedBoardVariantOptions
                )
                .environmentObject(settings)
            case .hexEditor:
                HexEditorView(data: $fileData)
                    .environmentObject(settings)
                    .frame(minWidth: 700, minHeight: 400)
            case .errorCodes:
                ErrorLookupView(
                    errorCodeInput: .constant(""),
                    errorDescription: .constant(""),
                    errorSolution: .constant(""),
                    viewModel: errorLookupViewModel,
                    uartViewModel: uartViewModel
                )
                .padding()
            case .uart:
                UARTView()
                    .environmentObject(uartViewModel)
                    .padding()
            case .errorLog:
                NORDiffView()
            case .settings, .none:
                SettingsView(selectedBinFile: .constant(nil))
                    .environmentObject(authManager)
                    .padding(.bottom)
                    .frame(minWidth: 600, maxWidth: .infinity, maxHeight: .infinity)
                    .onAppear { errorLookupViewModel.loadErrorCodes() }
                    .environmentObject(settings)
            }
        }
    }

extension Data {
    mutating func writeAsciiString(_ string: String, offset: Int, length: Int) {
        guard offset >= 0, offset + length <= self.count else { return }
        var bytes = [UInt8](repeating: 0x00, count: length)
        let asciiString = string.prefix(length)
        let asciiBytes = Array(asciiString.utf8)
        for i in 0..<Swift.min(asciiBytes.count, length) {
            bytes[i] = asciiBytes[i]
        }
        self.replaceSubrange(offset..<offset+length, with: bytes)
    }
    mutating func writeBytes(_ bytes: [UInt8], offset: Int) {
        guard offset >= 0, offset + bytes.count <= self.count else { return }
        self.replaceSubrange(offset..<offset+bytes.count, with: bytes)
    }
}

extension Color {
    static let customBlue = Color(hex: "006FCD")
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        guard hex.count == 6 else { self.init(.sRGB, red: 0, green: 0, blue: 0, opacity: 1); return }
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: 1)
    }
}

func showBinFilePicker(completion: @escaping (URL?) -> Void) {
    let panel = NSOpenPanel()
    panel.title = "Select a .bin File"
    panel.allowedContentTypes = [.data] // or [.item] if .bin isn't recognized
    panel.allowsMultipleSelection = false
    panel.canChooseDirectories = false

    panel.begin { result in
        if result == .OK, let url = panel.url {
            print("✅ File selected: \(url.lastPathComponent)")
            completion(url)
        } else {
            print("⚠️ User cancelled file selection")
            completion(nil)
        }
    }
}

struct DisclaimerView: View {
    @Binding var isPresented: Bool
    var body: some View {
        VStack(spacing: 20) {
            Text("Experimental Software").font(.headline)
            Text("This application is experimental. Use at your own risk. The author is not responsible for any damage or loss resulting from use.")
                .multilineTextAlignment(.center).padding(.horizontal)
            HStack {
                Button("Quit") { NSApplication.shared.terminate(nil) }.keyboardShortcut(.defaultAction)
                Spacer()
                Button("I Understand") { isPresented = false }.keyboardShortcut(.cancelAction)
            }.padding(.horizontal, 40)
        }.padding()
    }
}
