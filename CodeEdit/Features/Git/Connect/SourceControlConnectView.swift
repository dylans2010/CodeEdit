//
//  SourceControlConnectView.swift
//  CodeEdit
//
//

// swiftlint:disable file_length type_body_length line_length function_body_length

import SwiftUI
import AppKit

/// A clean, native macOS view and window controller for connecting workspaces to GitHub,
/// managing Personal Access Tokens, creating repositories, pushing local changes, and orchestrating Git remotes.
public struct SourceControlConnectView: View {
    @ObservedObject private var prefs = AppPreferencesModel.shared

    // MARK: - Token & Auth State
    @State private var tokenInput: String = ""
    @State private var isTokenVisible: Bool = false
    @State private var authenticatedUser: GitHubUserProfile?
    @State private var isAuthenticating: Bool = false
    @State private var authErrorMessage: String?
    @State private var authSuccessMessage: String?
    @State private var showTokenConfig: Bool = false

    // MARK: - Create Repo & Push State
    @State private var newRepoName: String = ""
    @State private var newRepoDescription: String = ""
    @State private var newRepoIsPrivate: Bool = true
    @State private var isCreatingAndPushing: Bool = false
    @State private var createPushStatus: String?
    @State private var createPushSuccessMessage: String?
    @State private var createPushErrorMessage: String?
    @State private var createdRepoURL: String?

    // MARK: - Workspace & Git State
    @State private var currentRemoteURL: String = ""
    @State private var currentBranch: String = ""
    @State private var customRemoteURL: String = ""
    @State private var isPerformingGitAction: Bool = false
    @State private var gitActionStatus: String?
    @State private var commitMessageText: String = ""
    @State private var showCommitSheet: Bool = false

    // MARK: - Repository Browser State
    @State private var repositories: [GitHubRepoItem] = []
    @State private var isFetchingRepos: Bool = false
    @State private var repoSearchText: String = ""
    @State private var repoActionMessage: String?
    @State private var showBrowseRepos: Bool = false

    public init() {}

    private var activeWorkspaceURL: URL? {
        CodeEditDocumentController.shared.documents
            .compactMap { $0 as? WorkspaceDocument }
            .first?
            .fileURL
    }

    private var activeToken: String? {
        if !tokenInput.isEmpty {
            return tokenInput
        }
        return EditorKeychainManager.shared.get(forKey: "github_personal_access_token")
    }

