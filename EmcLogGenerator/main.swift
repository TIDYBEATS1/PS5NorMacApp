import Foundation

// Check for correct argument count
let args = CommandLine.arguments
guard args.count > 1 else {
    fputs("Usage: EmcLogGenerator <path to .bin file>\n", stderr)
    exit(1)
}

let binFilePath = args[1]

// Validate .bin file existence
guard FileManager.default.fileExists(atPath: binFilePath) else {
    fputs("❌ Could not find .bin file at path: \(binFilePath)\n", stderr)
    exit(1)
}

// Locate decode_emc.py relative to the CLI tool
let executableURL = URL(fileURLWithPath: CommandLine.arguments[0])
let scriptURL = executableURL.deletingLastPathComponent().appendingPathComponent("decode_emc.py")

guard FileManager.default.fileExists(atPath: scriptURL.path) else {
    fputs("❌ Could not find decode_emc.py in the same folder as the executable at path: \(scriptURL.path)\n", stderr)
    exit(1)
}

// Set up the process to run the python script
let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
process.arguments = [scriptURL.path, binFilePath]

// Capture stdout and stderr
let outputPipe = Pipe()
process.standardOutput = outputPipe
process.standardError = outputPipe

do {
    try process.run()
    process.waitUntilExit()

    let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
    let outputString = String(data: outputData, encoding: .utf8) ?? ""
    print(outputString)

    // Return the same exit code as the Python script
    exit(process.terminationStatus)
} catch {
    fputs("❌ Failed to run Python script: \(error)\n", stderr)
    exit(1)
}
