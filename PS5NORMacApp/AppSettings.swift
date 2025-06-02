import Foundation
import Combine

class AppSettings: ObservableObject, Codable {
    enum CodingKeys: CodingKey {
        case autoCheckUpdates, enableTelemetry, showAdvancedHex, highlightDifferences, darkMode, exportPath, hexFontSize
        case defaultBaudRate, autoConnect, logToFile, showHexOutput, uartTimeout, autoUpdateEnabled
    }
    static let shared = AppSettings()
    @Published var autoCheckUpdates: Bool = true
    @Published var enableTelemetry: Bool = false
    @Published var showAdvancedHex: Bool = false
    @Published var highlightDifferences: Bool = true
    @Published var darkMode: Bool = false
    @Published var exportPath: String = ""
    @Published var hexFontSize: Double = 14
    @Published var isUserLoggedIn: Bool = false
    @Published var isTelemetryEnabled: Bool = false
    @Published var defaultBaudRate: Int = 115200
    @Published var autoConnect: Bool = false
    @Published var logToFile: Bool = false
    @Published var showHexOutput: Bool = true
    @Published var uartTimeout: Int = 10
    @Published var autoUpdateEnabled: Bool = true
    // etc.

    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Codable conformance
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        autoCheckUpdates = try container.decode(Bool.self, forKey: .autoCheckUpdates)
        enableTelemetry = try container.decode(Bool.self, forKey: .enableTelemetry)
        showAdvancedHex = try container.decode(Bool.self, forKey: .showAdvancedHex)
        highlightDifferences = try container.decode(Bool.self, forKey: .highlightDifferences)
        darkMode = try container.decode(Bool.self, forKey: .darkMode)
        exportPath = try container.decode(String.self, forKey: .exportPath)
        hexFontSize = try container.decode(Double.self, forKey: .hexFontSize)
        
        defaultBaudRate = try container.decode(Int.self, forKey: .defaultBaudRate)
        autoConnect = try container.decode(Bool.self, forKey: .autoConnect)
        logToFile = try container.decode(Bool.self, forKey: .logToFile)
        showHexOutput = try container.decode(Bool.self, forKey: .showHexOutput)
        uartTimeout = try container.decode(Int.self, forKey: .uartTimeout)
        autoUpdateEnabled = try container.decode(Bool.self, forKey: .autoUpdateEnabled)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(autoCheckUpdates, forKey: .autoCheckUpdates)
        try container.encode(enableTelemetry, forKey: .enableTelemetry)
        try container.encode(showAdvancedHex, forKey: .showAdvancedHex)
        try container.encode(highlightDifferences, forKey: .highlightDifferences)
        try container.encode(darkMode, forKey: .darkMode)
        try container.encode(exportPath, forKey: .exportPath)
        try container.encode(hexFontSize, forKey: .hexFontSize)
        
        try container.encode(defaultBaudRate, forKey: .defaultBaudRate)
        try container.encode(autoConnect, forKey: .autoConnect)
        try container.encode(logToFile, forKey: .logToFile)
        try container.encode(showHexOutput, forKey: .showHexOutput)
        try container.encode(uartTimeout, forKey: .uartTimeout)
        try container.encode(autoUpdateEnabled, forKey: .autoUpdateEnabled)
    }
    
    // MARK: - Initialization and Persistence
    
    init() {
        load()
        setupAutoSave()
    }
    
    private let userDefaultsKey = "AppSettings"
    
    func load() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else { return }
        if let decoded = try? JSONDecoder().decode(AppSettings.self, from: data) {
            DispatchQueue.main.async {
                self.autoCheckUpdates = decoded.autoCheckUpdates
                self.enableTelemetry = decoded.enableTelemetry
                self.showAdvancedHex = decoded.showAdvancedHex
                self.highlightDifferences = decoded.highlightDifferences
                self.darkMode = decoded.darkMode
                self.exportPath = decoded.exportPath
                self.hexFontSize = decoded.hexFontSize
                
                self.defaultBaudRate = decoded.defaultBaudRate
                self.autoConnect = decoded.autoConnect
                self.logToFile = decoded.logToFile
                self.showHexOutput = decoded.showHexOutput
                self.uartTimeout = decoded.uartTimeout
                self.autoUpdateEnabled = decoded.autoUpdateEnabled
            }
        }
    }
    
    func save() {
        if let encoded = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
    
    private func setupAutoSave() {
        Publishers.MergeMany(
            $autoCheckUpdates.map { _ in true }.eraseToAnyPublisher(),
            $enableTelemetry.map { _ in true }.eraseToAnyPublisher(),
            $showAdvancedHex.map { _ in true }.eraseToAnyPublisher(),
            $highlightDifferences.map { _ in true }.eraseToAnyPublisher(),
            $darkMode.map { _ in true }.eraseToAnyPublisher(),
            $exportPath.map { _ in true }.eraseToAnyPublisher(),
            $hexFontSize.map { _ in true }.eraseToAnyPublisher(),
            $defaultBaudRate.map { _ in true }.eraseToAnyPublisher(),
            $autoConnect.map { _ in true }.eraseToAnyPublisher(),
            $logToFile.map { _ in true }.eraseToAnyPublisher(),
            $showHexOutput.map { _ in true }.eraseToAnyPublisher(),
            $uartTimeout.map { _ in true }.eraseToAnyPublisher(),
            $autoUpdateEnabled.map { _ in true }.eraseToAnyPublisher()
        )
        .debounce(for: .seconds(1), scheduler: RunLoop.main)
        .sink { [weak self] _ in self?.save() }
        .store(in: &cancellables)
    }
    
    func resetDefaults() {
        autoCheckUpdates = true
        enableTelemetry = false
        showAdvancedHex = false
        highlightDifferences = true
        darkMode = false
        exportPath = ""
        hexFontSize = 14
        
        defaultBaudRate = 115200
        autoConnect = false
        logToFile = false
        showHexOutput = true
        uartTimeout = 10
        autoUpdateEnabled = true
    }
}
