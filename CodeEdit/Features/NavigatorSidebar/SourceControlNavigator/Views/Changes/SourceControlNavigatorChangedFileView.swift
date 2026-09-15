import SwiftUI

 struct SourceControlNavigatorChangedFileView: View {

     @State
     var changedFile: GitChangedFile

     @Binding
     var selection: GitChangedFile.ID?

     @State
     var workspaceURL: URL

     var body: some View {
         HStack {
             Image(systemName: changedFile.systemImage)
                 .frame(width: 11, height: 11)
                 .foregroundColor(selection == changedFile.id ? .white : changedFile.iconColor)

             Text(changedFile.fileName)
                 .font(.system(size: 11))
                 .foregroundColor(selection == changedFile.id ? .white : .secondary)

             Text(changedFile.changeTypeValue)
                 .font(.system(size: 11))
                 .foregroundColor(selection == changedFile.id ? .white : .secondary)
                 .frame(maxWidth: .infinity, alignment: .trailing)
         }
         .contextMenu {
             Group {
                 Button("View in Finder") {
                     changedFile.showInFinder(workspaceURL: workspaceURL)
                 }
                 Button("Reveal in Project Navigator") {
                     let fileURL = changedFile.fileURL(workspaceURL: workspaceURL)
                     NSWorkspace.shared.activateFileViewerSelecting([fileURL])
                 }
                 Divider()
             }
             Group {
                 Button("Open in New Tab") {
                     let fileURL = changedFile.fileURL(workspaceURL: workspaceURL)
                     CodeEditDocumentController.shared.openDocument(withContentsOf: fileURL, display: true) { _, _, _ in }
                 }
                 Button("Open in New Window") {
                     let fileURL = changedFile.fileURL(workspaceURL: workspaceURL)
                     CodeEditDocumentController.shared.openDocument(withContentsOf: fileURL, display: true) { _, _, _ in }
                 }
                 Button("Open with External Editor") {
                     let fileURL = changedFile.fileURL(workspaceURL: workspaceURL)
                     NSWorkspace.shared.open(fileURL)
                 }
             }
             Group {
                 Divider()
                 Button("Commit \(changedFile.fileName)...") {
                     Task {
                         _ = try? await GitPorcelainService.shared.execute(
                             repositoryURL: workspaceURL,
                             arguments: ["commit", "-m", "Update \(changedFile.fileName)"]
                         )
                     }
                 }
                 Divider()
                 Button("Discard Changes in \(changedFile.fileName)...") {
                     Task {
                         _ = try? await GitPorcelainService.shared.execute(
                             repositoryURL: workspaceURL,
                             arguments: ["checkout", "--", changedFile.fileLink.path]
                         )
                     }
                 }
                 Divider()
             }
             Group {
                 Button("Add \(changedFile.fileName)") {
                     Task {
                         _ = try? await GitPorcelainService.shared.execute(
                             repositoryURL: workspaceURL,
                             arguments: ["add", changedFile.fileLink.path]
                         )
                     }
                 }
                 Button("Mark \(changedFile.fileName) as Resolved") {
                     let fileURL = changedFile.fileURL(workspaceURL: workspaceURL)
                     GitConflictResolverWindowManager.show(fileURL: fileURL)
                 }
             }
         }
         .padding(.leading, 15)
     }
 }
