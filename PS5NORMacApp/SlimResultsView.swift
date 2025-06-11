import SwiftUI

struct SlimResultsView: View {
    @Binding var fileData: Data
    @Binding var modifiedSlimVariant: String
    @Binding var slimVariant: String
    @Binding var slimModel: String
    @Binding var modifiedSlimModel: String
    @Binding var wifiMacAddress: String
    @Binding var lanMacAddress: String
    @Binding var modifiedWifiMacAddress: String
    @Binding var modifiedLanMacAddress: String

    private let slimModelOptions = ["Slim Disc Edition", "Slim Digital Edition"]

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                Text("PS5 Slim Modifier")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.top)

                HStack(alignment: .top, spacing: 20) {
                    // Results
                    GroupBox(label: Text("Slim Metadata").font(.headline)) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Board Variant: \(slimVariant)")
                            Divider()
                            Text("PS5 Model: \(slimModel)")
                            Divider()
                            Text("WiFi MAC: \(wifiMacAddress)")
                            Divider()
                            Text("LAN MAC: \(lanMacAddress)")
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(minWidth: 300)

                    // Modifiers
                    GroupBox(label: Text("Modify Slim Fields").font(.headline)) {
                        VStack(alignment: .leading, spacing: 10) {
                            TextField("Board Variant", text: $modifiedSlimVariant)
                                .textFieldStyle(.roundedBorder)

                            Picker("PS5 Model", selection: $modifiedSlimModel) {
                                ForEach(slimModelOptions, id: \.self) { Text($0) }
                            }
                            .pickerStyle(.menu)

                            TextField("WiFi MAC", text: $modifiedWifiMacAddress)
                                .textFieldStyle(.roundedBorder)

                            TextField("LAN MAC", text: $modifiedLanMacAddress)
                                .textFieldStyle(.roundedBorder)

                            Button("Apply Slim Changes") {
                                applySlimModifications()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(minWidth: 250)
                }
                .padding()
            }
        }
    }

    // MARK: - Slim Modifier Logic
    func applySlimModifications() {
        print("🛠 Applying Slim patch...")

        let baseVariant = modifiedSlimVariant.components(separatedBy: " -").first ?? modifiedSlimVariant
        fileData.writeAsciiString(baseVariant, offset: 0x1C7226, length: 19)

        if modifiedSlimModel == "Slim Digital Edition" {
            fileData.writeBytes([0x22, 0x03, 0x01, 0x01], offset: 0x1C7030)
            fileData.writeBytes([0x00, 0x00, 0x00, 0x00], offset: 0x1C7010)
        } else {
            fileData.writeBytes([0x22, 0x02, 0x01, 0x01], offset: 0x1C7010)
            fileData.writeBytes([0x00, 0x00, 0x00, 0x00], offset: 0x1C7030)
        }

        if let wifi = macAddressStringToData(modifiedWifiMacAddress) {
            fileData.writeBytes([UInt8](wifi), offset: 0x1C73C0)
        }

        if let lan = macAddressStringToData(modifiedLanMacAddress) {
            fileData.writeBytes([UInt8](lan), offset: 0x1C4020)
        }

        print("✅ Slim patch complete")
    }
}
// Converts a MAC address string (e.g., "00:11:22:33:44:55") to Data
func macAddressStringToData(_ mac: String) -> Data? {
    let components = mac.trimmingCharacters(in: .whitespacesAndNewlines).split(separator: ":")
    guard components.count == 6 else { return nil }
    var bytes = [UInt8]()
    for comp in components {
        guard let byte = UInt8(comp, radix: 16) else { return nil }
        bytes.append(byte)
    }
    return Data(bytes)
}

