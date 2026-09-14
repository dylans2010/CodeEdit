import SwiftUI
import UniformTypeIdentifiers

struct WorkspaceCodeFileView: View {
    @EnvironmentObject
    private var workspace: WorkspaceDocument

    @StateObject
    private var prefs: AppPreferencesModel = .shared

    @ViewBuilder
    var codeView: some View {
        ZStack {
            if let item = workspace.selectionState.openFileItems.first(where: { file in
                if file.tabID == workspace.selectionState.selectedId {
                    print("Item loaded is: ", file.url)
                }
                return file.tabID == workspace.selectionState.selectedId
            }) {
                if let fileItem = workspace.selectionState.openedCodeFiles[item] {
                    if isXcodeProject(item.url) {
                        xcodeProjectView(for: item)
                    } else if isPropertyList(item.url) {
                        propertyListView(fileItem, for: item)
                    } else if fileItem.typeOfFile == .text || fileItem.typeOfFile == .data {
                        codeFileView(fileItem, for: item)
                    } else {
                        otherFileView(fileItem, for: item)
                    }
                }
            } else {
                Text("No Editor")
                    .font(.system(size: 17))
                    .foregroundColor(.secondary)
                    .frame(minHeight: 0)
                    .clipped()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func isXcodeProject(_ url: URL) -> Bool {
        url.pathExtension == "xcodeproj" || url.lastPathComponent == "project.pbxproj"
    }

    private func isPropertyList(_ url: URL) -> Bool {
        url.pathExtension == "plist" || url.pathExtension == "entitlements"
    }

    @ViewBuilder
    private func xcodeProjectView(for item: WorkspaceClient.FileItem) -> some View {
        VStack(spacing: 0) {
            BreadcrumbsView(file: item, tappedOpenFile: workspace.openTab(item:))
            Divider()
            XcodeProjectEditorView(projectURL: item.url)
        }
    }

    @ViewBuilder
    private func propertyListView(
        _ codeFile: CodeFileDocument,
        for item: WorkspaceClient.FileItem
    ) -> some View {
        VStack(spacing: 0) {
            BreadcrumbsView(file: item, tappedOpenFile: workspace.openTab(item:))
            Divider()
            PropertyListEditorView(codeFile: codeFile, fileURL: item.url)
        }
    }

    @ViewBuilder
    private func codeFileView(
        _ codeFile: CodeFileDocument,
        for item: WorkspaceClient.FileItem
    ) -> some View {
        VStack(spacing: 0) {
            BreadcrumbsView(file: item, tappedOpenFile: workspace.openTab(item:))
            Divider()
            CodeFileView(codeFile: codeFile)
        }
    }

    @ViewBuilder
    private func otherFileView(
        _ otherFile: CodeFileDocument,
        for item: WorkspaceClient.FileItem
    ) -> some View {
        VStack(spacing: 0) {
            BreadcrumbsView(file: item, tappedOpenFile: workspace.openTab(item:))
            Divider()

            if let url = otherFile.previewItemURL,
               let image = NSImage(contentsOf: url),
               otherFile.typeOfFile == .image {
                GeometryReader { proxy in
                    if image.size.width > proxy.size.width || image.size.height > proxy.size.height {
                        OtherFileView(otherFile)
                    } else {
                        OtherFileView(otherFile)
                            .frame(width: image.size.width, height: image.size.height)
                            .position(x: proxy.frame(in: .local).midX, y: proxy.frame(in: .local).midY)
                    }
                }
            } else {
                OtherFileView(otherFile)
            }
        }
    }

    var body: some View {
        codeView
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onHover { hover in
                DispatchQueue.main.async {
                    if hover {
                        NSCursor.iBeam.push()
                    } else {
                        NSCursor.pop()
                    }
                }
            }
    }
}
