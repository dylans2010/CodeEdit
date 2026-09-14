import SwiftUI

struct MenuBarView: View {
    @State private var isEnabled = true

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("{{PROJECT_NAME}}")
                    .font(.headline)
                Spacer()
                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
            }
            Divider()
            Toggle("Enable Status Service", isOn: $isEnabled)
            Button("Action Item") {
                print("Clicked action")
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .frame(width: 240)
    }
}
