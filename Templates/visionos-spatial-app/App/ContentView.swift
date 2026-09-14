import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "visionpro")
                .font(.system(size: 72))
                .foregroundColor(.cyan)
            Text("Welcome to visionOS")
                .font(.extraLargeTitle)
                .bold()
            Text("Spatial experience for {{PROJECT_NAME}}.")
                .font(.title2)
                .foregroundColor(.secondary)
        }
        .padding(40)
    }
}
