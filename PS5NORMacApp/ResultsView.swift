import SwiftUI
import AppKit
import UniformTypeIdentifiers
import FirebaseCore
import FirebaseRemoteConfig
import UpdateKit


struct ResultsView: View {
    let githubLatestVersion: String  // 👈 Add this

    // MARK: - Model Tab Enum
    enum PS5ModelTab: String, CaseIterable {
        case phat = "Phat"
        case slim = "Slim"
        case pro = "Pro"
        case special = "Special/Limited"
        case testkit = "TestKit"
        case devkit = "DevKit"
        case unknown = "Unknown"
    }

    // MARK: - States
    @Binding var fileData: Data
    @Binding var selectedFile: URL?
    @Binding var serialNumber: String
    @Binding var motherboardSerial: String
    @Binding var boardVariant: String
    @Binding var ps5Model: String
    @Binding var fileSize: String
    @Binding var wifiMacAddress: String
    @Binding var lanMacAddress: String
    @Binding var modifiedSerialNumber: String
    @Binding var modifiedBoardVariant: String
    @Binding var modifiedPs5Model: String
    @Binding var modifiedWifiMacAddress: String
    @Binding var modifiedLanMacAddress: String
    @Binding var showSaveConfirmation: Bool
    @Binding var selectedModelTab: PS5ModelTab
    @Binding var editingDisabled: Bool
    @State private var latestVersion = "Checking..."
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var versionChecker: VersionChecker
    let groupedBoardVariantOptions: [(header: String, models: [String])]
    @State private var currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    private let offsetOne: Int64 = 0x1C7010
    private let offsetTwo: Int64 = 0x1C7030
    private let wifiMacOffset: Int64 = 0x1C73C0
    private let lanMacOffset: Int64 = 0x1C4020
    private let serialOffset: Int64 = 0x1C7210
    private let variantOffset: Int64 = 0x1C7230
    private let moboSerialOffset: Int64 = 0x1C7200
    private let ps5ModelOptions = ["Digital Edition", "Disc Edition"]
    @StateObject private var updateManager =
        UpdateManager(repo: "TIDYBEATS1/PS5NorMacApp")
    private var flatBoardVariantOptions: [String] {
        groupedBoardVariantOptions.flatMap { $0.models }
    }

