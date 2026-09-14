import SwiftUI

struct IgnoredFileView: View {
    @Binding
    var ignoredFile: IgnoredFiles

    var body: some View {
        Text(ignoredFile.name)
    }
}
