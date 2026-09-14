import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let rect = NSRect(x: 0, y: 0, width: 600, height: 400)
        window = NSWindow(
            contentRect: rect,
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window?.title = "{{PROJECT_NAME}}"
        window?.center()

        let label = NSTextField(labelWithString: "Hello from AppKit & {{PROJECT_NAME}}")
        label.font = .systemFont(ofSize: 20, weight: .semibold)
        label.alignment = .center

        window?.contentView = label
        window?.makeKeyAndOrderFront(nil)
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }
}
