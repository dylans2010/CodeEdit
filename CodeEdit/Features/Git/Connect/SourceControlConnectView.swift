//
//  SourceControlConnectView.swift
//  CodeEdit
//
//

// swiftlint:disable file_length type_body_length line_length function_body_length

import SwiftUI
import AppKit

/// A modern, Liquid Glass view and window controller for connecting workspaces to GitHub,
/// managing Personal Access Tokens, browsing repositories, and orchestrating Source Control operations.
public struct SourceControlConnectView: View {
    @ObservedObject private var prefs = AppPreferencesModel.shared

    // MARK: - Navigation & Tabs
    @State private var selectedTab: Int = 0 // 0: Active Project, 1: Browse Repos, 2: Token & Auth

    // MARK: - Token & Auth State
    @State private var tokenInput: String = ""
    @State private var isTokenVisible: Bool = false
    @State private var authenticatedUser: GitHubUserProfile?
    @State private var isAuthenticating: Bool = false
    @State private var authErrorMessage: String?
    @State private var authSuccessMessage: String?

    // MARK: - Repository Browser State
    @State private var repositories: [GitHubRepoItem] = []
    @State private var isFetchingRepos: Bool = false
    @State private var repoSearchText: String = ""
    @State private var selectedRepo: GitHubRepoItem?
    @State private var repoActionMessage: String?

