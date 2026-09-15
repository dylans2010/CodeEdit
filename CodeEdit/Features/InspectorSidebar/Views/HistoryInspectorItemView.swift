import SwiftUI

struct HistoryInspectorItemView: View {

    var commit: GitCommit

    @Binding var selection: GitCommit?

    private var showPopup: Binding<Bool> {
        Binding<Bool> {
            selection == commit
        } set: { newValue in
            if newValue {
                selection = commit
            } else {
                selection = nil
            }
        }
    }

    @Environment(\.openURL) private var openCommit

    init(commit: GitCommit, selection: Binding<GitCommit?>) {
        self.commit = commit
        self._selection = selection
    }

    var body: some View {
        VStack(alignment: .trailing) {
            HStack(alignment: .top) {
                VStack(alignment: .leading) {
                    Text(commit.author)
                        .fontWeight(.bold)
                        .font(.system(size: 11))
                    Text(commit.message)
                        .font(.system(size: 11))
                        .lineLimit(2)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 5) {
                    Text(commit.hash)
                        .font(.system(size: 10))
                        .background(
                            RoundedRectangle(cornerRadius: 3)
                                .padding(.trailing, -5)
                                .padding(.leading, -5)
                                .foregroundColor(Color(nsColor: .quaternaryLabelColor))
                        )
                        .padding(.trailing, 5)
                    Text(commit.date.relativeStringToNow())
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .padding(.top, 1)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .contentShape(Rectangle())
        .popover(isPresented: showPopup, arrowEdge: .leading) {
            HistoryPopoverView(commit: commit)
        }
        .contextMenu {
            Group {
                Button("Copy Commit Message") {
                    let pasteboard = NSPasteboard.general
                    pasteboard.clearContents()
                    pasteboard.setString(commit.message, forType: .string)
                }
                Button("Copy Identifier") {
                    let pasteboard = NSPasteboard.general
                    pasteboard.clearContents()
                    pasteboard.setString(commit.commitHash, forType: .string)
                }
                Button("Email \(commit.author)...") {
                    let service = NSSharingService(named: NSSharingService.Name.composeEmail)
                    service?.recipients = [commit.authorEmail]
                    service?.perform(withItems: [])
                }
                Divider()
            }
            Group {
                Button("Tag \(commit.hash)...") {
                    Task {
                        _ = try? await GitPorcelainService.shared.runGit(
                            arguments: ["tag", "v_\(commit.hash.prefix(7))", commit.commitHash]
                        )
                    }
                }
                Button("New Branch from \(commit.hash)...") {
                    Task {
                        _ = try? await GitPorcelainService.shared.runGit(
                            arguments: ["checkout", "-b", "branch-\(commit.hash.prefix(7))", commit.commitHash]
                        )
                    }
                }
                Button("Cherry-Pick \(commit.hash)...") {
                    Task {
                        _ = try? await GitPorcelainService.shared.runGit(
                            arguments: ["cherry-pick", commit.commitHash]
                        )
                    }
                }
            }
            Group {
                Divider()
                if let commitRemoteURL = commit.commitBaseURL?.absoluteString {
                    Button("View on \(commit.remoteString)...") {
                        let commitURL = "\(commitRemoteURL)/\(commit.commitHash)"
                        openCommit(URL(string: commitURL)!)
                    }
                    Divider()
                }
                Button("Check Out \(commit.hash)...") {
                    Task {
                        _ = try? await GitPorcelainService.shared.runGit(
                            arguments: ["checkout", commit.commitHash]
                        )
                    }
                }
                Divider()
                Button("History Editor Help") {
                    PersonalDocWindowManager.show()
                }
            }
        }
    }
}
