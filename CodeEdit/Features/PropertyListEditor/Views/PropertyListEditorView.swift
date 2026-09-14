import SwiftUI

struct PropertyListEditorView: View {
    @StateObject private var manager: PropertyListManager
    @ObservedObject var codeFile: CodeFileDocument

    init(codeFile: CodeFileDocument, fileURL: URL) {
        self.codeFile = codeFile
        _manager = StateObject(
            wrappedValue: PropertyListManager(
                fileURL: fileURL,
                rawContent: codeFile.content
            )
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            toolbarView
            Divider()

            if manager.viewMode == .propertyList {
                propertyListView
            } else {
                sourceCodeView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var toolbarView: some View {
        HStack(spacing: 12) {
            Image(systemName: isEntitlements ? "checkmark.seal.fill" : "tablecells.fill")
                .foregroundColor(.accentColor)
                .font(.system(size: 14))

            Text(manager.fileURL.lastPathComponent)
                .font(.system(size: 13, weight: .semibold))

            Spacer()

            Picker("", selection: $manager.viewMode) {
                ForEach(PlistViewMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 190)

            if manager.viewMode == .propertyList {
                Button {
                    manager.addRow(to: manager.rootNode)
                } label: {
                    Label("Add Item", systemImage: "plus")
                }
                .buttonStyle(.bordered)
            }

            Button {
                manager.saveToDisk()
                codeFile.content = manager.rawContent
            } label: {
                Label("Save", systemImage: "square.and.arrow.down")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var isEntitlements: Bool {
        manager.fileURL.pathExtension == "entitlements"
    }

    private var propertyListView: some View {
        VStack(spacing: 0) {
            tableHeader
            Divider()

            ScrollView {
                LazyVStack(spacing: 0) {
                    if manager.rootNode.children.isEmpty {
                        Text("No items in Property List")
                            .font(.callout)
                            .foregroundColor(.secondary)
                            .padding(32)
                    } else {
                        ForEach(manager.rootNode.children) { child in
                            PropertyListRowView(
                                node: child,
                                parent: manager.rootNode,
                                manager: manager,
                                depth: 0
                            )
                        }
                    }
                }
            }
        }
    }

    private var tableHeader: some View {
        HStack {
            Text("Key")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
                .frame(width: 220, alignment: .leading)
            Text("Type")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
                .frame(width: 110, alignment: .leading)
            Text("Value")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private var sourceCodeView: some View {
        TextEditor(text: $manager.rawContent)
            .font(.system(size: 12, design: .monospaced))
            .padding(8)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
