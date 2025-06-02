//
//  UpdateInfo.swift
//  PS5NORMacApp
//
//  Created by Sam Stanwell on 30/05/2025.
//


import Foundation

struct UpdateInfo: Codable {
    let latestVersion: String
    let downloadURL: String
    let releaseNotes: String
}