//
//  AppInfo.swift
//  PS5NORMacApp
//
//  Created by Sam Stanwell on 02/06/2025.
//


import Foundation

struct AppInfo {
    static var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "3.0.0"
    }
}
