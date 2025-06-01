import Combine

class Settings: ObservableObject {
    @Published var autoConnect: Bool = false
    @Published var logToFile: Bool = false
    @Published var showHexOutput: Bool = false
}