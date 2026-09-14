import SwiftUI

struct ExtensionNavigatorItemView: View {
    var plugin: Plugin
    @EnvironmentObject var document: WorkspaceDocument

    var body: some View {
        Button {
            document.openTab(item: plugin)
        } label: {
            ZStack {
                HStack {
                    VStack(alignment: .leading) {
                        Text(plugin.manifest.displayName)
                            .font(.headline)
                        Text(plugin.manifest.name)
                            .font(.subheadline)
                    }
                    Spacer()
                }
            }
        }
        .buttonStyle(.plain)
    }
}
