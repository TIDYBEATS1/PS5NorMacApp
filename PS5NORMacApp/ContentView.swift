import SwiftUI
import AppKit

// AppDelegate to handle window configuration
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Access the main window after the app has finished launching
        if let window = NSApplication.shared.windows.first {
            // Lock the window size
            window.minSize = NSSize(width: 450, height: 600)
            window.maxSize = NSSize(width: 450, height: 600)
            // Disable resizing
            window.styleMask.remove(.resizable)
            // Ensure the window is set to the exact size
            window.setContentSize(NSSize(width: 450, height: 600))
        }
    }
}


struct NORToolApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .fixedSize()
                .frame(minWidth: 450, maxWidth: 450, minHeight: 600, maxHeight: 600)
        }
    }
}

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

    // Offsets from the C# code
    private let offsetOne: Int64 = 0x1c7010
    private let offsetTwo: Int64 = 0x1c7030
    private let wifiMacOffset: Int64 = 0x1C73C0
    private let lanMacOffset: Int64 = 0x1C4020
    private let serialOffset: Int64 = 0x1c7210
    private let variantOffset: Int64 = 0x1c7226
    private let moboSerialOffset: Int64 = 0x1C7200

    // Options for PS5 Model based on screenshot
    private let ps5ModelOptions = ["Digital Edition", "Disc Edition"]

    // Full list of Board Variants with region descriptions
    private let boardVariantOptions = [
        "CFI-1000A - Japan", "CFI-1000B - Japan",
        "CFI-1015A - US, Canada, (North America)", "CFI-1015B - US, Canada, (North America)",
        "CFI-1016A - US, Canada, (North America)", "CFI-1016B - US, Canada, (North America)",
        "CFI-1002A - Australia / New Zealand, (Oceania)", "CFI-1002B - Australia / New Zealand, (Oceania)",
        "CFI-1003A - United Kingdom / Ireland", "CFI-1003B - United Kingdom / Ireland",
        "CFI-1004A - Europe / Middle East / Africa", "CFI-1004B - Europe / Middle East / Africa",
        "CFI-1005A - South Korea", "CFI-1005B - South Korea",
        "CFI-1006A - Southeast Asia / Hong Kong", "CFI-1006B - Southeast Asia / Hong Kong",
        "CFI-1007A - Taiwan", "CFI-1007B - Taiwan",
        "CFI-1008A - Russia, Ukraine, India, Central Asia", "CFI-1008B - Russia, Ukraine, India, Central Asia",
        "CFI-1009A - Mainland China", "CFI-1009B - Mainland China",
        "CFI-1011A - Mexico, Central America, South America", "CFI-1011B - Mexico, Central America, South America",
        "CFI-1014A - Mexico, Central America, South America", "CFI-1014B - Mexico, Central America, South America",
        "CFI-1216A - Europe / Middle East / Africa", "CFI-1216B - Europe / Middle East / Africa",
        "CFI-1018A - Singapore, Korea, Asia", "CFI-1018B - Singapore, Korea, Asia"
    ]
    let image = Image("image 1")

    var body: some View {
        VStack(alignment: .center, spacing: 10) {
            HStack {
                Image("image 1")
                .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                VStack(alignment: .leading) {
                    Text("PS5 NOR Modifier")
                        .font(.title)
                        .bold()
                    Text("Bwe can SUCK IT!")
                        .font(.subheadline)
                }
            }
            .padding(.bottom, 0)

            Text("This Is In Developement use at your own risk")
                .font(.caption)

            HStack {
                Text("Select NOR Dump")
                Spacer()
                Button("Browse") {
                    let panel = NSOpenPanel()
                    panel.allowsMultipleSelection = false
                    panel.canChooseDirectories = false
                    panel.allowedContentTypes = [.init(filenameExtension: "bin")!]
                    if panel.runModal() == .OK {
                        selectedFile = panel.url
                        readFile()
                    }
                }
            }

            HStack(alignment: .top, spacing: 20) {
                GroupBox(label: Text("Dump Results:")) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Serial Number: \(serialNumber)")
                        Text("Motherboard Serial: \(motherboardSerial)")
                        Text("Board Variant: \(boardVariant)")
                        Text("PS5 Model: \(ps5Model)")
                        Text("File Size: \(fileSize)")
                        Text("WiFi MAC Address: \(wifiMacAddress)")
                        Text("LAN MAC Address: \(lanMacAddress)")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(minWidth: 200)

                GroupBox(label: Text("Modify Values")) {
                    VStack(alignment: .leading, spacing: 5) {
                        TextField("Serial Number", text: $modifiedSerialNumber)
                        Picker("Board Variant", selection: $modifiedBoardVariant) {
                            ForEach(boardVariantOptions, id: \.self) { option in
                                Text(option).tag(option)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        Picker("PS5 Model", selection: $modifiedPs5Model) {
                            ForEach(ps5ModelOptions, id: \.self) { option in
                                Text(option).tag(option)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        TextField("WiFi MAC Address", text: $modifiedWifiMacAddress)
                        Button("Save New BIOS Information") {
                            saveFile()
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(minWidth: 200)
            }

            Text("I Converted The Cod3r Code And Made This Using ChatGPT So Use At Your Own Risk ")
                .font(.caption)
                .multilineTextAlignment(.center)

            Text("This project wad not sponsored by www.consolefix.shop but go give it a look")
                .font(.caption)
                .multilineTextAlignment(.center)

            // Status bar at the bottom
            HStack {
                Text("Status: \(selectedFile?.path ?? "No file selected")")
                    .font(.caption)
                Spacer()
            }
            .padding(.bottom, 5)
            .background(Color.gray.opacity(0.1))
        }
        .padding()
        .onAppear {
            // Lock window size and disable resizing
            if let window = NSApplication.shared.windows.first {
                window.minSize = NSSize(width: 450, height: 600)
                window.maxSize = NSSize(width: 450, height: 600)
                window.styleMask.remove(.resizable) // Disable resize control
            }
        }
    }

    private func readFile() {
        guard let fileURL = selectedFile else { return }
        do {
            let fileHandle = try FileHandle(forReadingFrom: fileURL)
            defer { try? fileHandle.close() }

            // Get file size
            let fileSizeBytes = try fileHandle.seekToEnd()
            fileSize = "\(fileSizeBytes) bytes (\(fileSizeBytes / 1024 / 1024) MB)"

            // Read Serial Number
            serialNumber = readCString(at: serialOffset, maxLength: 17, from: fileHandle) ?? "..."
            modifiedSerialNumber = serialNumber != "..." ? serialNumber : ""

            // Read Motherboard Serial
            motherboardSerial = readCString(at: moboSerialOffset, maxLength: 16, from: fileHandle) ?? "..."

            // Read Board Variant
            boardVariant = readBoardVariant(at: variantOffset, length: 19, from: fileHandle) ?? "..."
            // Match with available options
            if let matchedVariant = boardVariantOptions.first(where: { $0.hasPrefix(String(boardVariant.split(separator: " -")[0])) }) {
                modifiedBoardVariant = matchedVariant
            } else {
                modifiedBoardVariant = "Unknown"
            }

            // Read PS5 Model
            ps5Model = readPs5Model(from: fileHandle) ?? "..."
            modifiedPs5Model = ps5Model

            // Read WiFi MAC Address
            wifiMacAddress = readMACAddress(at: wifiMacOffset, from: fileHandle) ?? "..."
            modifiedWifiMacAddress = wifiMacAddress != "..." ? wifiMacAddress : ""

            // Read LAN Mac Address
            lanMacAddress = readMACAddress(at: lanMacOffset, from: fileHandle) ?? "..."
            modifiedLanMacAddress = lanMacAddress != "..." ? lanMacAddress : ""
        } catch {
            print("Error reading file: \(error)")
        }
    }

    private func readCString(at offset: Int64, maxLength: Int, from fileHandle: FileHandle) -> String? {
        do {
            try fileHandle.seek(toOffset: UInt64(offset))
            guard let data = try fileHandle.read(upToCount: maxLength) else { return nil }
            let hexString = data.map { String(format: "%02X", $0) }.joined()
            return hexStringToString(hexString)?.trimmingCharacters(in: .controlCharacters)
        } catch {
            return nil
        }
    }

    private func readBoardVariant(at offset: Int64, length: Int, from fileHandle: FileHandle) -> String? {
        do {
            try fileHandle.seek(toOffset: UInt64(offset))
            guard let data = try fileHandle.read(upToCount: length) else { return nil }
            let hexString = data.map { String(format: "%02X", $0) }.joined().replacingOccurrences(of: "FF", with: "")
            guard let variant = hexStringToString(hexString) else { return nil }
            // Try to match with available options
            if let matchedOption = boardVariantOptions.first(where: { $0.hasPrefix(variant) }) {
                return matchedOption
            }
            return variant + " - Unknown Region"
        } catch {
            return nil
        }
    }

    private func readMACAddress(at offset: Int64, from fileHandle: FileHandle) -> String? {
        do {
            try fileHandle.seek(toOffset: UInt64(offset))
            guard let data = try fileHandle.read(upToCount: 6) else { return nil }
            return data.map { String(format: "%02X", $0) }.joined(separator: ":")
        } catch {
            return nil
        }
    }

    private func readPs5Model(from fileHandle: FileHandle) -> String? {
        do {
            // Check offsetOne for Disc Edition
            try fileHandle.seek(toOffset: UInt64(offsetOne))
            if let data = try fileHandle.read(upToCount: 12),
               data.map({ String(format: "%02X", $0) }).joined().contains("22020101") {
                return "Disc Edition"
            }

            // Check offsetTwo for Digital Edition
            try fileHandle.seek(toOffset: UInt64(offsetTwo))
            if let data = try fileHandle.read(upToCount: 12),
               data.map({ String(format: "%02X", $0) }).joined().contains("22030101") {
                return "Digital Edition"
            }

            return "Unknown"
        } catch {
            print("Error reading PS5 Model: \(error)")
            return "Unknown"
        }
    }

    private func readHexString(at offset: Int64, length: Int, from fileHandle: FileHandle) -> String? {
        do {
            try fileHandle.seek(toOffset: UInt64(offset))
            guard let data = try fileHandle.read(upToCount: length) else { return nil }
            return data.map { String(format: "%02X", $0) }.joined()
        } catch {
            return nil
        }
    }

    private func hexStringToString(_ hexString: String) -> String? {
        guard hexString.count % 2 == 0 else { return nil }
        var result = ""
        for i in stride(from: 0, to: hexString.count, by: 2) {
            let start = hexString.index(hexString.startIndex, offsetBy: i)
            let end = hexString.index(start, offsetBy: 2)
            let hexChar = String(hexString[start..<end])
            if let byte = UInt8(hexChar, radix: 16) {
                result.append(Character(UnicodeScalar(byte)))
            } else {
                return nil
            }
        }
        return result
    }

    private func saveFile() {
        guard let originalFileURL = selectedFile else {
            print("No file selected to modify")
            return
        }

        let savePanel = NSSavePanel()
        savePanel.title = "Save Modified NOR File"
        savePanel.allowedContentTypes = [.init(filenameExtension: "bin")!]
        savePanel.nameFieldStringValue = "modified_nor_dump.bin"

        if savePanel.runModal() == .OK, let saveURL = savePanel.url {
            do {
                // Copy the original file to the new location
                let fileManager = FileManager.default
                try fileManager.copyItem(at: originalFileURL, to: saveURL)

                // Open the new file for writing
                let fileHandle = try FileHandle(forUpdating: saveURL)
                defer { try? fileHandle.close() }

                // Modify Serial Number
                if !modifiedSerialNumber.isEmpty, modifiedSerialNumber != serialNumber {
                    try writeCString(modifiedSerialNumber, at: serialOffset, maxLength: 17, to: fileHandle)
                }

                // Modify Board Variant
                if !modifiedBoardVariant.isEmpty, modifiedBoardVariant != boardVariant {
                    let baseVariant = String(modifiedBoardVariant.split(separator: " -")[0])
                    try writeCString(baseVariant, at: variantOffset, maxLength: 19, to: fileHandle)
                }

                // Modify PS5 Model
                if !modifiedPs5Model.isEmpty, modifiedPs5Model != ps5Model {
                    try modifyPs5Model(modifiedPs5Model, to: fileHandle)
                }

                // Modify WiFi MAC Address
                if !modifiedWifiMacAddress.isEmpty, modifiedWifiMacAddress != wifiMacAddress {
                    try writeMACAddress(modifiedWifiMacAddress, at: wifiMacOffset, to: fileHandle)
                }

                // Modify LAN MAC Address
                if !modifiedLanMacAddress.isEmpty, modifiedLanMacAddress != lanMacAddress {
                    try writeMACAddress(modifiedLanMacAddress, at: lanMacOffset, to: fileHandle)
                }

                // Validate PS5 Model write
                let validationHandle = try FileHandle(forReadingFrom: saveURL)
                defer { try? validationHandle.close() }
                let validatedModel = readPs5Model(from: validationHandle)
                if validatedModel != modifiedPs5Model {
                    print("Warning: PS5 Model write validation failed. Expected: \(modifiedPs5Model), Found: \(validatedModel ?? "nil")")
                }

                // Update UI by re-reading the new file
                selectedFile = saveURL
                readFile()

                print("File saved successfully at \(saveURL)")
            } catch {
                print("Error saving file: \(error)")
            }
        }
    }

    private func writeCString(_ string: String, at offset: Int64, maxLength: Int, to fileHandle: FileHandle) throws {
        let data = string.prefix(maxLength).data(using: .utf8) ?? Data()
        let paddedData = data + Data(repeating: 0, count: Swift.max(0, maxLength - data.count))
        try fileHandle.seek(toOffset: UInt64(offset))
        try fileHandle.write(contentsOf: paddedData)
    }

    private func writeMACAddress(_ macAddress: String, at offset: Int64, to fileHandle: FileHandle) throws {
        let components = macAddress.split(separator: ":")
        guard components.count == 6 else { return }
        let bytes = components.compactMap { UInt8($0, radix: 16) }
        guard bytes.count == 6 else { return }
        let data = Data(bytes)
        try fileHandle.seek(toOffset: UInt64(offset))
        try fileHandle.write(contentsOf: data)
    }

    private func modifyPs5Model(_ model: String, to fileHandle: FileHandle) throws {
        let discEditionHex = "22020101"
        let digitalEditionHex = "22030101"
        let targetHex = model == "Disc Edition" ? discEditionHex : model == "Digital Edition" ? digitalEditionHex : nil

        guard let targetHex = targetHex, let targetData = hexStringToData(targetHex) else {
            print("Invalid PS5 Model selected for modification: \(model)")
            return
        }

        // Write to both offsets to ensure consistency
        // Write to offsetOne
        try fileHandle.seek(toOffset: UInt64(offsetOne))
        try fileHandle.write(contentsOf: targetData)

        // Write to offsetTwo
        try fileHandle.seek(toOffset: UInt64(offsetTwo))
        try fileHandle.write(contentsOf: targetData)
    }

    private func hexStringToData(_ hexString: String) -> Data? {
        guard hexString.count % 2 == 0 else { return nil }
        var data = Data()
        for i in stride(from: 0, to: hexString.count, by: 2) {
            let start = hexString.index(hexString.startIndex, offsetBy: i)
            let end = hexString.index(start, offsetBy: 2)
            let hexChar = String(hexString[start..<end])
            if let byte = UInt8(hexChar, radix: 16) {
                data.append(byte)
            } else {
                return nil
            }
        }
        return data
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            
            
            
            
            
    }
}
