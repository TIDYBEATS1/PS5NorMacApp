//
//  CommandInputView.swift
//  PS5NORMacApp
//
//  Created by Sam Stanwell on 28/05/2025.
//


import SwiftUI

struct CommandInputView: View {
    @Binding var command: String
    let sendCommand: () -> Void

    var body: some View {
        HStack {
            TextField("Enter command", text: $command)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onSubmit {
                    sendCommand()
                }

            Button(action: sendCommand) {
                Image(systemName: "paperplane.fill")
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Color.blue)
                    .clipShape(Circle())
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding()
    }
}