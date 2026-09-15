import SwiftUI

struct SourceControlToolbarBottom: View {
    var body: some View {
        HStack(spacing: 0) {
            sourceControlMenu
            SourceControlSearchToolbar()
        }
        .frame(height: 29, alignment: .center)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 4)
        .overlay(alignment: .top) {
            Divider()
        }
    }

    private var sourceControlMenu: some View {
        Menu {
            Button("Discard All Changes...") {
                if let workspaceDoc = CodeEditDocumentController.shared.documents.compactMap({ $0 as? WorkspaceDocument }).first,
                   let repoURL = workspaceDoc.fileURL {
                    Task {
                        _ = try? await GitPorcelainService.shared.execute(repositoryURL: repoURL, arguments: ["checkout", "--", "."])
                    }
                }
            }
            Button("Stash Changes...") {
                if let workspaceDoc = CodeEditDocumentController.shared.documents.compactMap({ $0 as? WorkspaceDocument }).first,
                   let repoURL = workspaceDoc.fileURL {
                    Task {
                        _ = try? await GitPorcelainService.shared.execute(repositoryURL: repoURL, arguments: ["stash"])
                    }
                }
            }
            Button("Commit...") {
                if let workspaceDoc = CodeEditDocumentController.shared.documents.compactMap({ $0 as? WorkspaceDocument }).first,
                   let repoURL = workspaceDoc.fileURL {
                    Task {
                        _ = try? await GitPorcelainService.shared.execute(repositoryURL: repoURL, arguments: ["commit", "-m", "Commit changes"])
                    }
                }
            }
            Button("Inspect History & Conflicts...") {
                SourceControlWindowManager.show()
            }
        } label: {
            Image(systemName: "ellipsis.circle")
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .frame(maxWidth: 30)
    }
}
