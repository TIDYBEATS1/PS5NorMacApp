//
//  HexEditorView.swift
//  PS5NORMacApp
//
//  Created by Sam Stanwell on 26/05/2025.
//


import SwiftUI
import Foundation
import Combine

struct HexEditorView: View {
    let data: Data
    let bytesPerRow = 16

    var body: some View {
        ScrollView(.vertical) {
            LazyVStack(alignment: .leading, spacing: 2) {
                ForEach(0..<numberOfRows(), id: \.self) { row in
                    HStack(alignment: .top) {
                        Text(offsetLabel(for: row))
                            .font(.system(.body, design: .monospaced))
                            .frame(width: 80, alignment: .leading)

                        Text(hexBytes(for: row))
                            .font(.system(.body, design: .monospaced))
                            .frame(width: 300, alignment: .leading)

                        Text(asciiRepresentation(for: row))
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.secondary)
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

    private func offsetLabel(for row: Int) -> String {
        String(format: "%08X", row * bytesPerRow)
    }

    private func hexBytes(for row: Int) -> String {
        rowData(for: row)
            .map { String(format: "%02X", $0) }
            .joined(separator: " ")
    }

    private func asciiRepresentation(for row: Int) -> String {
            rowData(for: row).map { byte in
                let scalar = UnicodeScalar(byte)
                return scalar.isASCII && scalar.isPrintable ? String(scalar) : "."
            }.joined()
        }
    }


private extension UnicodeScalar {
    var isPrintable: Bool {
        (32...126).contains(self.value)
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
