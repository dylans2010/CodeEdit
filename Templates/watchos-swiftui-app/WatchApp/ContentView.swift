import SwiftUI

struct ContentView: View {
    @State private var counter = 0

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                Image(systemName: "applewatch")
                    .font(.title)
                    .foregroundColor(.green)
                Text("{{PROJECT_NAME}}")
                    .font(.headline)
                Button("Count: \(counter)") {
                    counter += 1
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
    }
}
