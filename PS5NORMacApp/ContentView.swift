import SwiftUI
import AppKit
import Combine
import FirebaseAuth
import UniformTypeIdentifiers

struct ContentView: View {
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
    @State private var fileData: Data = Data()
    @State private var errorCodeInput: String = ""
    @State private var selectedFileURL: URL? = nil
    @State private var errorDescription: String = ""
    @State private var showFileImporter = false
    @EnvironmentObject var settings: AppSettings
    @StateObject var authManager = AuthManager()
    @State private var errorSolution: String = ""
    @StateObject private var errorLookupViewModel = ErrorLookupViewModel()
    @StateObject private var viewModel = ErrorLookupViewModel()
    @State private var codeInput = ""
    @State private var codeDescription = ""
    @State private var codeSolution = ""
    @State private var command: String = ""
    @State private var someData: Data = Data()
    @State private var binData: Data = Data()
    @State private var someReferenceData: Data? = nil
    @StateObject private var uartViewModel = UARTViewModel()
    @State private var referenceData: Data? = nil
    @StateObject private var versionFetcher = VersionFetcher()
    @State private var updateStatus: String = ""
    @State private var selectedBinFile: URL? = nil
    @State private var modifiedNORData: Data? = nil
    @State private var showSaveConfirmation = false

    private let offsetOne: Int64 = 0x1c7010
    private let offsetTwo: Int64 = 0x1c7030
    private let wifiMacOffset: Int64 = 0x1C73C0
    private let lanMacOffset: Int64 = 0x1C4020
    private let serialOffset: Int64 = 0x1c7210
    private let variantOffset: Int64 = 0x1c7226
    private let moboSerialOffset: Int64 = 0x1C7200

    private let ps5ModelOptions = ["Digital Edition", "Disc Edition"]
    private let boardVariantOptions = ["CFI-1000A - Japan", "CFI-1000B - Japan", "CFI-1015A - US, Canada, (North America)", "CFI-1015B - US, Canada, (North America)", "CFI-1016A - US, Canada, (North America)", "CFI-1016B - US, Canada, (North America)", "CFI-1002A - Australia / New Zealand, (Oceania)", "CFI-1002B - Australia / New Zealand, (Oceania)", "CFI-1003A - United Kingdom / Ireland", "CFI-1003B - United Kingdom / Ireland", "CFI-1004A - Europe / Middle East / Africa", "CFI-1004B - Europe / Middle East / Africa", "CFI-1005A - South Korea", "CFI-1005B - South Korea", "CFI-1006A - Southeast Asia / Hong Kong", "CFI-1006B - Southeast Asia / Hong Kong", "CFI-1007A - Taiwan", "CFI-1007B - Taiwan", "CFI-1008A - Russia, Ukraine, India, Central Asia", "CFI-1008B - Russia, Ukraine, India, Central Asia", "CFI-1009A - Mainland China", "CFI-1009B - Mainland China", "CFI-1011A - Mexico, Central America, South America", "CFI-1011B - Mexico, Central America, South America", "CFI-1014A - Mexico, Central America, South America", "CFI-1014B - Mexico, Central America, South America", "CFI-1216A - Europe / Middle East / Africa", "CFI-1216B - Europe / Middle East / Africa", "CFI-1018A - Singapore, Korea, Asia", "CFI-1018B - Singapore, Korea, Asia"]

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

    @State private var selectedSidebarItem: SidebarItem? = .results

    var body: some View {
        NavigationSplitView {
            List(SidebarItem.allCases, selection: $selectedSidebarItem) { item in
                NavigationLink(value: item) {
                    Label(item.rawValue, systemImage: item.iconName)
                        .padding(.vertical, 2)
                        .accentColor(Color.customBlue)
                }
            }
            .listStyle(.sidebar)
            .frame(minWidth: 150, idealWidth: 180)
            .navigationTitle("PS5 NOR Modifier")
        } detail: {
            detailView
        }
    }

