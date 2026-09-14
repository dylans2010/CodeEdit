import SwiftUI

struct ContentView: View {
    @State private var selectedTab: String? = "Dashboard"

    var body: some View {
        NavigationSplitView {
            List(["Dashboard", "Projects", "Settings"], id: \.self, selection: $selectedTab) { item in
                NavigationLink(value: item) {
                    Label(item, systemImage: iconFor(item))
                }
            }
            .navigationTitle("{{PROJECT_NAME}}")
        } detail: {
            VStack(spacing: 16) {
                Image(systemName: "laptopcomputer")
                    .font(.system(size: 48))
                    .foregroundColor(.accentColor)
                Text("Welcome to {{PROJECT_NAME}}")
                    .font(.title)
                    .bold()
                Text("Selected: \(selectedTab ?? "None")")
                    .foregroundColor(.secondary)
            }
            .frame(minWidth: 400, minHeight: 300)
        }
    }

    private func iconFor(_ name: String) -> String {
        switch name {
        case "Dashboard": return "gauge"
        case "Projects": return "folder"
        case "Settings": return "gear"
        default: return "circle"
        }
    }
}
