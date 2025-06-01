import SwiftUI

struct PS4View: View {
    let fileData: Data

    var body: some View {
        VStack {
            Text("PS4 NOR Data Viewer")
                .font(.title)
                .padding(.bottom)

            Text("Loaded File Size: \(fileData.count) bytes")
                .font(.subheadline)

            // Add custom PS4 metadata decoding logic here
            Text("More PS4 tools coming soon!")
                .foregroundColor(.gray)
                .padding(.top)
        }
        .padding()
    }
}