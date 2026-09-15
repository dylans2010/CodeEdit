//
//  GitHubAPIService.swift
//  CodeEdit
//
//

import Foundation

/// GitHub Pull Request representation.
public struct GitHubPRItem: Identifiable, Codable, Sendable {
    public let id: Int
    public let number: Int
    public let title: String
    public let state: String
    public let htmlURL: String?

    enum CodingKeys: String, CodingKey {
        case id
        case number
        case title
        case state
        case htmlURL = "html_url"
    }
}

/// GitHub Issue representation.
public struct GitHubIssueItem: Identifiable, Codable, Sendable {
    public let id: Int
    public let number: Int
    public let title: String
    public let state: String
    public let body: String?

    enum CodingKeys: String, CodingKey {
        case id
        case number
        case title
        case state
        case body
    }
}

/// GitHub Repository representation.
public struct GitHubRepoItem: Identifiable, Codable, Sendable, Hashable {
    public let id: Int
    public let name: String
    public let fullName: String
    public let description: String?
    public let htmlURL: String
    public let cloneURL: String
    public let isPrivate: Bool
    public let stargazersCount: Int?

    public init(
        id: Int,
        name: String,
        fullName: String,
        description: String? = nil,
        htmlURL: String,
        cloneURL: String,
        isPrivate: Bool = false,
        stargazersCount: Int? = 0
    ) {
        self.id = id
        self.name = name
        self.fullName = fullName
        self.description = description
        self.htmlURL = htmlURL
        self.cloneURL = cloneURL
        self.isPrivate = isPrivate
        self.stargazersCount = stargazersCount
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case fullName = "full_name"
        case description
        case htmlURL = "html_url"
        case cloneURL = "clone_url"
        case isPrivate = "private"
        case stargazersCount = "stargazers_count"
    }
}

/// Service integrating GitHub REST API for PRs, Issues, and Gists.
public actor GitHubAPIService {
    public static let shared = GitHubAPIService()

    private let baseURL = "https://api.github.com"

    private init() {}

    private func makeRequest(endpoint: String, method: String = "GET") throws -> URLRequest {
        guard let token = EditorKeychainManager.shared.get(forKey: "github_personal_access_token") else {
            throw NSError(
                domain: "GitHubAPI",
                code: 401,
                userInfo: [NSLocalizedDescriptionKey: "Missing GitHub Personal Access Token in Keychain."]
            )
        }
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw NSError(domain: "GitHubAPI", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }

        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        return req
    }

    /// Lists pull requests for repository (owner/repo).
    public func listPullRequests(owner: String, repo: String) async throws -> [GitHubPRItem] {
        let req = try makeRequest(endpoint: "/repos/\(owner)/\(repo)/pulls")
        let (data, _) = try await URLSession.shared.data(for: req)
        return (try? JSONDecoder().decode([GitHubPRItem].self, from: data)) ?? []
    }

    /// Creates a pull request.
    public func createPullRequest(
        owner: String,
        repo: String,
        title: String,
        body: String,
        head: String,
        base: String = "main"
    ) async throws -> GitHubPRItem {
        var req = try makeRequest(endpoint: "/repos/\(owner)/\(repo)/pulls", method: "POST")
        let payload: [String: String] = ["title": title, "body": body, "head": head, "base": base]
        req.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, _) = try await URLSession.shared.data(for: req)
        return try JSONDecoder().decode(GitHubPRItem.self, from: data)
    }

    /// Merges a pull request using specified method (squash, rebase, merge).
    public func mergePullRequest(
        owner: String,
        repo: String,
        number: Int,
        mergeMethod: String = "squash"
    ) async throws -> Bool {
        var req = try makeRequest(endpoint: "/repos/\(owner)/\(repo)/pulls/\(number)/merge", method: "PUT")
        req.httpBody = try JSONSerialization.data(withJSONObject: ["merge_method": mergeMethod])
        let (_, response) = try await URLSession.shared.data(for: req)
        return (response as? HTTPURLResponse)?.statusCode == 200
    }

    /// Lists repository issues.
    public func listIssues(owner: String, repo: String) async throws -> [GitHubIssueItem] {
        let req = try makeRequest(endpoint: "/repos/\(owner)/\(repo)/issues")
        let (data, _) = try await URLSession.shared.data(for: req)
        return (try? JSONDecoder().decode([GitHubIssueItem].self, from: data)) ?? []
    }

    /// Creates a GitHub Gist from code content.
    public func createGist(
        filename: String,
        content: String,
        isPublic: Bool = false
    ) async throws -> String {
        var req = try makeRequest(endpoint: "/gists", method: "POST")
        let payload: [String: Any] = [
            "description": "Created from CodeEdit",
            "public": isPublic,
            "files": [
                filename: ["content": content]
            ]
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: payload)
        let (data, _) = try await URLSession.shared.data(for: req)
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let htmlURL = json["html_url"] as? String {
            return htmlURL
        }
        return "https://gist.github.com"
    }

    /// Lists repositories for the authenticated user or specific username.
    public func listUserRepositories(token: String? = nil, username: String? = nil) async throws -> [GitHubRepoItem] {
        let activeToken = token ?? EditorKeychainManager.shared.get(forKey: "github_personal_access_token")
        let endpoint: String
        if let user = username, !user.isEmpty {
            endpoint = "/users/\(user)/repos?sort=updated&per_page=100"
        } else {
            endpoint = "/user/repos?sort=updated&per_page=100"
        }

        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw NSError(domain: "GitHubAPI", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }

        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        if let token = activeToken, !token.isEmpty {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        req.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: req)
        if let http = response as? HTTPURLResponse, http.statusCode >= 400 {
            let msg = String(data: data, encoding: .utf8) ?? "HTTP \(http.statusCode)"
            throw NSError(domain: "GitHubAPI", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: msg])
        }
        return (try? JSONDecoder().decode([GitHubRepoItem].self, from: data)) ?? []
    }
}

