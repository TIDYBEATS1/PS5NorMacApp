import SwiftUI
import UniformTypeIdentifiers
import AppKit
import Foundation

struct NORDiffEntry: Identifiable {
    let id = UUID()
    let offset: Int
    let originalByte: UInt8
    let editedByte: UInt8
}

struct OffsetLabel {
    let label: String
    let tooltip: String?
}
struct NORDiffView: View {
    @State private var originalData: Data?
    @State private var editedData: Data?
    @State private var diffs: [NORDiffEntry] = []
    @State private var showingFileImporter = false
    @State private var isSelectingOriginal = true
    @State private var filter: String = "All"
    
    var body: some View {
        VStack(spacing: 12) {
            // Header buttons
            HStack(spacing: 12) {
                Button("Load Original NOR") {
                    isSelectingOriginal = true
                    showingFileImporter = true
                }

                Button("Load Edited NOR") {
                    isSelectingOriginal = false
                    showingFileImporter = true
                }

                Button("Compare Files") {
                    if let original = originalData, let edited = editedData {
                        diffs = diffNORFiles(original, edited)
                    }
                }
                .disabled(originalData == nil || editedData == nil)

                Button("Export Diff") {
                    exportDiffAsCSV(diffs: diffs)
                }
            }
            .buttonStyle(.borderedProminent)
            .padding(.top)

            // Filter
            Picker("Filter", selection: $filter) {
                Text("All").tag("All")
                Text("Model").tag("Model")
                Text("Serials").tag("Serials")
                Text("MAC").tag("MAC")
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            // Count label
            if !diffs.isEmpty {
                Text("\(filteredDiffs.count) difference(s) shown")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }

            Divider()

            // Diff list
            if filteredDiffs.isEmpty {
                Spacer()
                Text("No differences to show.")
                    .foregroundColor(.gray)
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 6) {
                        ForEach(filteredDiffs) { entry in
                            let isGroup = isGroupOffset(entry.offset)
                            let label = labelForOffset(entry.offset)

                            HStack(spacing: 12) {
                                Text(String(format: "0x%06X", entry.offset))
                                    .monospacedDigit()
                                    .frame(width: 90, alignment: .leading)

                                Text(String(format: "%02X", entry.originalByte))
                                    .monospacedDigit()
                                    .foregroundColor(.red)
                                    .fontWeight(.medium)

                                Image(systemName: "arrow.right")
                                    .foregroundColor(.gray)

                                Text(String(format: "%02X", entry.editedByte))
                                    .monospacedDigit()
                                    .foregroundColor(.green)
                                    .fontWeight(.medium)

                                if let label = label {
                                    Text("• \(label.label)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .help(label.tooltip ?? "")
                                }

                                if let ascii = asciiForByte(offset: entry.offset, byte: entry.editedByte) {
                                    Text("‘\(ascii)’")
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                }

                                Spacer()
                            }
                            .padding(6)
                            .background(isGroup ? Color.gray.opacity(0.1) : Color.clear)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.secondary.opacity(0.2), lineWidth: 0.5)
                            )
                            .cornerRadius(6)
                            .contextMenu {
                                Button("Copy Row") {
                                    let copyText = String(format: "0x%06X: %02X → %02X", entry.offset, entry.originalByte, entry.editedByte)
                                    NSPasteboard.general.clearContents()
                                    NSPasteboard.general.setString(copyText, forType: .string)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .padding()
        .navigationTitle("Compare NOR Files")
        .fileImporter(
            isPresented: $showingFileImporter,
            allowedContentTypes: [UTType.data],
            allowsMultipleSelection: false
        ) { result in
            do {
                guard let selectedURL = try result.get().first else { return }
                let data = try Data(contentsOf: selectedURL)
                if isSelectingOriginal {
                    originalData = data
                } else {
                    editedData = data
                }
            } catch {
                print("Failed to load file: \(error)")
            }
        }
        .onDrop(of: [UTType.data], isTargeted: nil) { providers in
            loadDropFile(providers: providers) { data in
                if originalData == nil {
                    originalData = data
                } else {
                    editedData = data
                }
            }
        }
    }

    // MARK: - Helpers

    var filteredDiffs: [NORDiffEntry] {
        diffs.filter { entry in
            switch filter {
            case "Model":
                return (0x1C7010...0x1C7013).contains(entry.offset) || (0x1C7030...0x1C7033).contains(entry.offset)
            case "Serials":
                return (0x1C7200...0x1C7220).contains(entry.offset)
            case "MAC":
                return (0x1C73C0...0x1C73C5).contains(entry.offset) || (0x1C4020...0x1C4025).contains(entry.offset)
            default:
                return true
            }
        }
    }

    func isGroupOffset(_ offset: Int) -> Bool {
        return (0x1C7200...0x1C7210).contains(offset) ||
               (0x1C7210...0x1C7220).contains(offset) ||
               (0x1C7226...0x1C7238).contains(offset) ||
               (0x1C73C0...0x1C73C6).contains(offset) ||
               (0x1C4020...0x1C4026).contains(offset)
    }

    func loadDropFile(providers: [NSItemProvider], completion: @escaping (Data?) -> Void) -> Bool {
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(UTType.data.identifier) {
                provider.loadDataRepresentation(forTypeIdentifier: UTType.data.identifier) { data, _ in
                    DispatchQueue.main.async {
                        completion(data)
                    }
                }
                return true
            }
        }
        return false
    }

    func diffNORFiles(_ original: Data, _ edited: Data) -> [NORDiffEntry] {
        var output: [NORDiffEntry] = []
        let maxLength = max(original.count, edited.count)

        for offset in 0..<maxLength {
            let origByte = offset < original.count ? original[offset] : 0x00
            let editByte = offset < edited.count ? edited[offset] : 0x00
            if origByte != editByte {
                output.append(NORDiffEntry(offset: offset, originalByte: origByte, editedByte: editByte))
            }
        }
        return output
    }

    func asciiForByte(offset: Int, byte: UInt8) -> String? {
        if (0x1C7200...0x1C7238).contains(offset) && byte != 0xFF && byte >= 0x20 && byte <= 0x7E {
            return String(UnicodeScalar(byte))
        }
        return nil
    }

    func labelForOffset(_ offset: Int) -> OffsetLabel? {
        switch offset {
        case 0x1C7010:
            return OffsetLabel(label: "PS5 Model Signature (Disc)", tooltip: "Disc Edition model identifier")
        case 0x1C7030:
            return OffsetLabel(label: "PS5 Model Signature (Digital)", tooltip: "Digital Edition model identifier")
        case 0x1C7200..<0x1C7210:
            return OffsetLabel(label: "Motherboard Serial", tooltip: "ASCII identifier of the motherboard")
        case 0x1C7210..<0x1C7220:
            return OffsetLabel(label: "Console Serial", tooltip: "ASCII serial of the PS5 console")
        case 0x1C7226..<0x1C7238:
            return OffsetLabel(label: "Board Variant", tooltip: "ASCII region/model code (e.g. CFI-1002A = AU/NZ)")
        case 0x1C73C0..<0x1C73C6:
            return OffsetLabel(label: "Wi-Fi MAC Byte", tooltip: "Part of the Wi-Fi MAC address")
        case 0x1C4020..<0x1C4026:
            return OffsetLabel(label: "LAN MAC Byte", tooltip: "Part of the LAN MAC address")
        default:
            return nil
        }
    }

    func exportDiffAsCSV(diffs: [NORDiffEntry]) {
        var csv = "Offset,Original,Modified,Label\n"
        for entry in diffs {
            let offsetHex = String(format: "0x%06X", entry.offset)
            let origHex = String(format: "%02X", entry.originalByte)
            let modHex = String(format: "%02X", entry.editedByte)
            let label = labelForOffset(entry.offset)?.label ?? ""
            csv += "\(offsetHex),\(origHex),\(modHex),\(label)\n"
        }

        let panel = NSSavePanel()
        panel.title = "Export Comparison"
        panel.nameFieldStringValue = "NOR_Diff.csv"
        panel.allowedContentTypes = [.commaSeparatedText]

        if panel.runModal() == .OK, let url = panel.url {
            try? csv.write(to: url, atomically: true, encoding: .utf8)
        }
    }
}
