import SwiftUI

@main
struct {{PROJECT_NAME}}App: App {
    var body: some Scene {
        MenuBarExtra("{{PROJECT_NAME}}", systemImage: "sparkles") {
            MenuBarView()
        }
        .menuBarExtraStyle(.window)
    }
}