    // MARK: - Workspace & Git State
    @State private var currentRemoteURL: String = ""
    @State private var currentBranch: String = ""
    @State private var customRemoteURL: String = ""
    @State private var isPerformingGitAction: Bool = false
    @State private var gitActionStatus: String?
    @State private var commitMessageText: String = ""
    @State private var showCommitSheet: Bool = false

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
        ZStack {
            liquidGlassBackground

            VStack(spacing: 0) {
                topHeaderBar
                    .padding(.horizontal, 20)
                    .padding(.top, 18)
                    .padding(.bottom, 12)

                glassTabBar
                    .padding(.horizontal, 20)
                    .padding(.bottom, 14)

                Divider()
                    .opacity(0.4)

                Group {
                    switch selectedTab {
                    case 0:
                        activeProjectView
                    case 1:
                        browseRepositoriesView
                    case 2:
                        tokenAndAuthView
                    default:
                        activeProjectView
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(width: 740, height: 580)
        .task {
            await initializeViewState()
        }
    }

    // MARK: - Liquid Glass Background

    private var liquidGlassBackground: some View {
        ZStack {
            Color(NSColor.windowBackgroundColor)

            LinearGradient(
                colors: [
                    Color.blue.opacity(0.12),
                    Color.indigo.opacity(0.14),
                    Color.purple.opacity(0.10),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(Color.blue.opacity(0.20))
                .frame(width: 340, height: 340)
                .blur(radius: 80)
                .offset(x: -200, y: -180)

            Circle()
                .fill(Color.purple.opacity(0.18))
                .frame(width: 300, height: 300)
                .blur(radius: 75)
                .offset(x: 220, y: 160)
        }
        .ignoresSafeArea()
    }

    // MARK: - Header Bar

    private var topHeaderBar: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.blue, Color.purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 38, height: 38)
                    .shadow(color: Color.blue.opacity(0.4), radius: 8, x: 0, y: 2)

                Image(systemName: "point.3.connected.trianglepath.dotted")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text("GitHub Source Control")
                        .font(.system(size: 16, weight: .bold))
                    if authenticatedUser != nil {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 13))
                    }
                }

                Text("Link your workspace, manage tokens, and orchestrate Git remote actions.")
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

                    Button("Switch") {
                        selectedTab = 2
                    }
                    .buttonStyle(.borderless)
                    .font(.system(size: 11))
                    .foregroundColor(.accentColor)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.15), lineWidth: 0.8)
                )
            } else {
                Button {
                    selectedTab = 2
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "key.horizontal.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.orange)
                        Text("Add GitHub Token")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Glass Tab Bar

    private var glassTabBar: some View {
        HStack(spacing: 6) {
            tabButton(title: "Active Project", icon: "externaldrive.connected.to.line.below", index: 0)
            tabButton(title: "Browse Repositories", icon: "globe", index: 1)
            tabButton(title: "GitHub Token & Auth", icon: "key.horizontal.fill", index: 2)
            Spacer()
        }
    }

    private func tabButton(title: String, icon: String, index: Int) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                selectedTab = index
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(selectedTab == index ? .accentColor : .secondary)

                Text(title)
                    .font(.system(size: 12, weight: selectedTab == index ? .semibold : .regular))
                    .foregroundColor(selectedTab == index ? .primary : .secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(selectedTab == index ? Color.primary.opacity(0.10) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(selectedTab == index ? Color.white.opacity(0.14) : Color.clear, lineWidth: 0.8)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Window Management

    public static func openConnectWindow() {
        if let window = NSApp.windows.first(where: {
            ($0.contentView as? NSHostingView<SourceControlConnectView>) != nil
        }) {
            window.makeKeyAndOrderFront(nil)
            return
        }

        let view = SourceControlConnectView()
        let hostingController = NSHostingController(rootView: view)
        let window = NSWindow(contentViewController: hostingController)
        window.title = "Source Control — Connect to GitHub"
        window.setContentSize(NSSize(width: 740, height: 580))
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView]
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isReleasedWhenClosed = false
        window.center()
        window.makeKeyAndOrderFront(nil)
    }

    private func initializeViewState() async {
        if let savedToken = EditorKeychainManager.shared.get(forKey: "github_personal_access_token"),
           !savedToken.isEmpty {
            tokenInput = savedToken
            await authenticateWithToken(savedToken, silent: true)
        }
        await reloadWorkspaceGitInfo()
    }
}

// MARK: - Tab 0: Active Project & Source Control Operations

extension SourceControlConnectView {
    @ViewBuilder
    var activeProjectView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if !currentRemoteURL.isEmpty {
                    connectedRepositoryHeroCard
                    sourceControlQuickActionsSection
                } else {
                    unconnectedWorkspaceGuideCard
                    manualRemoteConnectCard
                }

                if let status = gitActionStatus {
                    statusFeedbackBanner(message: status)
                }
            }
            .padding(20)
        }
        .sheet(isPresented: $showCommitSheet) {
            commitDialogSheet
        }
    }

    private var connectedRepositoryHeroCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.2))
                        .frame(width: 36, height: 36)
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.green)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Workspace Connected to GitHub")
                        .font(.system(size: 15, weight: .bold))
                    Text("Source Control options are active for this repository.")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }

                Spacer()

                if let url = URL(string: currentRemoteURL.replacingOccurrences(of: ".git", with: "")) {
                    Button {
                        NSWorkspace.shared.open(url)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "safari.fill")
                            Text("Open on GitHub ↗")
                        }
                        .font(.system(size: 11))
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }

            Divider().opacity(0.3)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "globe")
                        .foregroundColor(.blue)
                        .frame(width: 16)
                    Text("Remote Origin:")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                    Text(currentRemoteURL)
                        .font(.system(size: 11, design: .monospaced))
                        .textSelection(.enabled)
                }

                if !currentBranch.isEmpty {
                    HStack {
                        Image(systemName: "arrow.triangle.branch")
                            .foregroundColor(.purple)
                            .frame(width: 16)
                        Text("Active Branch:")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                        Text(currentBranch)
                            .font(.system(size: 11, weight: .semibold))
                    }
                }

                if let ws = activeWorkspaceURL {
                    HStack {
                        Image(systemName: "folder.fill")
                            .foregroundColor(.orange)
                            .frame(width: 16)
                        Text("Folder:")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                        Text(ws.path)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Color.green.opacity(0.4), Color.white.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.green.opacity(0.1), radius: 10, x: 0, y: 4)
    }

    private var sourceControlQuickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SOURCE CONTROL ACTIONS")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.secondary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                actionCard(
                    title: "Open Source Control Navigator",
                    subtitle: "View staged, modified, and uncommitted files in the sidebar.",
                    icon: "vault.fill",
                    color: .blue
                ) {
                    NotificationCenter.default.post(name: NSNotification.Name("FocusSourceControlNavigator"), object: nil)
                    gitActionStatus = "Switched main sidebar to Version Control tab."
                }

                actionCard(
                    title: "Commit Changes...",
                    subtitle: "Stage files and create a new Git commit.",
                    icon: "plus.circle.fill",
                    color: .green
                ) {
                    showCommitSheet = true
                }

                actionCard(
                    title: "Pull from Origin",
                    subtitle: "Fetch and integrate changes from remote branch.",
                    icon: "arrow.triangle.pull",
                    color: .purple
                ) {
                    await runGitPull()
                }

                actionCard(
                    title: "Push to Origin",
                    subtitle: "Publish local commits to GitHub repository.",
                    icon: "arrow.triangle.push",
                    color: .indigo
                ) {
                    await runGitPush()
                }
            }

            HStack {
                Button(role: .destructive) {
                    Task { await disconnectRemote() }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "link.badge.plus")
                        Text("Disconnect or Change Remote...")
                    }
                    .font(.system(size: 11))
                }
                .buttonStyle(.borderless)
                .foregroundColor(.secondary)

                Spacer()

                Button {
                    Task { await reloadWorkspaceGitInfo() }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                        Text("Refresh Status")
                    }
                    .font(.system(size: 11))
                }
                .buttonStyle(.borderless)
            }
            .padding(.top, 6)
        }
    }

    private func actionCard(title: String, subtitle: String, icon: String, color: Color, action: @escaping () async -> Void) -> some View {
        Button {
            Task { await action() }
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(color.opacity(0.18))
                        .frame(width: 34, height: 34)
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(color)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.primary)
                    Text(subtitle)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                Spacer(minLength: 0)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.white.opacity(0.1), lineWidth: 0.8)
            )
        }
        .buttonStyle(.plain)
    }

    private var unconnectedWorkspaceGuideCard: some View {
        VStack(spacing: 14) {
            Image(systemName: "point.3.connected.trianglepath.dotted")
                .font(.system(size: 38))
                .foregroundColor(.accentColor)

            VStack(spacing: 4) {
                Text("Connect Current Workspace to GitHub")
                    .font(.system(size: 15, weight: .bold))
                Text("Select an existing GitHub repo or enter a remote URL to initialize Git and enable Source Control.")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
            }

            HStack(spacing: 12) {
                Button {
                    selectedTab = 1
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "globe")
                        Text("Browse My Repositories...")
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)

                Button {
                    selectedTab = 2
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "key.horizontal.fill")
                            .foregroundColor(.orange)
                        Text("Configure Token")
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
    }

    private var manualRemoteConnectCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "link.badge.plus")
                    .foregroundColor(.accentColor)
                Text("OR CONNECT VIA GIT URL")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 10) {
                TextField("https://github.com/user/repository.git", text: $customRemoteURL)
                    .textFieldStyle(.roundedBorder)

                Button {
                    Task { await connectManualURL() }
                } label: {
                    HStack(spacing: 4) {
                        if isPerformingGitAction {
                            ProgressView().controlSize(.small)
                        } else {
                            Image(systemName: "arrow.right.circle.fill")
                        }
                        Text("Connect")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(customRemoteURL.trimmingCharacters(in: .whitespaces).isEmpty || isPerformingGitAction)
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.white.opacity(0.1), lineWidth: 0.8)
        )
    }

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
        .background(Color.blue.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Tab 1: Browse Repositories

extension SourceControlConnectView {
    @ViewBuilder
    var browseRepositoriesView: some View {
        VStack(spacing: 12) {
            // Search & Fetch Controls
            HStack(spacing: 10) {
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search your GitHub repositories...", text: $repoSearchText)
                        .textFieldStyle(.plain)
                    if !repoSearchText.isEmpty {
                        Button {
                            repoSearchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.1), lineWidth: 0.8))

                Button {
                    Task { await fetchRepositories() }
                } label: {
                    HStack(spacing: 5) {
                        if isFetchingRepos {
                            ProgressView().controlSize(.small)
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                        Text("Fetch")
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                }
                .buttonStyle(.bordered)
                .disabled(isFetchingRepos || activeToken == nil)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)

            if let msg = repoActionMessage {
                statusFeedbackBanner(message: msg)
                    .padding(.horizontal, 20)
            }

            // Repository List
            if isFetchingRepos {
                VStack(spacing: 10) {
                    Spacer()
                    ProgressView()
                    Text("Fetching your GitHub repositories...")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Spacer()
                }
            } else if filteredRepos.isEmpty {
                emptyRepositoriesPlaceholder
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(filteredRepos) { repo in
                            repositoryRow(repo: repo)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                }
            }
        }
    }

    private var filteredRepos: [GitHubRepoItem] {
        if repoSearchText.isEmpty { return repositories }
        return repositories.filter {
            $0.name.localizedCaseInsensitiveContains(repoSearchText) ||
            $0.fullName.localizedCaseInsensitiveContains(repoSearchText) ||
            ($0.description ?? "").localizedCaseInsensitiveContains(repoSearchText)
        }
    }

    private func repositoryRow(repo: GitHubRepoItem) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: repo.isPrivate ? "lock.fill" : "globe")
                .font(.system(size: 14))
                .foregroundColor(repo.isPrivate ? .orange : .blue)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(repo.fullName)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.primary)

                    if (repo.stargazersCount ?? 0) > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 9))
                                .foregroundColor(.yellow)
                            Text("\(repo.stargazersCount ?? 0)")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                    }
                }

                if let desc = repo.description, !desc.isEmpty {
                    Text(desc)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            HStack(spacing: 8) {
                Button {
                    Task { await connectWorkspaceToRepo(repo) }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "link.badge.plus")
                        Text("Connect Workspace")
                    }
                    .font(.system(size: 11, weight: .medium))
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)

                Button {
                    Task { await cloneRepoLocally(repo) }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "icloud.and.arrow.down.fill")
                        Text("Clone...")
                    }
                    .font(.system(size: 11))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.white.opacity(0.10), lineWidth: 0.8)
        )
    }

    private var emptyRepositoriesPlaceholder: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "folder.badge.gearshape")
                .font(.system(size: 36))
                .foregroundColor(.secondary)

            if activeToken == nil {
                Text("No GitHub Token Configured")
                    .font(.system(size: 13, weight: .semibold))
                Text("Please configure your GitHub Personal Access Token to fetch and sync your repositories.")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                Button("Configure GitHub Token") {
                    selectedTab = 2
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
            } else {
                Text("No Repositories Found")
                    .font(.system(size: 13, weight: .semibold))
                Text("Click 'Fetch' above to load repositories from your GitHub account.")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)

                Button("Fetch Repositories") {
                    Task { await fetchRepositories() }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
            }
            Spacer()
        }
        .padding(20)
    }
}

