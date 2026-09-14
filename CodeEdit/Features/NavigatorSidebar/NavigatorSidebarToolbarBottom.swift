import SwiftUI

struct NavigatorSidebarToolbarBottom: View {
    @Environment(\.controlActiveState)
    private var activeState

    @EnvironmentObject
    var workspace: WorkspaceDocument

    var body: some View {
        HStack(spacing: 10) {
            addNewFileButton
            Spacer()
            sortButton
        }
        .frame(height: 29, alignment: .center)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 4)
        .overlay(alignment: .top) {
            Divider()
        }
    }

    private var targetDirectoryItem: WorkspaceClient.FileItem? {
        if case let .codeEditor(id) = workspace.selectionState.selectedId,
           let currentItem = try? workspace.workspaceClient?.getFileItem(id) {
            return currentItem.isFolder ? currentItem : currentItem.parent
        }
        guard let folderURL = workspace.workspaceClient?.folderURL() else { return nil }
        return try? workspace.workspaceClient?.getFileItem(folderURL.path)
    }

    private var addNewFileButton: some View {
        Menu {
            Button {
                guard let target = targetDirectoryItem else { return }
                target.addFile(fileName: "untitled")
            } label: {
                Label("New File", systemImage: "doc.badge.plus")
            }

            Button {
                guard let target = targetDirectoryItem else { return }
                target.addFolder(folderName: "untitled")
            } label: {
                Label("New Folder", systemImage: "folder.badge.plus")
            }

            Divider()

            Button {
                guard let target = targetDirectoryItem else { return }
                let panel = NSOpenPanel()
                panel.allowsMultipleSelection = true
                panel.canChooseDirectories = false
                panel.canChooseFiles = true
                panel.prompt = "Add"
                if panel.runModal() == .OK {
                    target.importFiles(from: panel.urls)
                }
            } label: {
                Label("Add File...", systemImage: "square.and.arrow.down")
            }

            Button {
                guard let target = targetDirectoryItem else { return }
                let panel = NSOpenPanel()
                panel.allowsMultipleSelection = false
                panel.canChooseDirectories = true
                panel.canChooseFiles = false
                panel.prompt = "Add"
                if panel.runModal() == .OK, let folder = panel.url {
                    target.importFolder(from: folder)
                }
            } label: {
                Label("Add Folder...", systemImage: "folder")
            }
        } label: {
            Image(systemName: "plus")
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .frame(maxWidth: 30)
        .opacity(activeState == .inactive ? 0.45 : 1)
    }

    private var sortButton: some View {
        Menu {
            Button {
                workspace.sortFoldersOnTop.toggle()
            } label: {
                Text(workspace.sortFoldersOnTop ? "Alphabetically" : "Folders on top")
            }
        } label: {
            Image(systemName: "line.3.horizontal.decrease.circle")
        }
        .menuStyle(.borderlessButton)
        .frame(maxWidth: 30)
        .opacity(activeState == .inactive ? 0.45 : 1)
    }
}
