//
//  PS5ErrorCodes.swift
//  PS5NORMacApp
//
//  Created by Sam Stanwell on 27/05/2025.
//

import Foundation

struct PS5ErrorCode: Identifiable, Codable {
    let code: String
    let description: String
    let solution: String?

    var id: String { code }
}
