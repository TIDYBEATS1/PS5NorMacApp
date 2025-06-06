import SwiftUI

struct PatchNotesSheetView: View {
    let notes: String
    let onUpdate: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("New Update Available")
                .font(.title)
                .bold()

            ScrollView {
                Text(notes)
                    .font(.body)
                    .padding()
                    .background(Color(NSColor.textBackgroundColor))
                    .cornerRadius(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(minHeight: 200)

            HStack {
                Spacer()
                Button("Cancel") {
                    onCancel()
                }
                .keyboardShortcut(.cancelAction)

                Button("Update Now") {
                    onUpdate()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 500)
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