    public var body: some View {
        VStack(spacing: 0) {
            topHeaderBar
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Account & Token Status (if token not set or expanded)
                    if showTokenConfig || authenticatedUser == nil {
                        tokenConfigCard
                    }

                    // Success or Status Feedback
                    if let success = createPushSuccessMessage {
                        successFeedbackBanner(message: success, linkURL: createdRepoURL)
                    }

                    if let status = gitActionStatus {
                        statusFeedbackBanner(message: status)
                    }

                    if let err = createPushErrorMessage {
                        errorFeedbackBanner(message: err)
                    }

                    // Connected Repository Status (if remote origin is configured)
                    if !currentRemoteURL.isEmpty {
                        connectedRepositoryCard
                        sourceControlQuickActionsSection
                    }

                    // Create New GitHub Repository & Push (Primary Feature)
                    createRepositoryAndPushSection

                    // Manual Remote or Browse Existing
                    additionalOptionsSection
                }
                .padding(20)
            }
        }
        .frame(width: 720, height: 600)
        .background(Color(NSColor.windowBackgroundColor))
        .sheet(isPresented: $showCommitSheet) {
            commitDialogSheet
        }
        .task {
            await initializeViewState()
        }
    }

    // MARK: - Header Bar (Clean Native Style, No Gradients)

    private var topHeaderBar: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.accentColor.opacity(0.15))
                    .frame(width: 36, height: 36)

                Image(systemName: "point.3.connected.trianglepath.dotted")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.accentColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text("GitHub Source Control")
                        .font(.system(size: 15, weight: .bold))
                    if authenticatedUser != nil {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 13))
                    }
                }

                Text("Manage remotes, create repositories, and push local workspace changes.")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            Spacer()

            if let user = authenticatedUser {
                HStack(spacing: 7) {
                    Image(systemName: "person.crop.circle.badge.checkmark")
                        .font(.system(size: 14))
                        .foregroundColor(.green)

                    Text("@\(user.login)")
                        .font(.system(size: 12, weight: .semibold))

                    Button(showTokenConfig ? "Done" : "Token") {
                        showTokenConfig.toggle()
                    }
                    .buttonStyle(.borderless)
                    .font(.system(size: 11))
                    .foregroundColor(.accentColor)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color(NSColor.controlBackgroundColor))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color.secondary.opacity(0.2), lineWidth: 0.8))
            } else {
                Button {
                    showTokenConfig.toggle()
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "key.horizontal.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.orange)
                        Text(showTokenConfig ? "Hide Token" : "Configure Token")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color(NSColor.controlBackgroundColor))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.secondary.opacity(0.2), lineWidth: 0.8))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Create New Repository & Push Section (No Gradients)

    private var createRepositoryAndPushSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.green.opacity(0.15))
                        .frame(width: 26, height: 26)
                    Image(systemName: "arrow.up.circle.fill")
                        .foregroundColor(.green)
                        .font(.system(size: 14))
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text("CREATE GITHUB REPOSITORY & PUSH LOCAL CHANGES")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.secondary)
                    Text("Creates a new repository on your GitHub account, configures origin, and pushes all local commits.")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                Spacer()
            }

            VStack(spacing: 10) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Repository Name")
                            .font(.system(size: 11, weight: .medium))
                        TextField("my-project", text: $newRepoName)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 12, design: .monospaced))
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Visibility")
                            .font(.system(size: 11, weight: .medium))
                        Picker("", selection: $newRepoIsPrivate) {
                            Text("Private (Recommended)").tag(true)
                            Text("Public").tag(false)
                        }
                        .pickerStyle(.segmented)
                    }
                    .frame(width: 200)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Description (Optional)")
                        .font(.system(size: 11, weight: .medium))
                    TextField("Project created with CodeEdit", text: $newRepoDescription)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 12))
                }

                HStack {
                    if let status = createPushStatus {
                        HStack(spacing: 6) {
                            ProgressView().controlSize(.small)
                            Text(status)
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    Button {
                        Task { await createRepoAndPushLocalChanges() }
                    } label: {
                        HStack(spacing: 6) {
                            if isCreatingAndPushing {
                                ProgressView().controlSize(.small)
                            } else {
                                Image(systemName: "arrow.triangle.push")
                            }
                            Text("Create Repository & Push")
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(newRepoName.trimmingCharacters(in: .whitespaces).isEmpty || isCreatingAndPushing || activeToken == nil)
                }
                .padding(.top, 4)
            }
        }
        .padding(16)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.6))
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.secondary.opacity(0.2), lineWidth: 0.8))
    }

    // MARK: - Connected Repository Card (No Gradients)

    private var connectedRepositoryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.15))
                        .frame(width: 30, height: 30)
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.green)
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text("Remote Origin Active")
                        .font(.system(size: 13, weight: .bold))
                    Text(currentRemoteURL)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.secondary)
                        .textSelection(.enabled)
                }

                Spacer()

                if let url = URL(string: currentRemoteURL.replacingOccurrences(of: ".git", with: "")) {
                    Button {
                        NSWorkspace.shared.open(url)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "safari.fill")
                            Text("Open on GitHub")
                        }
                        .font(.system(size: 11))
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }

            Divider().opacity(0.3)

            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.triangle.branch")
                        .foregroundColor(.purple)
                        .font(.system(size: 11))
                    Text("Branch: \(currentBranch.isEmpty ? "main" : currentBranch)")
                        .font(.system(size: 11, weight: .semibold))
                }

                if let ws = activeWorkspaceURL {
                    HStack(spacing: 4) {
                        Image(systemName: "folder.fill")
                            .foregroundColor(.orange)
                            .font(.system(size: 11))
                        Text(ws.path)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }
        }
        .padding(14)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.7))
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.green.opacity(0.3), lineWidth: 0.8))
    }

    // MARK: - Quick Actions Section

    private var sourceControlQuickActionsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("SOURCE CONTROL ACTIONS")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.secondary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                actionCard(
                    title: "Commit Changes...",
                    subtitle: "Stage files and create a new local Git commit.",
                    icon: "plus.circle.fill",
                    color: .green
                ) {
                    showCommitSheet = true
                }

                actionCard(
                    title: "Push to Origin",
                    subtitle: "Publish local commits to the remote GitHub repository.",
                    icon: "arrow.triangle.push",
                    color: .blue
                ) {
                    await runGitPush()
                }

                actionCard(
                    title: "Pull from Origin",
                    subtitle: "Fetch and integrate changes from the remote branch.",
                    icon: "arrow.triangle.pull",
                    color: .purple
                ) {
                    await runGitPull()
                }

                actionCard(
                    title: "Refresh Git Status",
                    subtitle: "Re-query local working tree and remote configuration.",
                    icon: "arrow.clockwise",
                    color: .indigo
                ) {
                    await reloadWorkspaceGitInfo()
                }
            }

            HStack {
                Button(role: .destructive) {
                    Task { await disconnectRemote() }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "link.badge.plus")
                        Text("Disconnect Remote Origin")
                    }
                    .font(.system(size: 10))
                }
                .buttonStyle(.borderless)
                .foregroundColor(.secondary)

                Spacer()
            }
            .padding(.top, 2)
        }
    }

    private func actionCard(title: String, subtitle: String, icon: String, color: Color, action: @escaping () async -> Void) -> some View {
        Button {
            Task { await action() }
        } label: {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(color.opacity(0.15))
                        .frame(width: 28, height: 28)
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundColor(color)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.primary)
                    Text(subtitle)
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)
            }
            .padding(10)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.15), lineWidth: 0.8))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Additional Options (Manual URL & Browse)

    private var additionalOptionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            DisclosureGroup("Link Existing Git Remote or Browse Repositories") {
                VStack(alignment: .leading, spacing: 14) {
                    // Manual Connect
                    VStack(alignment: .leading, spacing: 6) {
                        Text("CONNECT VIA GIT URL")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary)

                        HStack(spacing: 8) {
                            TextField("https://github.com/user/repo.git", text: $customRemoteURL)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(size: 11, design: .monospaced))

                            Button("Connect") {
                                Task { await connectManualURL() }
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .disabled(customRemoteURL.trimmingCharacters(in: .whitespaces).isEmpty || isPerformingGitAction)
                        }
                    }

                    Divider().opacity(0.3)

                    // Browse user repositories
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("YOUR GITHUB REPOSITORIES")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.secondary)
                            Spacer()
                            Button {
                                Task { await fetchRepositories() }
                            } label: {
                                HStack(spacing: 4) {
                                    if isFetchingRepos {
                                        ProgressView().controlSize(.small)
                                    } else {
                                        Image(systemName: "arrow.clockwise")
                                    }
                                    Text("Fetch Repos")
                                }
                                .font(.system(size: 10))
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.mini)
                            .disabled(activeToken == nil || isFetchingRepos)
                        }

                        if !repositories.isEmpty {
                            VStack(spacing: 6) {
                                ForEach(repositories.prefix(5)) { repo in
                                    HStack {
                                        Image(systemName: repo.isPrivate ? "lock.fill" : "globe")
                                            .font(.system(size: 11))
                                            .foregroundColor(.secondary)
                                        Text(repo.fullName)
                                            .font(.system(size: 11, weight: .medium))
                                        Spacer()
                                        Button("Connect") {
                                            Task { await connectWorkspaceToRepo(repo) }
                                        }
                                        .buttonStyle(.bordered)
                                        .controlSize(.mini)
                                    }
                                    .padding(6)
                                    .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                                    .cornerRadius(6)
                                }
                            }
                        } else {
                            Text("Click 'Fetch Repos' to list repositories from your GitHub account.")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.top, 8)
            }
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(.secondary)
        }
        .padding(14)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.4))
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.secondary.opacity(0.15), lineWidth: 0.8))
    }

    // MARK: - Token Configuration Card

    private var tokenConfigCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "key.horizontal.fill")
                    .foregroundColor(.orange)
                    .font(.system(size: 13))
                Text("GitHub Personal Access Token")
                    .font(.system(size: 12, weight: .bold))
                Spacer()
                if authenticatedUser != nil {
                    Button("Close") {
                        showTokenConfig = false
                    }
                    .buttonStyle(.borderless)
                    .font(.system(size: 11))
                }
            }

            Text("Enter a GitHub Personal Access Token (classic or fine-grained) with 'repo' scope.")
                .font(.system(size: 11))
                .foregroundColor(.secondary)

            HStack(spacing: 8) {
                if isTokenVisible {
                    TextField("ghp_...", text: $tokenInput)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 11, design: .monospaced))
                } else {
                    SecureField("ghp_...", text: $tokenInput)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 11, design: .monospaced))
                }

                Button {
                    isTokenVisible.toggle()
                } label: {
                    Image(systemName: isTokenVisible ? "eye.slash" : "eye")
                        .font(.system(size: 11))
                }
                .buttonStyle(.borderless)

                Button {
                    Task { await authenticateWithToken(tokenInput, silent: false) }
                } label: {
                    HStack(spacing: 4) {
                        if isAuthenticating {
                            ProgressView().controlSize(.small)
                        }
                        Text("Connect")
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(tokenInput.trimmingCharacters(in: .whitespaces).isEmpty || isAuthenticating)
            }

            if let err = authErrorMessage {
                Text(err)
                    .font(.system(size: 10))
                    .foregroundColor(.red)
            }

            if let success = authSuccessMessage {
                Text(success)
                    .font(.system(size: 10))
                    .foregroundColor(.green)
            }
        }
        .padding(14)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.8))
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.secondary.opacity(0.2), lineWidth: 0.8))
    }

    // MARK: - Feedback Banners

    private func successFeedbackBanner(message: String, linkURL: String?) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            Text(message)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.primary)

            if let link = linkURL, let url = URL(string: link) {
                Spacer()
                Button("Open on GitHub ↗") {
                    NSWorkspace.shared.open(url)
                }
                .buttonStyle(.borderless)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.accentColor)
            }
        }
        .padding(10)
        .background(Color.green.opacity(0.12))
        .cornerRadius(8)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.green.opacity(0.3), lineWidth: 0.8))
    }

    private func statusFeedbackBanner(message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "info.circle.fill")
                .foregroundColor(.blue)
            Text(message)
                .font(.system(size: 11))
                .foregroundColor(.primary)
            Spacer()
        }
        .padding(10)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(8)
    }

    private func errorFeedbackBanner(message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
            Text(message)
                .font(.system(size: 11))
                .foregroundColor(.red)
            Spacer()
        }
        .padding(10)
        .background(Color.red.opacity(0.1))
        .cornerRadius(8)
    }

    // MARK: - Commit Sheet

    private var commitDialogSheet: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.green)
                    .font(.system(size: 16))
                Text("Commit Changes to Repository")
                    .font(.system(size: 14, weight: .bold))
                Spacer()
                Button("Cancel") { showCommitSheet = false }
                    .buttonStyle(.borderless)
            }

            Text("Enter a commit message to record your local modifications:")
                .font(.system(size: 11))
                .foregroundColor(.secondary)

            TextEditor(text: $commitMessageText)
                .font(.system(size: 12, design: .monospaced))
                .frame(height: 90)
                .padding(4)
                .background(Color(NSColor.textBackgroundColor))
                .cornerRadius(6)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.secondary.opacity(0.2), lineWidth: 1))

            HStack {
                Spacer()
                Button("Commit") {
                    let msg = commitMessageText
                    showCommitSheet = false
                    commitMessageText = ""
                    Task { await performCommit(message: msg) }
                }
                .buttonStyle(.borderedProminent)
                .disabled(commitMessageText.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(20)
        .frame(width: 440)
    }

    // MARK: - Window Management

    public static func openConnectWindow() {
        if let window = NSApp.windows.first(where: {
            ($0.contentView as? NSHostingView<SourceControlConnectView>) != nil
        }) {
            window.makeKeyAndOrderFront(nil)
            return
        }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 720, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = "GitHub Source Control"
        window.contentView = NSHostingView(rootView: SourceControlConnectView())
        window.makeKeyAndOrderFront(nil)
    }

    // MARK: - Business Logic & Git Operations

    func initializeViewState() async {
        if let folderName = activeWorkspaceURL?.lastPathComponent {
            newRepoName = folderName
        }
        if let savedToken = EditorKeychainManager.shared.get(forKey: "github_personal_access_token"), !savedToken.isEmpty {
            tokenInput = savedToken
            await authenticateWithToken(savedToken, silent: true)
        }
        await reloadWorkspaceGitInfo()
    }

    func authenticateWithToken(_ token: String, silent: Bool) async {
        isAuthenticating = true
        authErrorMessage = nil
        authSuccessMessage = nil

        do {
            let profile = try await GitHubAPIService.shared.validateTokenAndGetUser(token: token)
            await MainActor.run {
                self.authenticatedUser = profile
                self.isAuthenticating = false
                EditorKeychainManager.shared.set(token, forKey: "github_personal_access_token")
                if !silent {
                    self.authSuccessMessage = "Connected as @\(profile.login)!"
                    self.showTokenConfig = false
                }
            }
        } catch {
            await MainActor.run {
                self.isAuthenticating = false
                if !silent {
                    self.authErrorMessage = "Auth failed: \(error.localizedDescription)"
                }
            }
        }
    }

    func createRepoAndPushLocalChanges() async {
        guard let workspaceURL = activeWorkspaceURL else {
            createPushErrorMessage = "No active workspace open."
            return
        }

        let repoName = newRepoName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !repoName.isEmpty else {
            createPushErrorMessage = "Repository name cannot be empty."
            return
        }

        isCreatingAndPushing = true
        createPushErrorMessage = nil
        createPushSuccessMessage = nil
        createdRepoURL = nil
        createPushStatus = "Initializing Git workspace..."
        defer {
            isCreatingAndPushing = false
            createPushStatus = nil
        }

        do {
            // 1. Initialize git if not already present
            let gitDir = workspaceURL.appendingPathComponent(".git")
            if !FileManager.default.fileExists(atPath: gitDir.path) {
                _ = try await GitPorcelainService.shared.execute(repositoryURL: workspaceURL, arguments: ["init", "-b", "main"])
            }

            // 2. Stage changes and commit if needed
            createPushStatus = "Staging local changes..."
            _ = try? await GitPorcelainService.shared.execute(repositoryURL: workspaceURL, arguments: ["add", "-A"])
            _ = try? await GitPorcelainService.shared.execute(repositoryURL: workspaceURL, arguments: ["commit", "-m", "Initial commit from CodeEdit"])

            // 3. Ensure branch is named main
            _ = try? await GitPorcelainService.shared.execute(repositoryURL: workspaceURL, arguments: ["branch", "-M", "main"])

            // 4. Create repository on GitHub via REST API
            createPushStatus = "Creating '\(repoName)' on GitHub..."
            let repo = try await GitHubAPIService.shared.createRepository(
                name: repoName,
                description: newRepoDescription.isEmpty ? nil : newRepoDescription,
                isPrivate: newRepoIsPrivate,
                token: activeToken
            )

            // 5. Link remote origin
            createPushStatus = "Configuring remote origin..."
            _ = try? await GitPorcelainService.shared.execute(repositoryURL: workspaceURL, arguments: ["remote", "remove", "origin"])
            _ = try await GitPorcelainService.shared.execute(repositoryURL: workspaceURL, arguments: ["remote", "add", "origin", repo.cloneURL])

            // 6. Push local commits to origin main
            createPushStatus = "Pushing local changes to GitHub..."
            let pushResult = try await GitPorcelainService.shared.execute(repositoryURL: workspaceURL, arguments: ["push", "-u", "origin", "main"])

            await MainActor.run {
                self.currentRemoteURL = repo.cloneURL
                self.currentBranch = "main"
                self.createdRepoURL = repo.htmlURL
                self.createPushSuccessMessage = "Repository '\(repo.name)' created and local changes pushed successfully!"
                self.gitActionStatus = "Push output:\n\(pushResult.trimmingCharacters(in: .whitespacesAndNewlines))"
            }

            NotificationCenter.default.post(name: NSNotification.Name("gitStatusChanged"), object: nil)
            await reloadWorkspaceGitInfo()
        } catch {
            await MainActor.run {
                self.createPushErrorMessage = "Create & Push failed: \(error.localizedDescription)"
            }
        }
    }

    func reloadWorkspaceGitInfo() async {
        guard let workspaceURL = activeWorkspaceURL else { return }
        // Remote origin
        if let out = try? await GitPorcelainService.shared.execute(
            repositoryURL: workspaceURL,
            arguments: ["remote", "get-url", "origin"]
        ) {
            let trimmed = out.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty && !trimmed.contains("fatal:") {
                await MainActor.run { self.currentRemoteURL = trimmed }
            }
        }

        // Branch
        if let out = try? await GitPorcelainService.shared.execute(
            repositoryURL: workspaceURL,
            arguments: ["rev-parse", "--abbrev-ref", "HEAD"]
        ) {
            let trimmed = out.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty && !trimmed.contains("fatal:") {
                await MainActor.run { self.currentBranch = trimmed }
            }
        }
    }

    func connectWorkspaceToRepo(_ repo: GitHubRepoItem) async {
        guard let workspaceURL = activeWorkspaceURL else {
            repoActionMessage = "No workspace folder currently open."
            return
        }

        do {
            let gitDir = workspaceURL.appendingPathComponent(".git")
            if !FileManager.default.fileExists(atPath: gitDir.path) {
                _ = try await GitPorcelainService.shared.execute(repositoryURL: workspaceURL, arguments: ["init", "-b", "main"])
            }

            _ = try? await GitPorcelainService.shared.execute(repositoryURL: workspaceURL, arguments: ["remote", "remove", "origin"])
            _ = try await GitPorcelainService.shared.execute(repositoryURL: workspaceURL, arguments: ["remote", "add", "origin", repo.cloneURL])
            _ = try? await GitPorcelainService.shared.execute(repositoryURL: workspaceURL, arguments: ["fetch", "origin"])

            await MainActor.run {
                self.currentRemoteURL = repo.cloneURL
                self.gitActionStatus = "Connected to \(repo.fullName)! Source Control options are now active."
            }

            NotificationCenter.default.post(name: NSNotification.Name("gitStatusChanged"), object: nil)
            await reloadWorkspaceGitInfo()
        } catch {
            await MainActor.run {
                self.repoActionMessage = "Error connecting remote: \(error.localizedDescription)"
            }
        }
    }

    func connectManualURL() async {
        let trimmed = customRemoteURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let workspaceURL = activeWorkspaceURL else { return }
        isPerformingGitAction = true
        defer { isPerformingGitAction = false }

        do {
            let gitDir = workspaceURL.appendingPathComponent(".git")
            if !FileManager.default.fileExists(atPath: gitDir.path) {
                _ = try await GitPorcelainService.shared.execute(repositoryURL: workspaceURL, arguments: ["init", "-b", "main"])
            }

            _ = try? await GitPorcelainService.shared.execute(repositoryURL: workspaceURL, arguments: ["remote", "remove", "origin"])
            _ = try await GitPorcelainService.shared.execute(repositoryURL: workspaceURL, arguments: ["remote", "add", "origin", trimmed])
            _ = try? await GitPorcelainService.shared.execute(repositoryURL: workspaceURL, arguments: ["fetch", "origin"])

            await MainActor.run {
                self.currentRemoteURL = trimmed
                self.customRemoteURL = ""
                self.gitActionStatus = "Successfully connected remote origin to \(trimmed)."
            }

            NotificationCenter.default.post(name: NSNotification.Name("gitStatusChanged"), object: nil)
            await reloadWorkspaceGitInfo()
        } catch {
            await MainActor.run {
                self.gitActionStatus = "Error: \(error.localizedDescription)"
            }
        }
    }

    func disconnectRemote() async {
        guard let workspaceURL = activeWorkspaceURL else { return }
        _ = try? await GitPorcelainService.shared.execute(repositoryURL: workspaceURL, arguments: ["remote", "remove", "origin"])
        await MainActor.run {
            self.currentRemoteURL = ""
            self.gitActionStatus = "Remote disconnected."
        }
        NotificationCenter.default.post(name: NSNotification.Name("gitStatusChanged"), object: nil)
    }

    func runGitPull() async {
        guard let workspaceURL = activeWorkspaceURL else { return }
        isPerformingGitAction = true
        gitActionStatus = "Pulling latest changes from origin..."
        defer { isPerformingGitAction = false }

        do {
            let branch = currentBranch.isEmpty ? "main" : currentBranch
            let out = try await GitPorcelainService.shared.execute(repositoryURL: workspaceURL, arguments: ["pull", "origin", branch])
            await MainActor.run {
                self.gitActionStatus = "Pull complete:\n\(out.trimmingCharacters(in: .whitespacesAndNewlines))"
            }
            NotificationCenter.default.post(name: NSNotification.Name("gitStatusChanged"), object: nil)
        } catch {
            await MainActor.run {
                self.gitActionStatus = "Pull failed: \(error.localizedDescription)"
            }
        }
    }

    func runGitPush() async {
        guard let workspaceURL = activeWorkspaceURL else { return }
        isPerformingGitAction = true
        gitActionStatus = "Pushing local commits to origin..."
        defer { isPerformingGitAction = false }

        do {
            let branch = currentBranch.isEmpty ? "main" : currentBranch
            let out = try await GitPorcelainService.shared.execute(repositoryURL: workspaceURL, arguments: ["push", "-u", "origin", branch])
            await MainActor.run {
                self.gitActionStatus = "Push complete:\n\(out.trimmingCharacters(in: .whitespacesAndNewlines))"
            }
            NotificationCenter.default.post(name: NSNotification.Name("gitStatusChanged"), object: nil)
        } catch {
            await MainActor.run {
                self.gitActionStatus = "Push failed: \(error.localizedDescription)"
            }
        }
    }

    func performCommit(message: String) async {
        guard let workspaceURL = activeWorkspaceURL else { return }
        isPerformingGitAction = true
        gitActionStatus = "Committing changes..."
        defer { isPerformingGitAction = false }

        do {
            _ = try await GitPorcelainService.shared.execute(repositoryURL: workspaceURL, arguments: ["add", "-A"])
            let out = try await GitPorcelainService.shared.execute(repositoryURL: workspaceURL, arguments: ["commit", "-m", message])
            await MainActor.run {
                self.gitActionStatus = "Committed successfully:\n\(out.trimmingCharacters(in: .whitespacesAndNewlines))"
            }
            NotificationCenter.default.post(name: NSNotification.Name("gitStatusChanged"), object: nil)
            await reloadWorkspaceGitInfo()
        } catch {
            await MainActor.run {
                self.gitActionStatus = "Commit failed: \(error.localizedDescription)"
            }
        }
    }

    func fetchRepositories() async {
        guard let token = activeToken else { return }
        isFetchingRepos = true
        repoActionMessage = nil
        defer { isFetchingRepos = false }

        do {
            let repos = try await GitHubAPIService.shared.listUserRepositories(token: token)
            await MainActor.run {
                self.repositories = repos
            }
        } catch {
            await MainActor.run {
                self.repoActionMessage = "Failed to fetch repositories: \(error.localizedDescription)"
            }
        }
    }
}
