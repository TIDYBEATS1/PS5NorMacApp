import SwiftUI
import AppKit
import Combine
import FirebaseAuth
import UniformTypeIdentifiers

struct ContentView: View {
    // MARK: - States
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
    
    @State private var errorCodeInput: String = ""
    @State private var errorDescription: String = ""
    @State private var errorSolution: String = ""
    @State private var codeInput: String = ""
    @State private var codeDescription: String = ""
    @State private var codeSolution: String = ""
    @State private var command: String = ""
    @State private var someData: Data = Data()
    @State private var binData: Data = Data()
    @State private var someReferenceData: Data? = nil
    @State private var referenceData: Data? = nil
    @State private var updateStatus: String = ""
    @State private var selectedBinFile: URL? = nil
    @State private var modifiedNORData: Data? = nil
    @State private var showSaveConfirmation: Bool = false
    @State private var showSlimResults: Bool = false
    @State private var selectedModelTab: String = "Phat"
    @State private var selectedSidebarItem: SidebarItem? = .results
    
    @State private var showDisclaimer: Bool = true
    
    @EnvironmentObject var settings: AppSettings
    @StateObject private var authManager = AuthManager()
    @StateObject private var errorLookupViewModel = ErrorLookupViewModel()
    @StateObject private var uartViewModel = UARTViewModel()
    @StateObject private var versionFetcher = VersionFetcher()
    
    private let offsetOne: Int64 = 0x1c7010
    private let offsetTwo: Int64 = 0x1c7030
    private let wifiMacOffset: Int64 = 0x1C73C0
    private let lanMacOffset: Int64 = 0x1C4020
    private let serialOffset: Int64 = 0x1c7210
    private let variantOffset: Int64 = 0x1c7226
    private let moboSerialOffset: Int64 = 0x1C7200
    
    private let modelTabs = ["Phat", "Slim", "Pro"]
    private let ps5ModelOptions = ["Digital Edition", "Disc Edition"]
    
    private var flatBoardVariantOptions: [String] {
        groupedBoardVariantOptions.flatMap { $0.models }
    }
    enum PS5Model: Int {
      case phat = 0, slim = 1, pro = 2
    }
    private var filteredBoardVariantGroups: [(header: String, models: [String])] {
        switch selectedModelTab {
        case "Slim":
            return groupedBoardVariantOptions.filter { $0.header.contains("Slim") }
        case "Pro":
            return groupedBoardVariantOptions.filter { $0.header.contains("Pro") }
        case "Phat":
            return groupedBoardVariantOptions.filter {
                $0.header.contains("FAT") || $0.header.contains("Standard") || $0.header.contains("Special") || $0.header.contains("TestKit")
            }
        default:
            return groupedBoardVariantOptions
        }
    }
    
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
    
