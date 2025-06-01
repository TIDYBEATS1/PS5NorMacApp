import Foundation
import CryptoKit

struct SysconDumper {
    static func dump(from portPath: String) async -> String {
        let fd = open(portPath, O_RDWR | O_NOCTTY | O_NONBLOCK)
        if fd == -1 {
            return "Failed to open serial port"
        }

        // Configure port (115200 8N1)
        var options = termios()
        tcgetattr(fd, &options)
        cfmakeraw(&options)
        cfsetspeed(&options, speed_t(B115200))
        options.c_cflag |= (CLOCAL | CREAD)
        tcsetattr(fd, TCSANOW, &options)
        fcntl(fd, F_SETFL, 0) // Make blocking again

        // Send dump command
        let dumpCommand: [UInt8] = [0x44] // Replace with real command
        write(fd, dumpCommand, dumpCommand.count)

        // Read response
        let expectedDumpSize = 512 * 1024 // 512KB typical
        var receivedData = Data()
        let bufferSize = 1024
        var buffer = [UInt8](repeating: 0, count: bufferSize)

        let start = Date()
        while receivedData.count < expectedDumpSize && Date().timeIntervalSince(start) < 20 {
            let bytesRead = read(fd, &buffer, bufferSize)
            if bytesRead > 0 {
                receivedData.append(buffer.prefix(bytesRead))
            } else {
                usleep(10000) // 10ms
            }
        }

        close(fd)

        if receivedData.count < expectedDumpSize {
            return "Dump incomplete: \(receivedData.count)/\(expectedDumpSize) bytes"
        }

        // Save dump
        let dumpPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Desktop/syscon_dump.bin")
        do {
            try receivedData.write(to: dumpPath)
        } catch {
            return "Failed to save dump: \(error.localizedDescription)"
        }

        // Validate hash
        let knownHash = "abcdef1234567890..." // Replace with real hash
        let computedHash = Insecure.MD5.hash(data: receivedData)
            .map { String(format: "%02hhx", $0) }.joined()

        return computedHash == knownHash
            ? "PASS ✅ Dump OK"
            : "FAIL ❌ Hash mismatch"
    }
}