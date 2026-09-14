import SwiftUI

@main
struct SafariExtensionApp: App {
    var body: some Scene {
        WindowGroup {
            VStack(spacing: 16) {
                Image(systemName: "safari")
                    .font(.system(size: 48))
                    .foregroundColor(.blue)
                Text("{{PROJECT_NAME}}")
                    .font(.headline)
                Text("Manage your Safari Extension settings.")
                    .foregroundColor(.secondary)
            }
            .padding()
            .frame(width: 320, height: 200)
        }
    }
}
