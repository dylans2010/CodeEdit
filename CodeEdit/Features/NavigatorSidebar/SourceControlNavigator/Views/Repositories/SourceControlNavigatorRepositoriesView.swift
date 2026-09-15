import SwiftUI

struct SourceControlNavigatorRepositoriesView: View {
    @EnvironmentObject
    private var workspace: WorkspaceDocument

    @State private var remoteURL: String = ""
    @State private var currentBranch: String = ""
    @State private var remotes: [String] = []
    @State private var isLoading: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            if isLoading {
                ProgressView()
                    .progressViewStyle(.circular)
                    .controlSize(.small)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if !remoteURL.isEmpty || !remotes.isEmpty {
                repoDetailsView
            } else {
                emptyConnectView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task(id: workspace.fileURL) {
            await loadRepoInfo()
        }
    }

    private var repoDetailsView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                // Header
                HStack(spacing: 8) {
                    Image(systemName: "externaldrive.connected.to.line.below")
                        .font(.system(size: 16))
                        .foregroundColor(.accentColor)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(workspace.fileURL?.lastPathComponent ?? "Repository")
                            .font(.system(size: 13, weight: .semibold))
                        if !currentBranch.isEmpty {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.triangle.branch")
                                    .font(.system(size: 10))
                                Text(currentBranch)
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.top, 12)

                Divider()

                // Remotes section
                VStack(alignment: .leading, spacing: 6) {
                    Text("REMOTES")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)

                    if !remoteURL.isEmpty {
                        VStack(alignment: .leading, spacing: 3) {
                            HStack {
                                Image(systemName: "globe")
                                    .font(.system(size: 11))
                                    .foregroundColor(.blue)
                                Text("origin")
                                    .font(.system(size: 12, weight: .medium))
                                Spacer()
                            }
                            Text(remoteURL)
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(.secondary)
                                .textSelection(.enabled)
                        }
                        .padding(8)
                        .background(Color(nsColor: .controlBackgroundColor))
                        .cornerRadius(6)
                        .padding(.horizontal, 12)
                    }

                    ForEach(remotes.filter { $0 != remoteURL }, id: \.self) { remote in
                        Text(remote)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 12)
                    }
                }

                Divider()

                // Quick actions
                VStack(spacing: 8) {
                    Button {
                        SourceControlConnectView.openConnectWindow()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "point.3.connected.trianglepath.dotted")
                            Text("Connect Remote or Clone...")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.regular)

                    Button {
                        Task { await loadRepoInfo() }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.clockwise")
                            Text("Refresh")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                .padding(.horizontal, 12)
            }
            .padding(.bottom, 16)
        }
    }

    private var emptyConnectView: some View {
        VStack(spacing: 12) {
            Spacer()

            Image(systemName: "point.3.connected.trianglepath.dotted")
                .font(.system(size: 36))
                .foregroundColor(.secondary)

            Text("Connect to Source Control")
                .font(.system(size: 13, weight: .semibold))

            Text("Connect this workspace to a remote GitHub repository or clone one from your account.")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Button {
                SourceControlConnectView.openConnectWindow()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "link.badge.plus")
                    Text("Connect to GitHub...")
                }
                .padding(.horizontal, 8)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
            .padding(.top, 4)

            Button {
                SourceControlConnectView.openConnectWindow()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.down.circle")
                    Text("Clone Repository...")
                }
            }
            .buttonStyle(.bordered)
            .controlSize(.small)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func loadRepoInfo() async {
        guard let url = workspace.fileURL else { return }
        isLoading = true
        defer { isLoading = false }

        // Get remote url
        if let out = try? await GitPorcelainService.shared.execute(
            repositoryURL: url,
            arguments: ["remote", "get-url", "origin"]
        ) {
            let trimmed = out.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty && !trimmed.contains("fatal:") {
                remoteURL = trimmed
            }
        }

        // Get current branch
        if let out = try? await GitPorcelainService.shared.execute(
            repositoryURL: url,
            arguments: ["rev-parse", "--abbrev-ref", "HEAD"]
        ) {
            let trimmed = out.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty && !trimmed.contains("fatal:") {
                currentBranch = trimmed
            }
        }

        // Get all remotes
        if let out = try? await GitPorcelainService.shared.execute(
            repositoryURL: url,
            arguments: ["remote", "-v"]
        ) {
            let lines = out.components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            remotes = Array(Set(lines)).sorted()
        }
    }
}
