import SwiftUI

// MARK: - Supporting Models

struct TerminalLine: Identifiable, Equatable {
    let id = UUID()
    let offset: Int
    let text: String

    static func ==(lhs: TerminalLine, rhs: TerminalLine) -> Bool {
        lhs.id == rhs.id && lhs.offset == rhs.offset && lhs.text == rhs.text
    }
}



// MARK: - Main View

struct UARTTerminalView: View {
    @EnvironmentObject private var viewModel: UARTViewModel
    @State private var command: String = ""
    
    private var terminalLines: [TerminalLine] {
        viewModel.terminalOutput.components(separatedBy: .newlines)
            .enumerated()
            .map { TerminalLine(offset: $0.offset, text: $0.element) }
    }
    @State private var currentCommand = ""
    
    var body: some View {
        ScrollView {
            GroupBox {
                VStack(alignment: .leading, spacing: 8) {
                    ConnectionStatusView(
                        isConnected: viewModel.isConnected,
                        toggleConnection: { viewModel.toggleConnection() },
                        clearTerminal: { viewModel.clearTerminal() }
                    )
                    TerminalDisplayView(lines: terminalLines)
                    CommandInputView(
                        command: $command,
                        sendCommand: {
                            viewModel.sendCommand(command)
                            command = ""
                        }
                    )
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
            } label: {
                Text("UART Terminal").font(.headline)
            }
            .padding()
            
            Divider()
            
            CommandInputView(command: $currentCommand) {
                sendCommand(currentCommand)
            }
        }
    }
    
    func sendCommand(_ command: String) {
        // Append command to terminal, send over UART, etc.
        print("Command sent: \(command)")
        currentCommand = ""
    }
}

// MARK: - Subviews

private struct ConnectionStatusView: View {
    let isConnected: Bool
    let toggleConnection: () -> Void
    let clearTerminal: () -> Void

    var body: some View {
        HStack {
            Circle()
                .frame(width: 12, height: 12)
                .foregroundColor(isConnected ? .green : .red)
            Text(isConnected ? "Connected" : "Disconnected")
                .font(.caption)
                .foregroundColor(.gray)
            Spacer()
            Button(action: toggleConnection) {
                Text(isConnected ? "Disconnect" : "Connect")
                    .font(.caption)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(4)
            }
            Button(action: clearTerminal) {
                Text("Clear Terminal")
                    .font(.caption)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(4)
            }
        }
    }
}

private struct TerminalDisplayView: View {
    let lines: [TerminalLine]

    var body: some View {
        ScrollView {
            ScrollViewReader { proxy in
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(lines) { line in
                        TerminalLineView(index: line.offset, text: line.text)
                            .id(line.id)
                    }
                }
                .onChange(of: lines.count) { _ in
                    if let lastLine = lines.last {
                        withAnimation {
                            proxy.scrollTo(lastLine.id, anchor: .bottom)
                        }
                    }
                }
            }
        }
        .frame(minHeight: 200, maxHeight: 400)
        .background(Color.black)
        .cornerRadius(8)
    }
}

private struct TerminalLineView: View {
    let index: Int
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("\(index + 1)")
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.gray)
                .frame(width: 30, alignment: .trailing)
            Text(text)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.green)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
    }
}
