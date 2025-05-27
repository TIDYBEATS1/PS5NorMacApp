//
//  HexEditorView.swift
//  PS5NORMacApp
//
//  Created by Sam Stanwell on 26/05/2025.
//


import SwiftUI

struct HexEditorView: View {
    let data: Data
    let bytesPerRow = 16

    var body: some View {
        ScrollView(.vertical) {
            LazyVStack(alignment: .leading, spacing: 2) {
                ForEach(0..<data.count / bytesPerRow + 1, id: \.self) { row in
                    HStack(alignment: .top) {
                        Text(String(format: "%08X", row * bytesPerRow))
                            .font(.system(.body, design: .monospaced))
                            .frame(width: 80, alignment: .leading)

                        let rowData = data[safe: row * bytesPerRow ..< min((row + 1) * bytesPerRow, data.count)]
                        Text(rowData.map { String(format: "%02X", $0) }.joined(separator: " "))
                            .font(.system(.body, design: .monospaced))
                            .frame(width: 300, alignment: .leading)

                        Text(rowData.map { byte in
                            let scalar = UnicodeScalar(byte)
                            return scalar?.isASCII == true && scalar!.isPrintable ? String(scalar!) : "."
                        }.joined())
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
        }
        .frame(minWidth: 600, minHeight: 300)
    }
}

private extension UnicodeScalar {
    var isPrintable: Bool {
        return (32...126).contains(self.value)
    }
}

private extension Data {
    subscript(safe range: Range<Int>) -> [UInt8] {
        return range.compactMap { index in
            guard index < self.count else { return nil }
            return self[index]
        }
    }
}