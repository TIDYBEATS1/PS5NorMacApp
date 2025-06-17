import SwiftUI

struct PatchNotesSheetView: View {
    let notes: String
    let onUpdate: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("🚀 New Version Available")
                .font(.title2)
                .bold()

            ScrollView {
                Text(notes)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }

            HStack(spacing: 16) {
                Button("Later") {
                    onCancel()
                }
                Button("Update Now") {
                    onUpdate()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(minWidth: 400, minHeight: 300)
    }
}

// Example preview
struct PatchNotesSheetView_Previews: PreviewProvider {
    static var previews: some View {
        PatchNotesSheetView(
            notes: "- Added support for NOR file comparison\n- Improved EMC export tool\n- Minor bug fixes and UI enhancements",
            onUpdate: {},
            onCancel: {}
        )
    }
}