// MARK: - Tab 2: Token & Authentication

extension SourceControlConnectView {
    @ViewBuilder
    var tokenAndAuthView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                tokenConfigCard
                keychainSecurityCard
                generateTokenGuideCard
            }
            .padding(20)
        }
    }

    private var tokenConfigCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.2))
                        .frame(width: 32, height: 32)
                    Image(systemName: "key.horizontal.fill")
                        .foregroundColor(.orange)
                        .font(.system(size: 15))
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text("GitHub Personal Access Token (PAT)")
                        .font(.system(size: 14, weight: .bold))
                    Text("Stored securely in macOS Keychain for git authentication and repo querying.")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }

            Divider().opacity(0.3)

            VStack(alignment: .leading, spacing: 8) {
                Text("TOKEN")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary)

                HStack(spacing: 8) {
                    if isTokenVisible {
                        TextField("ghp_xxxxxxxxxxxxxxxxxxxx", text: $tokenInput)
                            .textFieldStyle(.roundedBorder)
                    } else {
                        SecureField("ghp_xxxxxxxxxxxxxxxxxxxx", text: $tokenInput)
                            .textFieldStyle(.roundedBorder)
                    }

                    Button {
                        isTokenVisible.toggle()
                    } label: {
                        Image(systemName: isTokenVisible ? "eye.slash.fill" : "eye.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.borderless)

                    Button {
                        Task { await saveAndAuthenticateToken() }
                    } label: {
                        HStack(spacing: 5) {
                            if isAuthenticating {
                                ProgressView().controlSize(.small)
                            } else {
                                Image(systemName: "sparkles")
                            }
                            Text("Authenticate & Save")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(tokenInput.trimmingCharacters(in: .whitespaces).isEmpty || isAuthenticating)
                }

                if let err = authErrorMessage {
                    Text(err)
                        .font(.system(size: 11))
                        .foregroundColor(.red)
                }

                if let success = authSuccessMessage {
                    Text(success)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.green)
                }
            }

            if let user = authenticatedUser {
                Divider().opacity(0.3)

                HStack(spacing: 12) {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.accentColor)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(user.name ?? user.login)
                            .font(.system(size: 13, weight: .bold))
                        Text("@\(user.login)")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    HStack(spacing: 10) {
                        badgeView(title: "Public Repos", count: user.publicRepos ?? 0)
                        badgeView(title: "Private Repos", count: user.totalPrivateRepos ?? 0)
                    }
                }
                .padding(10)
                .background(Color.primary.opacity(0.04))
                .cornerRadius(8)
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
    }

    private func badgeView(title: String, count: Int) -> some View {
        VStack(spacing: 1) {
            Text("\(count)")
                .font(.system(size: 12, weight: .bold))
            Text(title)
                .font(.system(size: 9))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.ultraThinMaterial)
        .cornerRadius(6)
    }

    private var keychainSecurityCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 24))
                .foregroundColor(.green)

            VStack(alignment: .leading, spacing: 2) {
                Text("Secure Keychain Encryption")
                    .font(.system(size: 12, weight: .semibold))
                Text("Your token is protected using macOS Keychain and never stored in plain text.")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 0.8)
        )
    }

    private var generateTokenGuideCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("NEED A TOKEN?")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.secondary)

            Text("Generate a personal access token on GitHub with `repo` and `read:user` permissions.")
                .font(.system(size: 11))
                .foregroundColor(.secondary)

            Button {
                if let url = URL(string: "https://github.com/settings/tokens/new?scopes=repo,read:user&description=CodeEdit%20Integration") {
                    NSWorkspace.shared.open(url)
                }
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "arrow.up.right.square")
                    Text("Generate Token on GitHub ↗")
                }
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 0.8)
        )
    }
}

