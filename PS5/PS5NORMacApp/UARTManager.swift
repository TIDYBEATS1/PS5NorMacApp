import Foundation
import Combine
import Darwin.C

class UARTManager: ObservableObject {
    @Published var availablePorts: [String] = []
    @Published var receivedData: String = ""
    @Published var isConnected: Bool = false
    @Published var errorCodes: PS5ErrorCodeDictionary = [:]
    @Published var detectedErrorCodes: [String] = []
    
    typealias PS5ErrorCodeDictionary = [String: PS5ErrorCode]
    
    private var fileDescriptor: Int32 = -1
    private let readQueue = DispatchQueue(label: "UARTReadQueue")
    private var readSource: DispatchSourceRead?
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        refreshPorts()
        loadErrorCodes()
    }
    
    func refreshPorts() {
        let serialPrefixes = ["tty.", "cu."]
        let devPath = "/dev"
        
        do {
            let files = try FileManager.default.contentsOfDirectory(atPath: devPath)
            let ports = files.filter { filename in
                serialPrefixes.contains(where: { prefix in
                    filename.hasPrefix(prefix)
                })
            }.map { "/dev/" + $0 }
            
            DispatchQueue.main.async {
                self.availablePorts = ports.sorted()
            }
        } catch {
            print("Failed to list /dev: \(error)")
            DispatchQueue.main.async {
                self.availablePorts = []
            }
        }
    }
    
    func loadErrorCodes() {
        guard let url = Bundle.main.url(forResource: "errorCodes", withExtension: "json") else {
            print("UARTManager Error: JSON file 'errorCodes.json' not found in bundle")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoded: PS5ErrorCodeDictionary = try JSONDecoder().decode(PS5ErrorCodeDictionary.self, from: data)
            DispatchQueue.main.async {
                self.errorCodes = decoded
                print("UARTManager: Loaded \(decoded.count) PS5 error codes.")
            }
        } catch {
            print("UARTManager Error decoding JSON: \(error)")
        }
    }
    
    func connect(to portPath: String, baudRate: speed_t = 115200) {
        disconnect() // clean up any existing connection
        
        fileDescriptor = open(portPath, O_RDWR | O_NOCTTY | O_NONBLOCK)
        guard fileDescriptor != -1 else {
            print("Failed to open port \(portPath)")
            return
        }
        
        var options = termios()
        tcgetattr(fileDescriptor, &options)
        cfmakeraw(&options) // raw input/output, no processing
        
        // Set baud rate
        cfsetispeed(&options, baudRate)
        cfsetospeed(&options, baudRate)
        
        // 8N1 config, no parity, enable read, ignore modem controls
        options.c_cflag &= ~UInt(PARENB)
        options.c_cflag &= ~UInt(CSTOPB)
        options.c_cflag &= ~UInt(CSIZE)
        options.c_cflag |= UInt(CS8)
        options.c_cflag |= UInt(CREAD | CLOCAL)
        
        options.c_lflag = 0
        options.c_iflag = 0
        options.c_oflag = 0
        
        // Control chars
        options.c_cc.16 = 1  // VMIN: minimum bytes to read
        options.c_cc.17 = 0  // VTIME: no timeout
        
        tcsetattr(fileDescriptor, TCSANOW, &options)
        
        isConnected = true
        startReading()
        print("Connected to \(portPath) at baudRate \(baudRate)")
    }
    
    func disconnect() {
        stopReading()
        
        if fileDescriptor != -1 {
            close(fileDescriptor)
            fileDescriptor = -1
        }
        isConnected = false
        print("Disconnected")
    }
    
    private func startReading() {
        guard fileDescriptor != -1 else { return }
        
        readSource = DispatchSource.makeReadSource(fileDescriptor: fileDescriptor, queue: readQueue)
        readSource?.setEventHandler { [weak self] in
            guard let self = self else { return }
            
            var buffer = [UInt8](repeating: 0, count: 1024)
            let bytesRead = read(self.fileDescriptor, &buffer, buffer.count)
            
            if bytesRead > 0 {
                if let string = String(bytes: buffer[0..<bytesRead], encoding: .utf8) {
                    DispatchQueue.main.async {
                        self.processReceivedData(string)
                    }
                }
            } else if bytesRead == 0 {
                // EOF, disconnect
                self.disconnect()
            } else {
                perror("Read error")
                self.disconnect()
            }
        }
        
        readSource?.setCancelHandler {
            // Cleanup if needed
        }
        
        readSource?.resume()
    }
    
    private func stopReading() {
        readSource?.cancel()
        readSource = nil
    }
    
    func send(command: String) {
        guard fileDescriptor != -1 else {
            print("Port not connected")
            return
        }
        
        let cmd = command + "\n"
        if let data = cmd.data(using: .utf8) {
            data.withUnsafeBytes { ptr in
                var bytesWritten = 0
                while bytesWritten < data.count {
                    let writeResult = write(fileDescriptor, ptr.baseAddress!.advanced(by: bytesWritten), data.count - bytesWritten)
                    if writeResult > 0 {
                        bytesWritten += writeResult
                    } else {
                        perror("Write error")
                        break
                    }
                }
            }
        }
    }
    
    func processReceivedData(_ data: String) {
        receivedData += data
        
        // Regex for PS5 error codes like CE-xxxxx-x
        let pattern = #"CE-\d{6}-\d"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            print("UARTManager Error: Failed to create regex")
            return
        }
        
        let matches = regex.matches(in: receivedData, options: [], range: NSRange(location: 0, length: receivedData.utf16.count))
        
        for match in matches {
            if let range = Range(match.range, in: receivedData) {
                let code = String(receivedData[range])
                
                if !detectedErrorCodes.contains(code) {
                    detectedErrorCodes.append(code)
                    print("UARTManager: Detected new error code: \(code)")
                }
            }
        }
        
        // Limit stored received data to last 1000 chars for performance
        if receivedData.count > 2000 {
            receivedData = String(receivedData.suffix(1000))
        }
    }
    
    // MARK: - Error code helpers
    
    func scanForErrorCodes() {
        DispatchQueue.main.async {
            self.receivedData = ""
            self.detectedErrorCodes = []
        }
        if !isConnected {
            print("UARTManager: Not connected. Please connect to a port first.")
        } else {
            print("UARTManager: Starting scan for error codes...")
            // Data processing will detect codes automatically
        }
    }
    
    func getErrorDescription(for code: String) -> PS5ErrorCode? {
        return errorCodes[code]
    }
}
