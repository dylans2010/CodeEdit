//
//  AddPackageDependencyView.swift
//  CodeEdit
//
//

// swiftlint:disable line_length function_body_length

import SwiftUI
import AppKit

public struct FetchedPackageInfo: Identifiable, Sendable {
    public var id: String { "\(owner)/\(name)" }
    public let name: String
    public let owner: String
    public let description: String?
    public let stargazersCount: Int
    public let forksCount: Int
    public let licenseName: String?
    public let defaultBranch: String
    public let tags: [String]
    public let latestVersion: String?
}

struct AddPackageDependencyView: View {
    let workspaceURL: URL
    @Binding var isPresented: Bool
    let onAdded: () -> Void

    @State private var packageURL: String = ""
    @State private var requirementType: String = "Up to Next Major"
    @State private var requirementValue: String = "1.0.0"
    @State private var selectedTag: String = ""

    @State private var isFetching: Bool = false
    @State private var fetchedPackage: FetchedPackageInfo?
    @State private var fetchErrorMessage: String?

    @State private var isAdding: Bool = false
    @State private var addErrorMessage: String?

    let requirementTypes = ["Up to Next Major", "Up to Next Minor", "Exact Version", "Branch"]

    let quickPills = [
        ("Swift Collections", "https://github.com/apple/swift-collections.git"),
        ("Alamofire", "https://github.com/Alamofire/Alamofire.git"),
        ("Kingfisher", "https://github.com/onevcat/Kingfisher.git"),
        ("SnapKit", "https://github.com/SnapKit/SnapKit.git"),
        ("KeychainAccess", "https://github.com/kishikawakatsumi/KeychainAccess.git"),
        ("GRDB.swift", "https://github.com/groue/GRDB.swift.git")
    ]

    var body: some View {
        VStack(spacing: 0) {
            headerBar
            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    urlInputSection
                    quickPillsSection

                    if isFetching {
                        fetchingIndicatorCard
                    } else if let pkg = fetchedPackage {
                        packageDetailsCard(pkg: pkg)
                    } else if let error = fetchErrorMessage {
                        fetchErrorCard(error: error)
                    }

                    dependencyRuleSection

                    if let error = addErrorMessage {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text(error)
                                .font(.system(size: 11))
                                .foregroundColor(.red)
                        }
                        .padding(10)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                .padding(22)
            }

            Divider()
            footerBar
        }
        .frame(width: 680, height: 530)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

// MARK: - Subviews & Layout

extension AddPackageDependencyView {
    private var headerBar: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.accentColor.opacity(0.15))
                    .frame(width: 32, height: 32)
                Image(systemName: "shippingbox.fill")
                    .foregroundColor(.accentColor)
                    .font(.system(size: 16, weight: .semibold))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Add Swift Package Dependency")
                    .font(.system(size: 14, weight: .bold))
                Text("Integrate remote Swift packages into \(workspaceURL.lastPathComponent)")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    // MARK: - URL Input Section

    private var urlInputSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Package Repository URL")
                .font(.system(size: 12, weight: .semibold))

