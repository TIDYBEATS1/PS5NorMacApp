import SwiftUI
import UniformTypeIdentifiers
import AppKit

let highlightedOffsets: [Int] = Array(
    Set(
        Array(0x1C7200..<0x1C7210) +  // Motherboard Serial
        Array(0x1C7210..<0x1C7220) +  // Console Serial
        Array(0x1C7226..<0x1C7238) +  // Board Variant
        Array(0x1C73C0..<0x1C73C6) +  // WiFi MAC
        Array(0x1C4020..<0x1C4026)    // LAN MAC
    )
).sorted()

struct HexEditorView: View {
    @EnvironmentObject var settings: AppSettings

    @State private var editableData: Data = Data()
    @State private var fileURL: URL?
    @State private var showFileImporter = false
    @State private var invalidBytes: Set<Int> = []

    let bytesPerRow = 16

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Button("Open .bin File") {
                    showFileImporter = true
                }

                Button("Save As…") {
                    saveEditedHex()
                }
                .disabled(editableData.isEmpty)

                if let fileURL = fileURL {
                    Text("Editing: \(fileURL.lastPathComponent)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding([.horizontal, .top])

            Divider()

            ScrollView(.vertical) {
                LazyVStack(alignment: .leading, spacing: 2) {
                    if !editableData.isEmpty {
                        GroupBox(label: Text("Highlighted Sections")) {
                            ForEach(highlightedOffsets.map { $0 / bytesPerRow }.removingDuplicates(), id: \.self) { row in                                VStack(alignment: .leading, spacing: 4) {
                                    if let label = labelForOffsetRow(row) {
                                        Text(label)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    rowView(for: row)
                                    Divider()
                                }
                            }
                        }
                    }

                    ForEach(0..<numberOfRows(), id: \.self) { row in
                        rowView(for: row)
                    }
                }
                .padding()
            }

            Divider()

            HStack {
                let checksumValue = calculateChecksum(from: editableData)
                Text("Checksum: 0x\(String(format: "%02X", checksumValue)) (\(checksumValue))")
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundColor(isChecksumValid(checksumValue) ? .green : .red)

                Spacer()
            }
            .padding(.vertical, 6)
            .padding(.horizontal)
        }
        .frame(minWidth: 600, minHeight: 300)
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.data],
            allowsMultipleSelection: false
        ) { result in
            do {
                guard let selected = try result.get().first else { return }
                self.fileURL = selected
                self.editableData = try Data(contentsOf: selected)
                self.invalidBytes.removeAll()
                print("Loaded editable file: \(selected.lastPathComponent)")
            } catch {
                print("Failed to load editable file: \(error)")
            }
        }
    }

    private func rowView(for row: Int) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(offsetLabel(for: row))
                .font(.system(size: CGFloat(settings.hexFontSize), design: .monospaced))
                .frame(width: 80, alignment: .leading)

            hexBytesView(for: row)

            if settings.showAdvancedHex {
                asciiRepresentationView(for: row)
            }
        }
    }

    private func hexBytesView(for row: Int) -> some View {
        let startOffset = row * bytesPerRow
        let endOffset = min(startOffset + bytesPerRow, editableData.count)

        return HStack(spacing: 4) {
            ForEach(startOffset..<endOffset, id: \.self) { i in
                let byte = editableData[i]
                let isHighlighted = highlightedOffsets.contains(i)

                TextField("", text: Binding(
                    get: { String(format: "%02X", editableData[i]) },
                    set: { newValue in
                        let upper = newValue.uppercased()
                        if let byte = UInt8(upper, radix: 16) {
                            editableData[i] = byte
                            invalidBytes.remove(i)
                        } else {
                            invalidBytes.insert(i)
                        }
                    })
                )
                .font(.system(size: CGFloat(settings.hexFontSize), design: .monospaced))
                .frame(width: 32)
                .padding(2)
                .background(invalidBytes.contains(i) ? Color.red.opacity(0.5) : isHighlighted ? Color.yellow.opacity(0.4) : Color.clear)
                .cornerRadius(3)
                .textFieldStyle(PlainTextFieldStyle())
            }
        }
        .frame(minWidth: 300, alignment: .leading)
    }

    private func asciiRepresentationView(for row: Int) -> some View {
        let startOffset = row * bytesPerRow
        let endOffset = min(startOffset + bytesPerRow, editableData.count)

        return HStack(spacing: 0) {
            ForEach(startOffset..<endOffset, id: \.self) { i in
                let byte = editableData[i]
                let scalar = UnicodeScalar(byte)
                let char = (scalar.isASCII && scalar.isPrintable) ? String(scalar) : "."

                Text(char)
                    .font(.system(size: CGFloat(settings.hexFontSize), design: .monospaced))
                    .foregroundColor(.secondary)
            }
        }
        .frame(minWidth: 120, alignment: .leading)
    }

    private func numberOfRows() -> Int {
        (editableData.count + bytesPerRow - 1) / bytesPerRow
    }

    private func offsetLabel(for row: Int) -> String {
        String(format: "%08X", row * bytesPerRow)
    }

    private func labelForOffsetRow(_ row: Int) -> String? {
        let start = row * bytesPerRow
        switch start {
        case 0x1C7200..<0x1C7210:
            return "Motherboard Serial"
        case 0x1C7210..<0x1C7220:
            return "Console Serial"
        case 0x1C7226..<0x1C7238:
            return "Board Variant"
        case 0x1C73C0..<0x1C73C6:
            return "WiFi MAC Address"
        case 0x1C4020..<0x1C4026:
            return "LAN MAC Address"
        default:
            return nil
        }
    }

    private func calculateChecksum(from data: Data) -> Int {
        data.reduce(0) { $0 + Int($1) } & 0xFF
    }

    private func isChecksumValid(_ value: Int) -> Bool {
        (0x00...0xFF).contains(value)
    }

    private func saveEditedHex() {
        let panel = NSSavePanel()
        panel.allowedFileTypes = ["bin"]
        panel.nameFieldStringValue = "EditedPS5Nor.bin"

        if panel.runModal() == .OK, let url = panel.url {
            do {
                try editableData.write(to: url)
            } catch {
                print("Failed to save edited file: \(error)")
            }
        }
    }
}

private extension UnicodeScalar {
    var isPrintable: Bool {
        (32...126).contains(self.value)
    }
}

private extension Array where Element: Hashable {
    func removingDuplicates() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}