// MARK: - Action Handlers & Git Operations

extension SourceControlConnectView {
    func authenticateWithToken(_ token: String, silent: Bool = false) async {
        isAuthenticating = true
        authErrorMessage = nil
        if !silent { authSuccessMessage = nil }
        defer { isAuthenticating = false }

        do {
            let profile = try await GitHubAPIService.shared.validateTokenAndGetUser(token: token)
            await MainActor.run {
                self.authenticatedUser = profile
                if !silent {
                    self.authSuccessMessage = "✓ Verified as @\(profile.login)"
                }
                // Save token in Keychain
                _ = EditorKeychainManager.shared.set(token, forKey: "github_personal_access_token")
                _ = EditorKeychainManager.shared.set(token, forKey: "github_\(profile.login)")

                // Register account in preferences
                let providerLink = "https://github.com"
                if !self.prefs.preferences.accounts.sourceControlAccounts.gitAccount.contains(
                    where: { $0.gitAccountName.lowercased() == profile.login.lowercased() }
                ) {
                    self.prefs.preferences.accounts.sourceControlAccounts.gitAccount.append(
                        SourceControlAccounts(
                            id: "\(providerLink)_\(profile.login.lowercased())",
                            gitProvider: "GitHub",
                            gitProviderLink: providerLink,
                            gitProviderDescription: "GitHub",
                            gitAccountName: profile.login,
                            gitCloningProtocol: true,
                            gitSSHKey: "",
                            isTokenValid: true
                        )
                    )
                }
            }
            if repositories.isEmpty {
                await fetchRepositories()
            }
        } catch {
            await MainActor.run {
                if !silent {
                    self.authErrorMessage = error.localizedDescription
                }
            }
        }
    }

