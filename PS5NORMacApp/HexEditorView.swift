import SwiftUI
import Foundation
import Combine

struct HexEditorView: View {
    @EnvironmentObject var settings: AppSettings
    @Binding var data: Data
    let referenceData: Data?
    let bytesPerRow = 16

    var body: some View {
        ScrollView(.vertical) {
            LazyVStack(alignment: .leading, spacing: 2) {
                ForEach(0..<numberOfRows(), id: \.self) { row in
                    HStack(alignment: .top, spacing: 8) {
                        // Offset label
                        Text(offsetLabel(for: row))
                            .font(.system(size: CGFloat(settings.hexFontSize), design: .monospaced))
                            .frame(width: 80, alignment: .leading)

                        // Hex bytes with highlighting
                        hexBytesView(for: row)

                        // ASCII column shown only if advanced hex enabled
                        if settings.showAdvancedHex {
                            asciiRepresentationView(for: row)
                        }
                    }
                }
            }
            .padding()
        }
        .frame(minWidth: 600, minHeight: 300)
    }

    private func numberOfRows() -> Int {
        (data.count + bytesPerRow - 1) / bytesPerRow
    }

    private func rowData(for row: Int) -> [UInt8] {
        let start = row * bytesPerRow
        let end = min(start + bytesPerRow, data.count)
        return Array(data[start..<end])
    }
    
    private func refRowData(for row: Int) -> [UInt8] {
        guard let refData = referenceData else { return [] }
        let start = row * bytesPerRow
        let end = min(start + bytesPerRow, refData.count)
        return Array(refData[start..<end])
    }

    private func offsetLabel(for row: Int) -> String {
        String(format: "%08X", row * bytesPerRow)
    }

    // Hex bytes as individual Text views so we can color individual bytes
    private func hexBytesView(for row: Int) -> some View {
        let bytes = rowData(for: row)
        let refBytes = settings.highlightDifferences ? refRowData(for: row) : []
        
        return HStack(spacing: 4) {
            ForEach(0..<bytes.count, id: \.self) { i in
                let byte = bytes[i]
                let hexString = String(format: "%02X", byte)
                let isDifferent = settings.highlightDifferences && (i < refBytes.count) && (byte != refBytes[i])
                
                Text(hexString)
                    .font(.system(size: CGFloat(settings.hexFontSize), design: .monospaced))
                    .padding(2)
                    .background(isDifferent ? Color.red.opacity(0.5) : Color.clear)
                    .cornerRadius(3)
            }
        }
        .frame(minWidth: 300, alignment: .leading)
    }

    // ASCII with highlighted differences
    private func asciiRepresentationView(for row: Int) -> some View {
        let bytes = rowData(for: row)
        let refBytes = settings.highlightDifferences ? refRowData(for: row) : []
        
        return HStack(spacing: 0) {
            ForEach(0..<bytes.count, id: \.self) { i in
                let byte = bytes[i]
                let scalar = UnicodeScalar(byte)
                let char = (scalar.isASCII && scalar.isPrintable) ? String(scalar) : "."
                let isDifferent = settings.highlightDifferences && (i < refBytes.count) && (byte != refBytes[i])
                
                Text(char)
                    .font(.system(size: CGFloat(settings.hexFontSize), design: .monospaced))
                    .foregroundColor(isDifferent ? .red : .secondary)
            }
        }
        .frame(minWidth: 120, alignment: .leading)
    }
}

private extension UnicodeScalar {
    var isPrintable: Bool {
        (32...126).contains(self.value)
    }
}
