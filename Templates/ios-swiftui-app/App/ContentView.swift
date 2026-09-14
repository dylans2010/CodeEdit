import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            NavigationStack {
                VStack(spacing: 20) {
                    Image(systemName: "iphone.gen3")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    Text("{{PROJECT_NAME}}")
                        .font(.largeTitle)
                        .bold()
                    Text("Welcome to your new iOS SwiftUI application.")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                }
                .padding()
                .navigationTitle("Home")
            }
            .tabItem {
                Label("Home", systemImage: "house")
            }

            NavigationStack {
                List(1..<11) { index in
                    Text("Item #\(index)")
                }
                .navigationTitle("Explore")
            }
            .tabItem {
                Label("Explore", systemImage: "safari")
            }
        }
    }
}