    // MARK: - Body
    var body: some View {
        NavigationSplitView {
            List(SidebarItem.allCases, selection: $selectedSidebarItem) { item in
                NavigationLink(value: item) {
                    Label(item.rawValue, systemImage: item.iconName)
                        .padding(.vertical, 2)
                        .accentColor(.customBlue)
                }
            }
            .listStyle(.sidebar)
            .frame(minWidth: 150, idealWidth: 180)
            .navigationTitle("PS5 NOR Modifier")
        } detail: {
            detailView
        }
        .alert(isPresented: $showSaveConfirmation) {
            Alert(
                title: Text("Success"),
                message: Text("Modified NOR file saved successfully."),
                dismissButton: .default(Text("OK"))
            )
        }
        .alert("Success",
               isPresented: $showSaveConfirmation) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Modified NOR file saved successfully.")
        }
        // 2) Experimental‐disclaimer as a sheet that cannot be dismissed with ⎋:
        .sheet(isPresented: $showDisclaimer) {
            DisclaimerView(isPresented: $showDisclaimer)
                .interactiveDismissDisabled(true)
                .frame(width: 400, height: 200)
        }
        .onAppear {
            showDisclaimer = true
        }
    }
    
    
    // MARK: - Detail View
    @ViewBuilder
    var detailView: some View {
        switch selectedSidebarItem {
        case .results:
            if showSlimResults {
                slimTab
            } else {
                resultsTab
            }
        case .hexEditor:
            HexEditorView(data: $fileData)
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
            SettingsView(selectedBinFile: $selectedBinFile)
                .environmentObject(authManager)
                .padding(.bottom)
                .frame(minWidth: 600, maxWidth: .infinity, maxHeight: .infinity)
                .onAppear { errorLookupViewModel.loadErrorCodes() }
                .environmentObject(settings)
        }
    }
    
    // MARK: - Results Tab
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
                    showBinFilePicker { url in
                        if let url = url, url.pathExtension.lowercased() == "bin" {
                            selectedFile = url
                            loadFile()
                        } else {
                            showAlert(title: "Invalid File", message: "Please select a valid .bin file.")
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            Divider()
            
            HStack {
                Picker("Model", selection: $selectedModelTab) {
                    ForEach(modelTabs, id: \.self) { tab in
                        Text(tab)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 300)
                Spacer()
            }
            .padding(.horizontal)
            
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
                        Menu {
                            ForEach(filteredBoardVariantGroups, id: \.header) { group in
                                Section {
                                    ForEach(group.models, id: \.self) { variant in
                                        Button {
                                            modifiedBoardVariant = variant
                                        } label: {
                                            HStack {
                                                Text(variant)
                                                if modifiedBoardVariant == variant {
                                                    Spacer()
                                                    Image(systemName: "checkmark")
                                                }
                                            }
                                        }
                                    }
                                } header: {
                                    Text(group.header)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                if group.header != groupedBoardVariantOptions.last?.header {
                                    Divider()
                                }
                            }
                        } label: {
                            Text(modifiedBoardVariant.isEmpty ? "Select Board Variant" : modifiedBoardVariant)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(8)
                                .background(Color(NSColor.controlBackgroundColor))
                                .cornerRadius(6)
                        }
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
    
    // MARK: - Slim Tab
    @ViewBuilder
    var slimTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("PS5 Slim Variant Editor")
                    .font(.title2)
                    .bold()
                    .padding(.bottom, 4)
                
                GroupBox(label: Text("Slim Board Variants")) {
                    Menu {
                        ForEach(groupedBoardVariantOptions.first(where: { $0.header == "PS5 Slim" })?.models ?? [], id: \.self) { variant in
                            Button {
                                modifiedBoardVariant = variant
                            } label: {
                                HStack {
                                    Text(variant)
                                    if modifiedBoardVariant == variant {
                                        Spacer()
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        Text(modifiedBoardVariant.isEmpty ? "Select Slim Variant" : modifiedBoardVariant)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(8)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(6)
                    }
                    .padding()
                }
                
                GroupBox(label: Text("Apply Slim Variant")) {
                    Button("Save as Slim Variant") {
                        if let data = generateModifiedNORData(slimSafe: true) {
                            modifiedNORData = data
                            saveAs(data: data) {
                                showSaveConfirmation = true
                            }
                        } else {
                            showAlert(title: "Error", message: "Unable to generate NOR data.")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .padding()
                }
                
                Spacer()
            }
            .padding()
        }
    }
    
    // MARK: - Computed Properties
    var hasChanges: Bool {
        return modifiedSerialNumber != serialNumber ||
               modifiedBoardVariant != boardVariant ||
               modifiedPs5Model != ps5Model ||
               modifiedWifiMacAddress != wifiMacAddress ||
               modifiedLanMacAddress != lanMacAddress
    }
    
    // MARK: - File Modification
    private func generateModifiedNORData(slimSafe: Bool = false) -> Data? {
        guard !modifiedBoardVariant.isEmpty, !modifiedPs5Model.isEmpty else { return nil }
        
        var mutableData = fileData
        
        mutableData.writeAsciiString(modifiedSerialNumber, offset: Int(serialOffset), length: 16)
        
        let baseVariant = modifiedBoardVariant.components(separatedBy: " -").first ?? modifiedBoardVariant
        let variantLength = slimSafe ? (selectedModelTab == "Slim" ? 12 : selectedModelTab == "Pro" ? 10 : 19) : 19
        mutableData.writeAsciiString(baseVariant, offset: Int(variantOffset), length: variantLength)
        
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
        
        if let wifiMacData = macAddressStringToData(modifiedWifiMacAddress) {
            mutableData.writeBytes([UInt8](wifiMacData), offset: Int(wifiMacOffset))
        }
        if let lanMacData = macAddressStringToData(modifiedLanMacAddress) {
            mutableData.writeBytes([UInt8](lanMacData), offset: Int(lanMacOffset))
        }
        
        return mutableData
    }
    
    func generateSlimSafeNORData() -> Data? {
        generateModifiedNORData(slimSafe: true)
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
                showAlert(title: "Error", message: "Failed to save file: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - File Loading
    private func loadFile() {
        guard let fileURL = selectedFile else { return }
        do {
            fileData = try Data(contentsOf: fileURL)
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
        
        serialNumber = readCString(from: fileData, at: Int(serialOffset), maxLength: 16) ?? "Unknown"
        modifiedSerialNumber = serialNumber != "Unknown" ? serialNumber : ""
        
        motherboardSerial = readCString(from: fileData, at: Int(moboSerialOffset), maxLength: 16) ?? "Unknown"
        
        if let variant = readCString(from: fileData, at: Int(variantOffset), maxLength: 19)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased() {
            if let matchedVariant = flatBoardVariantOptions.first(where: { $0.uppercased().hasPrefix(variant) }) {
                boardVariant = matchedVariant
                modifiedBoardVariant = matchedVariant
                
                // If Slim model detected, select Slim tab
                let slimVariants = groupedBoardVariantOptions.first(where: { $0.header == "PS5 Slim" })?.models.map { $0.uppercased() } ?? []
                if let foundVariant = flatBoardVariantOptions.first(where: { $0.uppercased().hasPrefix(variant) }),
                   slimVariants.contains(where: { foundVariant.uppercased().hasPrefix($0) }) {
                    selectedModelTab = "Slim"
                }
            } else {
                boardVariant = "Unrecognized (\(variant))"
                modifiedBoardVariant = ""
            }
        } else {
            boardVariant = "Unknown"
            modifiedBoardVariant = ""
        }
        
        ps5Model = readPs5ModelFromData() ?? "Unknown"
        modifiedPs5Model = ps5Model
        
        wifiMacAddress = readMACAddress(from: fileData, at: Int(wifiMacOffset)) ?? "Unknown"
        modifiedWifiMacAddress = wifiMacAddress != "Unknown" ? wifiMacAddress : ""
        
        lanMacAddress = readMACAddress(from: fileData, at: Int(lanMacOffset)) ?? "Unknown"
        modifiedLanMacAddress = lanMacAddress != "Unknown" ? lanMacAddress : ""
        
        let code = boardVariant.components(separatedBy: " ").first ?? ""
        switch code.prefix(4) {
        case "CFI-2":
            selectedModelTab = "Slim"
        case "CFI-7":
            selectedModelTab = "Pro"
        default:
            selectedModelTab = "Phat"
        }
    }
    
    private func readCString(from data: Data, at offset: Int, maxLength: Int) -> String? {
        guard offset >= 0, offset + maxLength <= data.count else { return nil }
        let subdata = data[offset..<Swift.min(offset + maxLength, data.count)]
        return String(bytes: subdata.prefix { $0 != 0 }, encoding: .utf8)?.trimmingCharacters(in: .controlCharacters)
    }
    
    private func readMACAddress(from data: Data, at offset: Int) -> String? {
        guard offset >= 0, offset + 6 <= data.count else { return nil }
        let macBytes = data[offset..<(offset + 6)]
        return macBytes.map { String(format: "%02X", $0) }.joined(separator: ":")
    }
    
    private func readPs5ModelFromData() -> String? {
        guard fileData.count >= max(Int(offsetOne) + 12, Int(offsetTwo) + 12) else { return nil }
        if fileData.count >= Int(offsetOne) + 12 {
            let range = Int(offsetOne)..<Int(offsetOne + 12)
            let dataSlice = fileData.subdata(in: range)
            let hexString = dataSlice.map { String(format: "%02X", $0) }.joined()
            if hexString.contains("22020101") {
                return "Disc Edition"
            }
        }
        if fileData.count >= Int(offsetTwo) + 12 {
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
        
        mutableData.writeAsciiString(modifiedSerialNumber, offset: Int(serialOffset), length: 16)
        
        let baseVariant = modifiedBoardVariant.components(separatedBy: " -").first ?? modifiedBoardVariant
        mutableData.writeAsciiString(baseVariant, offset: Int(variantOffset), length: 19)
        
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

// MARK: - Data Extensions
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

// MARK: - Helper Functions
func launchHelper(withZipPath zipPath: String) {
    guard let helperPath = Bundle.main.path(forResource: "UpdaterHelperGUI", ofType: "app", inDirectory: "Contents/Helpers") else {
        print("Helper app not found")
        return
    }
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
    
    // Example arguments (update path as needed)
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

// MARK: - Color Extension
extension Color {
    static let customBlue = Color(hex: "006FCD")
    
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        guard hex.count == 6 else {
            self.init(.sRGB, red: 0, green: 0, blue: 0, opacity: 1)
            return
        }
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: 1)
    }
}
    
    
    // MARK: - File Picker
    func showBinFilePicker(completion: @escaping (URL?) -> Void) {
        let panel = NSOpenPanel()
        panel.title = "Select a .bin File"
        panel.allowedContentTypes = [.data]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.begin { result in
            if result == .OK, let url = panel.url {
                completion(url)
            } else {
                completion(nil)
            }
        }
    }
        struct DisclaimerView: View {
            @Binding var isPresented: Bool
            
            var body: some View {
                VStack(spacing: 20) {
                    Text("Experimental Software")
                        .font(.headline)
                    Text("""
                    This application is experimental. Use at your own risk. \
                    The author is not responsible for any damage or loss resulting from use.
                    """)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    HStack {
                        Button("Quit") {
                            NSApplication.shared.terminate(nil)
                        }
                        .keyboardShortcut(.defaultAction)
                        Spacer()
                        Button("I Understand") {
                            isPresented = false
                        }
                        .keyboardShortcut(.cancelAction)
                    }
                    .padding(.horizontal, 40)
                }
                .padding()
            }
        }
// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AppSettings())
    }
}