    @ViewBuilder
    var detailView: some View {
        switch selectedSidebarItem {
        case .results:
            resultsTab
        case .hexEditor:
            HexEditorView()
                .environmentObject(settings)
                .frame(minWidth: 700, minHeight: 400)
        case .errorCodes:
            ErrorLookupView(
                errorCodeInput: $errorCodeInput,
                errorDescription: $errorDescription,
                errorSolution: $errorSolution,
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
            VStack {
                SettingsView(selectedBinFile: $selectedBinFile)
                    .environmentObject(authManager)
                    .padding(.bottom)
                    .frame(minWidth: 600, maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(minWidth: 800, minHeight: 600)
            .onAppear {
                errorLookupViewModel.loadErrorCodes()
            }
            .environmentObject(settings)
        }
    }

    @ViewBuilder
    var resultsTab: some View {
        ScrollView {
            VStack(spacing: 10) {
                Image(systemName: "gamecontroller")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .foregroundColor(.customBlue)

                Text("PS5 NOR Modifier")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Current Version: \(versionFetcher.currentVersion)")
                Text("Latest Version: \(versionFetcher.latestVersion)")
                if versionFetcher.checkingUpdate {
                    ProgressView()
                }

                Text("This is in development, use at your own risk")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, alignment: .center)

            HStack {
                Text("Select NOR Dump")
                    .font(.subheadline)
                Spacer()
                Button("Browse") {
                    let panel = NSOpenPanel()
                    panel.title = "Select a PS5 NOR Dump"
                    panel.message = "Choose a .bin file to decode"
                    panel.allowedContentTypes = [UTType(filenameExtension: "bin") ?? .item]
                    panel.allowsMultipleSelection = false
                    panel.canChooseDirectories = false
                    panel.canCreateDirectories = false

                    if panel.runModal() == .OK, let url = panel.url {
                        selectedFile = url
                        loadFile()
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            Divider()

            HStack(alignment: .top, spacing: 20) {
                GroupBox(label: Text("Dump Results").font(.headline)) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Serial Number: \(serialNumber)")
                        Divider()
                        Text("Motherboard Serial: \(motherboardSerial)")
                        Divider()
                        Text("Board Variant: \(boardVariant)")
                        Divider()
                        Text("PS5 Model: \(ps5Model)")
                        Divider()
                        Text("File Size: \(fileSize)")
                        Divider()
                        Text("WiFi MAC Address: \(wifiMacAddress)")
                        Divider()
                        Text("LAN MAC Address: \(lanMacAddress)")
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(minWidth: 300, idealWidth: 350)

                GroupBox(label: Text("Modify Values").font(.headline)) {
                    VStack(alignment: .leading, spacing: 10) {
                        TextField("Serial Number", text: $modifiedSerialNumber)
                            .textFieldStyle(.roundedBorder)

                        Picker("Board Variant", selection: $modifiedBoardVariant) {
                            ForEach(boardVariantOptions, id: \.self) { Text($0) }
                        }
                        .pickerStyle(.menu)

                        Picker("PS5 Model", selection: $modifiedPs5Model) {
                            ForEach(ps5ModelOptions, id: \.self) { Text($0) }
                        }
                        .pickerStyle(.menu)

                        TextField("WiFi MAC Address", text: $modifiedWifiMacAddress)
                            .textFieldStyle(.roundedBorder)

                        TextField("LAN MAC Address", text: $modifiedLanMacAddress)
                            .textFieldStyle(.roundedBorder)

                        Button("Save New BIOS Information") {
                            if let data = generateModifiedNORData() {
                                modifiedNORData = data
                                saveAs(data: data) {
                                    showSaveConfirmation = true
                                }
                            } else {
                                showAlert(title: "Missing Data", message: "Please make sure all required fields are filled.")
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(minWidth: 250, idealWidth: 350)
            }
            .padding()
        }
    }

    var hasChanges: Bool {
        return modifiedSerialNumber != serialNumber ||
               modifiedBoardVariant != boardVariant ||
               modifiedPs5Model != ps5Model ||
               modifiedWifiMacAddress != wifiMacAddress ||
               modifiedLanMacAddress != lanMacAddress
    }
    func generateModifiedNORData() -> Data? {
        guard !modifiedBoardVariant.isEmpty, !modifiedPs5Model.isEmpty else { return nil }

        var mutableData = fileData

        // Serial Number
        mutableData.writeAsciiString(modifiedSerialNumber, offset: Int(serialOffset), length: 16)

        // Board Variant
        let baseVariant = modifiedBoardVariant.components(separatedBy: " -").first ?? modifiedBoardVariant
        mutableData.writeAsciiString(baseVariant, offset: Int(variantOffset), length: 19)

        // PS5 Model
        let discSignature: [UInt8] = [0x22, 0x02, 0x01, 0x01]
        let digitalSignature: [UInt8] = [0x22, 0x03, 0x01, 0x01]
        let emptyBytes = [UInt8](repeating: 0x00, count: 12)

        switch modifiedPs5Model {
        case "Disc Edition":
            mutableData.writeBytes(discSignature, offset: Int(offsetOne))
            mutableData.writeBytes(emptyBytes, offset: Int(offsetTwo))
        case "Digital Edition":
            mutableData.writeBytes(digitalSignature, offset: Int(offsetTwo))
            mutableData.writeBytes(emptyBytes, offset: Int(offsetOne))
        default:
            break
        }

        // MAC Addresses
        if let wifiMacData = macAddressStringToData(modifiedWifiMacAddress) {
            mutableData.writeBytes([UInt8](wifiMacData), offset: Int(wifiMacOffset))
        }
        if let lanMacData = macAddressStringToData(modifiedLanMacAddress) {
            mutableData.writeBytes([UInt8](lanMacData), offset: Int(lanMacOffset))
        }

        return mutableData
    }
    
    func saveAs(data: Data, suggestedName: String = "ModifiedNOR.bin", onSuccess: @escaping () -> Void) {
        let panel = NSSavePanel()
        panel.title = "Save Modified NOR File"
        panel.nameFieldStringValue = suggestedName
        panel.allowedContentTypes = [.data]
        panel.canCreateDirectories = true

        if panel.runModal() == .OK, let url = panel.url {
            do {
                try data.write(to: url)
                onSuccess()
            } catch {
                print("Error saving: \(error)")
            }
        }
    }
        
    private func loadFile() {
        guard let fileURL = selectedFile else { return }
        do {
            fileData = try Data(contentsOf: fileURL)
            selectedFileURL = fileURL // ✅ this is what's missing
            loadMetadataFromFile()
            showAlert(title: "Success", message: "File loaded: \(fileURL.lastPathComponent)")
        } catch {
            showAlert(title: "Error", message: "Failed to read file: \(error.localizedDescription)")
        }
    }
            
            private func loadMetadataFromFile() {
                guard fileData.count > 0 else {
                    showAlert(title: "Error", message: "No file data loaded.")
                    return
                }
                
                fileSize = "\(fileData.count) bytes (\(fileData.count / 1024 / 1024) MB)"
                
                // Serial Number
                if fileData.count >= serialOffset + 16 {
                    serialNumber = readCString(from: fileData, at: Int(serialOffset), maxLength: 16) ?? "Unknown"
                    modifiedSerialNumber = serialNumber != "Unknown" ? serialNumber : ""
                }
                
                // Motherboard Serial
                if fileData.count >= moboSerialOffset + 16 {
                    motherboardSerial = readCString(from: fileData, at: Int(moboSerialOffset), maxLength: 16) ?? "Unknown"
                }
                
                // Board Variant
                if fileData.count >= variantOffset + 19 {
                    if let variant = readCString(from: fileData, at: Int(variantOffset), maxLength: 19),
                       let matchedVariant = boardVariantOptions.first(where: { $0.hasPrefix(variant) }) {
                        boardVariant = matchedVariant
                        modifiedBoardVariant = matchedVariant
                    } else {
                        boardVariant = "Unknown"
                        modifiedBoardVariant = ""
                    }
                }
                
                // PS5 Model
                ps5Model = readPs5ModelFromData() ?? "Unknown"
                modifiedPs5Model = ps5Model
                
                // WiFi MAC Address
                if fileData.count >= wifiMacOffset + 6 {
                    wifiMacAddress = readMACAddress(from: fileData, at: Int(wifiMacOffset)) ?? "Unknown"
                    modifiedWifiMacAddress = wifiMacAddress != "Unknown" ? wifiMacAddress : ""
                }
                
                // LAN MAC Address
                if fileData.count >= lanMacOffset + 6 {
                    lanMacAddress = readMACAddress(from: fileData, at: Int(lanMacOffset)) ?? "Unknown"
                    modifiedLanMacAddress = lanMacAddress != "Unknown" ? lanMacAddress : ""
                }
            }
            
            private func readCString(from data: Data, at offset: Int, maxLength: Int) -> String? {
                guard offset + maxLength <= data.count else { return nil }
                let subdata = data[offset..<Swift.min(offset + maxLength, data.count)]
                return String(bytes: subdata.prefix { $0 != 0 }, encoding: .utf8)?.trimmingCharacters(in: .controlCharacters)
            }
            
            private func readMACAddress(from data: Data, at offset: Int) -> String? {
                guard offset + 6 <= data.count else { return nil }
                let macBytes = data[offset..<(offset + 6)]
                return macBytes.map { String(format: "%02X", $0) }.joined(separator: ":")
            }
            
            private func readPs5ModelFromData() -> String? {
                guard fileData.count > 0 else { return nil }
                if fileData.count >= offsetOne + 12 {
                    let range = Int(offsetOne)..<Int(offsetOne + 12)
                    let dataSlice = fileData.subdata(in: range)
                    let hexString = dataSlice.map { String(format: "%02X", $0) }.joined()
                    if hexString.contains("22020101") {
                        return "Disc Edition"
                    }
                }
                if fileData.count >= offsetTwo + 12 {
                    let range = Int(offsetTwo)..<Int(offsetTwo + 12)
                    let dataSlice = fileData.subdata(in: range)
                    let hexString = dataSlice.map { String(format: "%02X", $0) }.joined()
                    if hexString.contains("22030101") {
                        return "Digital Edition"
                    }
                }
                return "Unknown"
            }
            
            private func saveFile() {
                guard let fileURL = selectedFile else {
                    showAlert(title: "Error", message: "No file selected to save.")
                    return
                }
                
                guard !modifiedBoardVariant.isEmpty, !modifiedPs5Model.isEmpty else {
                    showAlert(title: "Error", message: "Please select a valid board variant and PS5 model.")
                    return
                }
                
                var mutableData = fileData
                
                // Write Serial Number
                mutableData.writeAsciiString(modifiedSerialNumber, offset: Int(serialOffset), length: 16)
                
                // Write Board Variant
                let baseVariant = modifiedBoardVariant.components(separatedBy: " -").first ?? modifiedBoardVariant
                mutableData.writeAsciiString(baseVariant, offset: Int(variantOffset), length: 19)
                
                // Write PS5 Model
                let discSignature: [UInt8] = [0x22, 0x02, 0x01, 0x01]
                let digitalSignature: [UInt8] = [0x22, 0x03, 0x01, 0x01]
                let emptyBytes = [UInt8](repeating: 0x00, count: 12)
                switch modifiedPs5Model {
                case "Disc Edition":
                    mutableData.writeBytes(discSignature, offset: Int(offsetOne))
                    mutableData.writeBytes(emptyBytes, offset: Int(offsetTwo))
                case "Digital Edition":
                    mutableData.writeBytes(digitalSignature, offset: Int(offsetTwo))
                    mutableData.writeBytes(emptyBytes, offset: Int(offsetOne))
                default:
                    break
                }
                
                // Write MAC Addresses
                if let wifiMacData = macAddressStringToData(modifiedWifiMacAddress) {
                    mutableData.writeBytes([UInt8](wifiMacData), offset: Int(wifiMacOffset))
                }
                if let lanMacData = macAddressStringToData(modifiedLanMacAddress) {
                    mutableData.writeBytes([UInt8](lanMacData), offset: Int(lanMacOffset))
                }
                
                do {
                    try mutableData.write(to: fileURL)
                    fileData = mutableData
                    loadMetadataFromFile()
                    showAlert(title: "Success", message: "File saved successfully.")
                } catch {
                    showAlert(title: "Error", message: "Failed to save file: \(error.localizedDescription)")
                }
            }
            
            private func macAddressStringToData(_ mac: String) -> Data? {
                let components = mac.trimmingCharacters(in: .whitespacesAndNewlines).split(separator: ":")
                guard components.count == 6 else { return nil }
                var bytes = [UInt8]()
                for comp in components {
                    guard let byte = UInt8(comp, radix: 16) else { return nil }
                    bytes.append(byte)
                }
                return Data(bytes)
            }
            
            private func showAlert(title: String, message: String) {
                let alert = NSAlert()
                alert.messageText = title
                alert.informativeText = message
                alert.alertStyle = .informational
                alert.addButton(withTitle: "OK")
                alert.runModal()
            }
        }
        
        
        extension Data {
            mutating func writeAsciiString(_ string: String, offset: Int, length: Int) {
                var bytes = [UInt8](repeating: 0x00, count: length)
                let asciiString = string.prefix(length)
                let asciiBytes = Array(asciiString.utf8)
                for i in 0..<Swift.min(asciiBytes.count, length) {
                    bytes[i] = asciiBytes[i]
                }
                self.replaceSubrange(offset..<offset+length, with: bytes)
            }
            
            mutating func writeBytes(_ bytes: [UInt8], offset: Int) {
                guard offset + bytes.count <= self.count else { return }
                self.replaceSubrange(offset..<offset+bytes.count, with: bytes)
            }
        }
func launchHelper(withZipPath zipPath: String) {
    let helperPath = Bundle.main.path(forResource: "UpdaterHelperGUI", ofType: "app", inDirectory: "Contents/Helpers")!
    let executablePath = "\(helperPath)/Contents/MacOS/UpdaterHelperGUI"

    let process = Process()
    process.executableURL = URL(fileURLWithPath: executablePath)
    process.arguments = [zipPath]

    do {
        try process.run()
    } catch {
        print("Failed to launch helper: \(error)")
    }
}
func runUpdater(completion: @escaping (Bool, String) -> Void) {
    guard let helperURL = Bundle.main.bundleURL.appendingPathComponent("Contents/Helpers/UpdaterHelperGUI.app") as URL? else {
        completion(false, "Helper app not found")
        return
    }
    
    let executableURL = helperURL.appendingPathComponent("Contents/MacOS/UpdaterHelperGUI")
    
    let task = Process()
    task.executableURL = executableURL
    
    // Example arguments - update as needed:
    task.arguments = ["--update", "/path/to/update.zip"]
    
    task.terminationHandler = { process in
        if process.terminationStatus == 0 {
            completion(true, "Updater finished successfully")
        } else {
            completion(false, "Updater exited with code \(process.terminationStatus)")
        }
    }
    
    do {
        try task.run()
    } catch {
        completion(false, "Failed to launch helper: \(error.localizedDescription)")
    }
}
extension Color {
    static let customBlue = Color(hex: "006FCD")
    
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6:
            r = (int >> 16) & 0xFF
            g = (int >> 8) & 0xFF
            b = int & 0xFF
        default:
            r = 0; g = 0; b = 0
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: 1
        )
    }
}
func showBinFilePicker(completion: @escaping (URL?) -> Void) {
    let panel = NSOpenPanel()
    panel.title = "Select a .bin File"
    panel.allowedContentTypes = [.init(filenameExtension: "bin")!]
    panel.allowsMultipleSelection = false
    panel.canChooseDirectories = false
    panel.begin { result in
        if result == .OK {
            completion(panel.url)
        } else {
            completion(nil)
        }
    }
}
        
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
        }
    }

