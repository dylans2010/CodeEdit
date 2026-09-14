import SwiftUI

extension NSTableView {
    /// Allows to set a lists background color in SwiftUI
    override open func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()

        backgroundColor = NSColor.clear
        enclosingScrollView?.drawsBackground = false
    }
}
