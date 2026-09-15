//
//  SourceControlConnectView.swift
//  CodeEdit
//
//

// swiftlint:disable file_length type_body_length line_length identifier_name

import SwiftUI
import AppKit

// swiftlint:disable type_body_length
/// View and window manager for connecting a local project to GitHub or cloning repositories from a GitHub account.
public struct SourceControlConnectView: View {
    @ObservedObject private var prefs = AppPreferencesModel.shared
    @State private var selectedTab: Int = 0 // 0: Connect Project, 1: Clone from Account

    // MARK: - Connect Project State
    @State private var remoteName: String = "origin"
    @State private var remoteURL: String = ""
    @State private var isConnecting: Bool = false
    @State private var connectStatusMessage: String?
    @State private var connectStatusSuccess: Bool = true

    // MARK: - Clone Account State
    @State private var selectedAccountIndex: Int = 0
    @State private var customUsername: String = ""
    @State private var customToken: String = ""
    @State private var repositories: [GitHubRepoItem] = []
    @State private var repoSearchText: String = ""
    @State private var selectedRepo: GitHubRepoItem?
    @State private var isFetchingRepos: Bool = false
    @State private var isCloning: Bool = false
    @State private var cloneErrorMessage: String?
    @State private var customCloneURL: String = ""

    public init() {}

    private var activeWorkspaceURL: URL? {
        CodeEditDocumentController.shared.documents
            .compactMap { $0 as? WorkspaceDocument }
            .first?
            .fileURL
    }

    private var filteredRepos: [GitHubRepoItem] {
        if repoSearchText.isEmpty {
            return repositories
        }
        return repositories.filter {
            $0.name.localizedCaseInsensitiveContains(repoSearchText) ||
            ($0.description ?? "").localizedCaseInsensitiveContains(repoSearchText)
        }
    }

    public var body: some View {
        VStack(spacing: 0) {
            headerBar
            Divider()

            Picker("", selection: $selectedTab) {
                Text("Connect Current Project").tag(0)
                Text("Clone from GitHub").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)

            Divider()

            if selectedTab == 0 {
                connectProjectView
            } else {
                cloneFromAccountView
            }
        }
        .frame(width: 620, height: 480)
        .background(Color(NSColor.windowBackgroundColor))
        .task {
            await loadAccountRepos()
        }
    }

    // MARK: - Header Bar

