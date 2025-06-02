//
//  MainContentView.swift
//  PS5NORMacApp
//
//  Created by Sam Stanwell on 02/06/2025.
//


import SwiftUI

struct MainContentView: View {
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var auth: AuthManager
    @EnvironmentObject var updater: Updater

    @State private var skipLogin = false

    var body: some View {
        ZStack {
            ContentView()
                .environmentObject(settings)
            
        }
    }
}
