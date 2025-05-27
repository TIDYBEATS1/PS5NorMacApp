import Foundation
import Combine

class HexEditorViewModel: ObservableObject {
    @Published var hexString: String = ""
    
    func updateHexData(_ data: Data) {
        hexString = data.map { String(format: "%02X ", $0) }.joined()
    }
}