    private var headerBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "point.3.connected.trianglepath.dotted")
                .font(.system(size: 20))
                .foregroundColor(.accentColor)

            VStack(alignment: .leading, spacing: 2) {
                Text("Connect to GitHub")
                    .font(.system(size: 15, weight: .bold))
                Text("Link your local repository to a remote or clone from your account.")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    // MARK: - Tab 1: Connect Project

    private var connectProjectView: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let workspaceURL = activeWorkspaceURL {
                VStack(alignment: .leading, spacing: 4) {
                    Text("ACTIVE WORKSPACE")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)

                    Text(workspaceURL.path)
                        .font(.system(size: 11, design: .monospaced))
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(6)
                }

                Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 12) {
                    GridRow {
                        Text("Remote Name:")
                            .font(.system(size: 12, weight: .medium))
                            .gridColumnAlignment(.trailing)
                        TextField("origin", text: $remoteName)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 140)
                    }

                    GridRow {
                        Text("GitHub Repo URL:")
                            .font(.system(size: 12, weight: .medium))
                        TextField("https://github.com/owner/repository.git", text: $remoteURL)
                            .textFieldStyle(.roundedBorder)
                    }
                }

                if let message = connectStatusMessage {
                    HStack(spacing: 8) {
                        Image(systemName: connectStatusSuccess ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                            .foregroundColor(connectStatusSuccess ? .green : .red)
                        Text(message)
                            .font(.system(size: 11))
                            .foregroundColor(connectStatusSuccess ? .primary : .red)
                    }
                    .padding(8)
                    .background((connectStatusSuccess ? Color.green : Color.red).opacity(0.1))
                    .cornerRadius(6)
                }

                Spacer()

                HStack {
                    Spacer()
                    if isConnecting {
                        ProgressView()
                            .scaleEffect(0.7)
                    }
                    Button("Connect & Push") {
                        connectLocalProject()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(remoteURL.trimmingCharacters(in: .whitespaces).isEmpty || isConnecting)
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "folder.badge.questionmark")
                        .font(.system(size: 36))
                        .foregroundColor(.secondary)
                    Text("No Active Project Open")
                        .font(.headline)
                    Text("Open a workspace or project in CodeEdit to connect it to a GitHub repository.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding(20)
    }

    private func connectLocalProject() {
        guard let workspaceURL = activeWorkspaceURL else { return }
        isConnecting = true
        connectStatusMessage = nil

        let targetRemote = remoteName.trimmingCharacters(in: .whitespaces).isEmpty ? "origin" : remoteName
        let cleanURL = remoteURL.trimmingCharacters(in: .whitespaces)

        Task {
            do {
                // Initialize git if needed
                let dotGit = workspaceURL.appendingPathComponent(".git")
                if !FileManager.default.fileExists(atPath: dotGit.path) {
                    _ = try await GitPorcelainService.shared.execute(repositoryURL: workspaceURL, arguments: ["init"])
                }

                // Check existing remotes
                let existingRemotes = try await GitPorcelainService.shared.execute(repositoryURL: workspaceURL, arguments: ["remote"])
                if existingRemotes.components(separatedBy: .newlines).contains(targetRemote) {
                    _ = try await GitPorcelainService.shared.execute(repositoryURL: workspaceURL, arguments: ["remote", "set-url", targetRemote, cleanURL])
                } else {
                    _ = try await GitPorcelainService.shared.execute(repositoryURL: workspaceURL, arguments: ["remote", "add", targetRemote, cleanURL])
                }

                // Push initial commit if any branch exists
                let branchRes = try? await GitPorcelainService.shared.execute(repositoryURL: workspaceURL, arguments: ["branch", "--show-current"])
                let currentBranch = branchRes?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "main"
                _ = try? await GitPorcelainService.shared.execute(repositoryURL: workspaceURL, arguments: ["push", "-u", targetRemote, currentBranch])

                await MainActor.run {
                    self.isConnecting = false
                    self.connectStatusSuccess = true
                    self.connectStatusMessage = "Successfully connected '\(targetRemote)' to \(cleanURL)"
                }
            } catch {
                await MainActor.run {
                    self.isConnecting = false
                    self.connectStatusSuccess = false
                    self.connectStatusMessage = "Failed to configure remote: \(error.localizedDescription)"
                }
            }
        }
    }

    // MARK: - Tab 2: Clone from Account

    private var cloneFromAccountView: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .font(.system(size: 11))
                TextField("Search repositories or enter custom URL...", text: $repoSearchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                if !repoSearchText.isEmpty {
                    Button {
                        repoSearchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.system(size: 11))
                    }
                    .buttonStyle(.plain)
                }
                Button {
                    Task { await loadAccountRepos() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 11))
                }
                .buttonStyle(.plain)
                .help("Refresh repositories")
            }
            .padding(6)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(6)

            if isFetchingRepos {
                VStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Fetching GitHub repositories...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if filteredRepos.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "tray")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)
                    Text("No Repositories Discovered")
                        .font(.headline)
                    Text("Enter a repository URL below or sign into your GitHub account in Preferences -> Accounts.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)

                    HStack {
                        TextField("https://github.com/owner/repo.git", text: $customCloneURL)
                            .textFieldStyle(.roundedBorder)
                        Button("Clone") {
                            cloneRepo(url: customCloneURL)
                        }
                        .disabled(customCloneURL.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(filteredRepos, selection: $selectedRepo) { repo in
                    HStack(spacing: 10) {
                        Image(systemName: repo.isPrivate ? "lock.fill" : "book.closed.fill")
                            .foregroundColor(repo.isPrivate ? .orange : .accentColor)
                            .font(.system(size: 13))

                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text(repo.fullName)
                                    .font(.system(size: 12, weight: .semibold))
                                if let stars = repo.stargazersCount, stars > 0 {
                                    HStack(spacing: 2) {
                                        Image(systemName: "star.fill")
                                            .font(.system(size: 9))
                                            .foregroundColor(.yellow)
                                        Text("\(stars)")
                                            .font(.system(size: 9))
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            if let desc = repo.description, !desc.isEmpty {
                                Text(desc)
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                        }
                        Spacer()
                        Button("Clone") {
                            cloneRepo(url: repo.cloneURL)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    .padding(.vertical, 3)
                }
                .listStyle(.sidebar)
            }

            if let error = cloneErrorMessage {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text(error)
                        .font(.system(size: 11))
                        .foregroundColor(.red)
                }
                .padding(6)
                .background(Color.red.opacity(0.1))
                .cornerRadius(6)
            }
        }
        .padding(16)
    }

    private func loadAccountRepos() async {
        isFetchingRepos = true
        cloneErrorMessage = nil

        let gitAccounts = prefs.preferences.accounts.sourceControlAccounts.gitAccount.filter {
            $0.gitProvider.lowercased().contains("github")
        }

        var loaded: [GitHubRepoItem] = []
        for account in gitAccounts {
            let token = EditorKeychainManager.shared.get(forKey: "github_\(account.id)") ??
                EditorKeychainManager.shared.get(forKey: "github_personal_access_token")
            if let repos = try? await GitHubAPIService.shared.listUserRepositories(token: token, username: account.gitAccountName) {
                loaded.append(contentsOf: repos)
            }
        }

        // Also attempt unauthenticated/generic token fetch if nothing found
        if loaded.isEmpty {
            if let generalRepos = try? await GitHubAPIService.shared.listUserRepositories() {
                loaded.append(contentsOf: generalRepos)
            }
        }

        await MainActor.run {
            self.repositories = loaded
            self.isFetchingRepos = false
        }
    }

    private func cloneRepo(url: String) {
        let trimmed = url.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let repoName = (trimmed as NSString).lastPathComponent.replacingOccurrences(of: ".git", with: "")
        let panel = NSSavePanel()
        panel.title = "Clone Repository"
        panel.prompt = "Clone"
        panel.nameFieldStringValue = repoName
        panel.canCreateDirectories = true
        panel.showsTagField = false

        guard panel.runModal() == .OK, let targetURL = panel.url else {
            return
        }

        isCloning = true
        cloneErrorMessage = nil

        Task {
            let parentDir = targetURL.deletingLastPathComponent()
            let cloneCmd = "git clone \"\(trimmed)\" \"\(targetURL.path)\""
            let runResult = try? await CommandRunner.execute(command: cloneCmd, in: parentDir)

            await MainActor.run {
                self.isCloning = false
                if runResult?.exitCode == 0 {
                    // Open newly cloned project in CodeEdit
                    CodeEditDocumentController.shared.reopenDocument(
                        for: targetURL,
                        withContentsOf: targetURL,
                        display: true
                    ) { _, _, _ in }

                    // Close connect window
                    NSApp.keyWindow?.close()
                } else {
                    self.cloneErrorMessage = runResult?.output ?? "Failed to clone repository."
                }
            }
        }
    }

    // MARK: - Window Presentation

    /// Opens the Source Control Connect window.
    public static func openConnectWindow() {
        if let existing = NSApp.windows.first(where: { $0.title == "Connect to GitHub" }) {
            existing.makeKeyAndOrderFront(nil)
            return
        }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 620, height: 480),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = "Connect to GitHub"
        window.contentView = NSHostingView(rootView: SourceControlConnectView())
        window.makeKeyAndOrderFront(nil)
    }
}