            HStack(spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "globe")
                        .foregroundColor(.secondary)
                        .font(.system(size: 12))
                    TextField("https://github.com/owner/repository.git", text: $packageURL)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12, design: .monospaced))
                        .onSubmit {
                            fetchPackageMetadata()
                        }
                    if !packageURL.isEmpty {
                        Button {
                            packageURL = ""
                            fetchedPackage = nil
                            fetchErrorMessage = nil
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(6)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.secondary.opacity(0.2), lineWidth: 0.8))

                Button {
                    fetchPackageMetadata()
                } label: {
                    HStack(spacing: 4) {
                        if isFetching {
                            ProgressView().controlSize(.small)
                        } else {
                            Image(systemName: "arrow.down.circle.fill")
                        }
                        Text("Fetch Details")
                    }
                    .font(.system(size: 11, weight: .medium))
                }
                .buttonStyle(.bordered)
                .disabled(packageURL.trimmingCharacters(in: .whitespaces).isEmpty || isFetching)
            }
        }
    }

    // MARK: - Quick Pills Section

    private var quickPillsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("POPULAR PACKAGES")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(quickPills, id: \.0) { item in
                        Button {
                            packageURL = item.1
                            fetchPackageMetadata()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "cube.fill")
                                    .font(.system(size: 9))
                                Text(item.0)
                                    .font(.system(size: 11))
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.secondary.opacity(0.15), lineWidth: 0.8))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - Package Details Card

    private func packageDetailsCard(pkg: FetchedPackageInfo) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.orange.opacity(0.15))
                        .frame(width: 36, height: 36)
                    Image(systemName: "shippingbox.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.orange)
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(pkg.name)
                            .font(.system(size: 14, weight: .bold))
                        Text("by \(pkg.owner)")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 11))
                    }

                    if let desc = pkg.description, !desc.isEmpty {
                        Text(desc)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }

                Spacer()
            }

            Divider().opacity(0.3)

            HStack(spacing: 16) {
                if pkg.stargazersCount > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.system(size: 10))
                        Text("\(pkg.stargazersCount) stars")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }

                if pkg.forksCount > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "tuningfork")
                            .foregroundColor(.purple)
                            .font(.system(size: 10))
                        Text("\(pkg.forksCount) forks")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }

                if let lic = pkg.licenseName, !lic.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.text.fill")
                            .foregroundColor(.blue)
                            .font(.system(size: 10))
                        Text(lic)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }

                HStack(spacing: 4) {
                    Image(systemName: "arrow.triangle.branch")
                        .foregroundColor(.accentColor)
                        .font(.system(size: 10))
                    Text(pkg.defaultBranch)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.secondary)
                }

                if let latest = pkg.latestVersion {
                    HStack(spacing: 4) {
                        Image(systemName: "tag.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 10))
                        Text("Latest: \(latest)")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.green)
                    }
                }
            }

            // Quick Tag selector if releases/tags are available
            if !pkg.tags.isEmpty {
                HStack(spacing: 8) {
                    Text("Select Release Tag:")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)

                    Picker("", selection: $selectedTag) {
                        ForEach(pkg.tags.prefix(15), id: \.self) { tag in
                            Text(tag).tag(tag)
                        }
                    }
                    .pickerStyle(.menu)
                    .controlSize(.small)
                    .onChange(of: selectedTag) { newTag in
                        let cleaned = newTag.replacingOccurrences(of: "v", with: "")
                        requirementValue = cleaned
                    }
                }
                .padding(.top, 2)
            }
        }
        .padding(14)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.8))
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.secondary.opacity(0.2), lineWidth: 0.8))
    }

    private var fetchingIndicatorCard: some View {
        HStack(spacing: 12) {
            ProgressView().controlSize(.small)
            Text("Fetching package repository details & release tags...")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding(14)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        .cornerRadius(8)
    }

    private func fetchErrorCard(error: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "info.circle.fill")
                .foregroundColor(.orange)
            Text(error)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding(10)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(8)
    }

    // MARK: - Dependency Rule Section

    private var dependencyRuleSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Dependency Rule")
                .font(.system(size: 12, weight: .semibold))

            Picker("", selection: $requirementType) {
                ForEach(requirementTypes, id: \.self) { type in
                    Text(type).tag(type)
                }
            }
            .pickerStyle(.segmented)

            HStack(spacing: 10) {
                Text(requirementType == "Branch" ? "Branch Name:" : "Version:")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(width: 80, alignment: .leading)

                TextField(requirementType == "Branch" ? "main" : "1.0.0", text: $requirementValue)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 12, design: .monospaced))

                if requirementType == "Up to Next Major" {
                    let nextMajor = (Int(requirementValue.components(separatedBy: ".").first ?? "1") ?? 1) + 1
                    Text("<\(nextMajor).0.0")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.secondary)
                } else if requirementType == "Up to Next Minor" {
                    let parts = requirementValue.components(separatedBy: ".")
                    let major = parts.first ?? "1"
                    let minor = (Int(parts.count > 1 ? parts[1] : "0") ?? 0) + 1
                    Text("<\(major).\(minor).0")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.secondary)
                }
            }

            Text(ruleDescription)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
        }
        .padding(14)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.4))
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.secondary.opacity(0.15), lineWidth: 0.8))
    }

    private var ruleDescription: String {
        switch requirementType {
        case "Up to Next Major":
            return "Allows updates up to the next breaking major version release (recommended for semantic versioning)."
        case "Up to Next Minor":
            return "Allows bug fixes and minor patches within the specified minor version."
        case "Exact Version":
            return "Locks package to this exact version tag. No automated updates are pulled."
        case "Branch":
            return "Tracks the latest commits on the specified remote branch (e.g. main or develop)."
        default:
            return ""
        }
    }

    // MARK: - Footer Bar

    private var footerBar: some View {
        HStack {
            Button("Cancel") {
                isPresented = false
            }
            .keyboardShortcut(.cancelAction)

            Spacer()

            if isAdding {
                ProgressView()
                    .scaleEffect(0.7)
                    .padding(.trailing, 4)
            }

            Button("Add Package Dependency") {
                addDependency()
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.defaultAction)
            .disabled(packageURL.trimmingCharacters(in: .whitespaces).isEmpty || isAdding)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    // MARK: - Metadata Fetching

    private func fetchPackageMetadata() {
        let trimmed = packageURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isFetching = true
        fetchErrorMessage = nil
        fetchedPackage = nil

        Task {
            // Extract owner and repo from URL
            guard let (owner, repo) = extractGitHubOwnerAndRepo(from: trimmed) else {
                await MainActor.run {
                    self.isFetching = false
                    let name = (trimmed as NSString).lastPathComponent.replacingOccurrences(of: ".git", with: "")
                    self.fetchedPackage = FetchedPackageInfo(
                        name: name,
                        owner: "Custom Remote",
                        description: "Git Package Repository at \(trimmed)",
                        stargazersCount: 0,
                        forksCount: 0,
                        licenseName: nil,
                        defaultBranch: "main",
                        tags: [],
                        latestVersion: nil
                    )
                }
                return
            }

            do {
                let token = EditorKeychainManager.shared.get(forKey: "github_personal_access_token")
                let (repoData, _) = try await makeGitHubRequest(path: "/repos/\(owner)/\(repo)", token: token)
                let repoJSON = (try? JSONSerialization.jsonObject(with: repoData) as? [String: Any]) ?? [:]

                let name = repoJSON["name"] as? String ?? repo
                let desc = repoJSON["description"] as? String
                let stars = repoJSON["stargazers_count"] as? Int ?? 0
                let forks = repoJSON["forks_count"] as? Int ?? 0
                let defBranch = repoJSON["default_branch"] as? String ?? "main"
                let licenseObj = repoJSON["license"] as? [String: Any]
                let licenseName = licenseObj?["spdx_id"] as? String ?? licenseObj?["name"] as? String

                // Fetch tags/releases
                var tagNames: [String] = []
                if let (tagsData, _) = try? await makeGitHubRequest(path: "/repos/\(owner)/\(repo)/tags?per_page=30", token: token),
                   let tagsArray = try? JSONSerialization.jsonObject(with: tagsData) as? [[String: Any]] {
                    tagNames = tagsArray.compactMap { $0["name"] as? String }
                }

                let latestVer = tagNames.first.map { $0.replacingOccurrences(of: "v", with: "") }

                await MainActor.run {
                    self.isFetching = false
                    self.fetchedPackage = FetchedPackageInfo(
                        name: name,
                        owner: owner,
                        description: desc,
                        stargazersCount: stars,
                        forksCount: forks,
                        licenseName: licenseName,
                        defaultBranch: defBranch,
                        tags: tagNames,
                        latestVersion: latestVer
                    )

                    if let latest = latestVer, !latest.isEmpty {
                        self.requirementValue = latest
                        if let firstTag = tagNames.first {
                            self.selectedTag = firstTag
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    self.isFetching = false
                    self.fetchErrorMessage = "Could not reach GitHub API (\(error.localizedDescription)). Package will be added with standard Git resolution."
                    let name = (trimmed as NSString).lastPathComponent.replacingOccurrences(of: ".git", with: "")
                    self.fetchedPackage = FetchedPackageInfo(
                        name: name,
                        owner: owner,
                        description: "Remote Swift Package",
                        stargazersCount: 0,
                        forksCount: 0,
                        licenseName: nil,
                        defaultBranch: "main",
                        tags: [],
                        latestVersion: nil
                    )
                }
            }
        }
    }

    private func extractGitHubOwnerAndRepo(from urlStr: String) -> (String, String)? {
        let clean = urlStr
            .replacingOccurrences(of: ".git", with: "")
            .replacingOccurrences(of: "https://", with: "")
            .replacingOccurrences(of: "http://", with: "")
            .replacingOccurrences(of: "git@github.com:", with: "github.com/")
        let parts = clean.components(separatedBy: "/").filter { !$0.isEmpty }
        if let idx = parts.firstIndex(of: "github.com"), idx + 2 < parts.count {
            return (parts[idx + 1], parts[idx + 2])
        } else if parts.count >= 2 {
            return (parts[parts.count - 2], parts[parts.count - 1])
        }
        return nil
    }

    private func makeGitHubRequest(path: String, token: String?) async throws -> (Data, URLResponse) {
        let url = URL(string: "https://api.github.com\(path)")!
        var req = URLRequest(url: url)
        req.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        if let validToken = token, !validToken.isEmpty {
            req.setValue("Bearer \(validToken)", forHTTPHeaderField: "Authorization")
        }
        return try await URLSession.shared.data(for: req)
    }

    private func addDependency() {
        isAdding = true
        addErrorMessage = nil

        Task {
            do {
                try await WorkspaceDependencyService.shared.addPackageDependency(
                    workspaceURL: workspaceURL,
                    packageURL: packageURL,
                    requirementType: requirementType,
                    requirementValue: requirementValue
                )
                await MainActor.run {
                    self.isAdding = false
                    self.isPresented = false
                    self.onAdded()
                }
            } catch {
                await MainActor.run {
                    self.isAdding = false
                    self.addErrorMessage = error.localizedDescription
                }
            }
        }
    }
}

