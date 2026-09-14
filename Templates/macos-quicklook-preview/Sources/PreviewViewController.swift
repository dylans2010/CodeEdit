import Cocoa
import Quartz

class PreviewViewController: NSViewController, QLPreviewingController {
    override func loadView() {
        let label = NSTextField(labelWithString: "QuickLook Preview for {{PROJECT_NAME}}")
        label.alignment = .center
        self.view = label
    }

    func preparePreviewOfFile(at url: URL, completionHandler handler: @escaping (Error?) -> Void) {
        handler(nil)
    }
}
