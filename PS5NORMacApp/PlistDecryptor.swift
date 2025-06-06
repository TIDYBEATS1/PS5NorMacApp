//
//  PlistDecryptor.swift
//  PS5NORMacApp
//
//  Created by Sam Stanwell on 03/06/2025.
//


import Foundation
import CryptoSwift

enum PlistDecryptor {
    static let key = "mZ4vRq0sJh1W8XeBYoLpK92fAgDMtQn6".bytes  // 32 bytes

    static func decryptedPlistData() -> Data? {
        guard let encURL = Bundle.main.url(forResource: "googleServiceInfo", withExtension: "enc"),
              let encryptedData = try? Data(contentsOf: encURL) else {
            print("❌ Failed to load encrypted file")
            return nil
        }

        let iv = encryptedData.prefix(16).bytes
        let ciphertext = encryptedData.dropFirst(16).bytes

        do {
            let aes = try AES(key: key, blockMode: CBC(iv: iv), padding: .pkcs7)
            let decrypted = try aes.decrypt(ciphertext)
            return Data(decrypted)
        } catch {
            print("❌ Decryption failed: \(error)")
            return nil
        }
    }
}