    func saveAndAuthenticateToken() async {
        let trimmed = tokenInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        await authenticateWithToken(trimmed, silent: false)
    }

    func fetchRepositories() async {
        guard let token = activeToken, !token.isEmpty else {
            repoActionMessage = "Please configure a GitHub token first."
            return
        }
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
            // Check if git is initialized
            let gitDir = workspaceURL.appendingPathComponent(".git")
            if !FileManager.default.fileExists(atPath: gitDir.path) {
                _ = try await GitPorcelainService.shared.execute(repositoryURL: workspaceURL, arguments: ["init", "-b", "main"])
            }

            // Remove existing origin if needed
            _ = try? await GitPorcelainService.shared.execute(repositoryURL: workspaceURL, arguments: ["remote", "remove", "origin"])

            // Add new origin
            _ = try await GitPorcelainService.shared.execute(repositoryURL: workspaceURL, arguments: ["remote", "add", "origin", repo.cloneURL])

            // Try to fetch origin
            _ = try? await GitPorcelainService.shared.execute(repositoryURL: workspaceURL, arguments: ["fetch", "origin"])

            await MainActor.run {
                self.currentRemoteURL = repo.cloneURL
                self.selectedTab = 0
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

    func cloneRepoLocally(_ repo: GitHubRepoItem) async {
        let panel = NSOpenPanel()
        panel.title = "Select Folder to Clone \(repo.name)"
        panel.prompt = "Clone Here"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true

        guard panel.runModal() == .OK, let destinationURL = panel.url else { return }

        let targetDir = destinationURL.appendingPathComponent(repo.name)
        repoActionMessage = "Cloning \(repo.fullName)..."

        do {
            _ = try await GitPorcelainService.shared.runGit(
                arguments: ["clone", repo.cloneURL, targetDir.path],
                repositoryURL: destinationURL
            )

            await MainActor.run {
                self.repoActionMessage = "Successfully cloned to \(targetDir.lastPathComponent)!"
                CodeEditDocumentController.shared.openDocument(withContentsOf: targetDir, display: true) { _, _, _ in }
            }
        } catch {
            await MainActor.run {
                self.repoActionMessage = "Clone failed: \(error.localizedDescription)"
            }
        }
    }
}