    private var filteredBoardVariantGroups: [(header: String, models: [String])] {
        switch selectedModelTab {
        case .phat:
            return groupedBoardVariantOptions.filter { $0.header.contains("FAT") }
        case .slim:
            return groupedBoardVariantOptions.filter { $0.header.contains("Slim") }
        case .pro:
            return groupedBoardVariantOptions.filter { $0.header.contains("Pro") }
        case .special:
            return groupedBoardVariantOptions.filter { $0.header.contains("Special") }
        case .testkit:
            return groupedBoardVariantOptions.filter { $0.header.contains("TestKit") }
        case .devkit:
            return groupedBoardVariantOptions.filter { $0.header.contains("DevKit") }
        case .unknown:
            return []
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
              if let info = updateManager.pendingUpdate {
                HStack {
                  Image(systemName: "arrow.down.circle.fill")
                  Text("Update \(info.version) available — go to Settings to update.")
                  Spacer()
                }
                .padding()
                .background(Color.yellow.opacity(0.2))
                .cornerRadius(10)
                .padding([.horizontal, .top])
              }
                Image(systemName: "gamecontroller")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .foregroundColor(.customBlue)
                
                Text("PS5 NOR Modifier")
                    .font(.title)
                    .fontWeight(.bold)
                
                //Text("Current Version: \(versionChecker.currentVersion)")
                //Text("Latest Version: \(versionChecker.latestVersion.isEmpty ? "Checking..." : versionChecker.latestVersion)")
                //   if versionChecker.isChecking { ProgressView() }
                
                Text("This is in development, use at your own risk")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.red)

                Text("Current Version: \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown")")
                    .font(.footnote)
                    .foregroundColor(.secondary)

                Text("Latest GitHub Release: \(githubLatestVersion)")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                
                Text("Fuck BwE")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .fixedSize(horizontal: false, vertical: true)
                
                HStack {
                    Text("Select NOR Dump").font(.subheadline)
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
                    ScrollView(.horizontal, showsIndicators: false) {
                        Picker("Model", selection: $selectedModelTab) {
                            ForEach(PS5ModelTab.allCases, id: \.self) { tab in
                                Text(tab.rawValue)
                            }
                        }
                        .pickerStyle(.segmented)
                        .fixedSize()
                    }
                    .padding(.horizontal)
                }
                
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
                    
                    if editingDisabled {
                        GroupBox(label: Text("Modify Values").font(.headline)) {
                            Text("Editing is disabled for this model.")
                                .foregroundColor(.gray)
                                .padding()
                        }
                        .frame(minWidth: 250, idealWidth: 350)
                    } else {
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
                                            Text(group.header).font(.caption).foregroundColor(.secondary)
                                        }
                                        if group.header != groupedBoardVariantOptions.last?.header { Divider() }
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
                                        saveAs(data: data) { showSaveConfirmation = true }
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
                }
                .padding()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding()
        }
        .alert("Success", isPresented: $showSaveConfirmation) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Modified NOR file saved successfully.")
        }
    }
                    
    
    // MARK: - Helper Functions
    func detectModelTab(from variantCode: String) -> PS5ModelTab {
        let upper = variantCode.uppercased()
        if upper.contains("70XXB") || upper.contains("20XXB") || upper.contains("LIMITED") {
            return .special
        }
        if upper.starts(with: "CFI-70") {
            return .pro
        }
        if upper.starts(with: "CFI-20") {
            return .slim
        }
        if upper.starts(with: "CFI-10") || upper.starts(with: "CFI-11") || upper.starts(with: "CFI-12") {
            return .phat
        }
        if upper.starts(with: "DFI-T") {
            return .testkit
        }
        if upper.starts(with: "DFI-D") {
            return .devkit
        }
        return .unknown
    }

    private func generateModifiedNORData(slimSafe: Bool = false) -> Data? {
        guard !modifiedBoardVariant.isEmpty, !modifiedPs5Model.isEmpty else { return nil }
        var mutableData = fileData
        mutableData.writeAsciiString(modifiedSerialNumber, offset: Int(serialOffset), length: 16)
        let baseVariant = modifiedBoardVariant.components(separatedBy: " -").first ?? modifiedBoardVariant
        let variantLength = slimSafe ? (selectedModelTab == .slim ? 12 : selectedModelTab == .pro ? 10 : 19) : 19
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

    func saveAs(data: Data, suggestedName: String = "ModifiedNOR.bin", onSuccess: @escaping () -> Void) {
        let panel = NSSavePanel()
        panel.title = "Save Modified NOR File"
        panel.nameFieldStringValue = suggestedName
        panel.allowedContentTypes = [.data]
        panel.canCreateDirectories = true
        if panel.runModal() == .OK, let url = panel.url {
            do { try data.write(to: url); onSuccess() }
            catch { showAlert(title: "Error", message: "Failed to save file: \(error.localizedDescription)") }
        }
    }

    private func loadFile() {
        guard let fileURL = selectedFile else { return }
        do {
            let data = try Data(contentsOf: fileURL)
            if data.count < Int(variantOffset + 0x20) {
                showAlert(title: "Invalid File", message: "The selected .bin file is too small or corrupted.")
                return
            }
            fileData = data
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
        let requiredOffsets = [offsetOne, offsetTwo, wifiMacOffset, lanMacOffset, serialOffset, variantOffset, moboSerialOffset]
        for offset in requiredOffsets {
            if Int(offset) + 20 > fileData.count {
                showAlert(title: "Error", message: "The file appears to be incomplete or invalid.")
                return
            }
        }
        let rawDiscBytes = fileData.subdata(in: Int(offsetOne)..<Int(offsetOne + 12)).map { String(format: "%02X", $0) }.joined()
        let rawDigitalBytes = fileData.subdata(in: Int(offsetTwo)..<Int(offsetTwo + 12)).map { String(format: "%02X", $0) }.joined()
        print("🔍 OffsetOne Hex: \(rawDiscBytes)")
        print("🔍 OffsetTwo Hex: \(rawDigitalBytes)")
        fileSize = "\(fileData.count) bytes (\(fileData.count / 1024 / 1024) MB)"
        serialNumber = readCString(from: fileData, at: Int(serialOffset), maxLength: 17) ?? "Unknown"
        modifiedSerialNumber = serialNumber != "Unknown" ? serialNumber : ""
        motherboardSerial = readCString(from: fileData, at: Int(moboSerialOffset), maxLength: 16) ?? "Unknown"
        let rawVariant = readCString(from: fileData, at: Int(variantOffset), maxLength: 19)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let baseVariant = rawVariant.components(separatedBy: " ").first?.uppercased() ?? ""
        let fullVariant = rawVariant.uppercased()
        print("🧪 rawVariant = [\(rawVariant)]")
        if let matched = flatBoardVariantOptions.first(where: {
            $0.uppercased().contains(baseVariant)
                || $0.uppercased().contains(baseVariant + "A")
                || $0.uppercased().contains(baseVariant + "B")
                || $0.uppercased().contains(fullVariant)
        }) {
            boardVariant = matched
            modifiedBoardVariant = matched
            if matched.contains("Slim") {
                selectedModelTab = .slim
                editingDisabled = false
            } else if matched.contains("Pro") || matched.contains("DevKit") || matched.contains("TestKit") {
                selectedModelTab = .pro
                editingDisabled = true
            } else {
                selectedModelTab = .phat
                editingDisabled = false
            }
            print("📌 Final resolved variant string = \(matched)")
            let detectedTab = detectModelTab(from: matched)
            selectedModelTab = detectedTab
            editingDisabled = (detectedTab != .phat && detectedTab != .slim)
            print("📻 selectedModelTab updated to: \(selectedModelTab)")
        } else {
            boardVariant = "Unrecognized (\(rawVariant))"
            modifiedBoardVariant = ""
            selectedModelTab = .unknown
            editingDisabled = true
            print("❌ Variant not matched — fallback engaged.")
        }
        ps5Model = readPs5ModelFromData() ?? "Unknown"
        modifiedPs5Model = ps5Model
        wifiMacAddress = readMACAddress(from: fileData, at: Int(wifiMacOffset)) ?? "Unknown"
        modifiedWifiMacAddress = wifiMacAddress != "Unknown" ? wifiMacAddress : ""
        lanMacAddress = readMACAddress(from: fileData, at: Int(lanMacOffset)) ?? "Unknown"
        modifiedLanMacAddress = lanMacAddress != "Unknown" ? lanMacAddress : ""
    }

    private func readCString(from data: Data, at offset: Int, maxLength: Int) -> String? {
        guard offset >= 0, offset + maxLength <= data.count else { return nil }
        let subdata = data[offset..<Swift.min(offset + maxLength, data.count)]
        return String(bytes: subdata.prefix { $0 != 0 }, encoding: .ascii)?.trimmingCharacters(in: .controlCharacters)
    }

    private func readMACAddress(from data: Data, at offset: Int) -> String? {
        guard offset >= 0, offset + 6 <= data.count else { return nil }
        let macBytes = data[offset..<(offset + 6)]
        return macBytes.map { String(format: "%02X", $0) }.joined(separator: ":")
    }

    private func readPs5ModelFromData() -> String? {
        guard fileData.count >= max(Int(offsetOne) + 12, Int(offsetTwo) + 12) else { return nil }
        let offsetOneSlice = fileData.subdata(in: Int(offsetOne)..<Int(offsetOne + 12))
        let offsetTwoSlice = fileData.subdata(in: Int(offsetTwo)..<Int(offsetTwo + 12))
        let oneHex = offsetOneSlice.map { String(format: "%02X", $0) }.joined()
        let twoHex = offsetTwoSlice.map { String(format: "%02X", $0) }.joined()
        if oneHex.contains("22020101") || twoHex.contains("22020101") {
            return "Disc Edition"
        }
        if oneHex.contains("22030101") || twoHex.contains("22030101") {
            return "Digital Edition"
        }
        if oneHex.contains("22010101") || twoHex.contains("22010101") {
            selectedModelTab = .slim
        }
        let variantSource = !modifiedBoardVariant.isEmpty ? modifiedBoardVariant : boardVariant
        let cfiCode = variantSource.components(separatedBy: " ").first?.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() ?? ""
        if cfiCode.hasSuffix("A") {
            return "Disc Edition"
        } else if cfiCode.hasSuffix("B") {
            return "Digital Edition"
        }
        return "Unknown"
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

