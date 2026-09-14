import SwiftUI
import SwiftData

@Model
final class Item {
    var timestamp: Date
    var title: String

    init(title: String, timestamp: Date = .now) {
        self.title = title
        self.timestamp = timestamp
    }
}

@main
struct SwiftDataApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: Item.self)
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]

    var body: some View {
        NavigationStack {
            List {
                ForEach(items) { item in
                    Text(item.title)
                }
            }
            .navigationTitle("{{PROJECT_NAME}}")
            .toolbar {
                Button("Add") {
                    modelContext.insert(Item(title: "Task #\(items.count + 1)"))
                }
            }
        }
    }
}
