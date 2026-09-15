//
//  CloudDeploymentManagers.swift
//  CodeEdit
//
//

import Foundation

/// Result of a cloud deployment operation.
public struct DeploymentResult: Sendable {
    public let isSuccess: Bool
    public let deploymentURL: URL?
    public let message: String

    public init(isSuccess: Bool, deploymentURL: URL? = nil, message: String) {
        self.isSuccess = isSuccess
        self.deploymentURL = deploymentURL
        self.message = message
    }
}

/// Manager for deploying web apps to Vercel via REST API.
public actor VercelManager {
    public static let shared = VercelManager()

    private init() {}

    /// Triggers deployment to Vercel.
    public func deploy(
        projectName: String,
        directoryURL: URL
    ) async throws -> DeploymentResult {
        guard let token = EditorKeychainManager.shared.get(forKey: "deploy_vercel_token"), !token.isEmpty else {
            return DeploymentResult(isSuccess: false, message: "Missing Vercel API token in Keychain.")
        }

        guard let apiURL = URL(string: "https://api.vercel.com/v13/deployments") else {
            return DeploymentResult(isSuccess: false, message: "Invalid Vercel endpoint URL.")
        }

        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload: [String: Any] = [
            "name": projectName,
            "target": "production"
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await URLSession.shared.data(for: request)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 500

        if statusCode >= 200 && statusCode < 300 {
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let urlString = json["url"] as? String {
                let fullURL = URL(string: "https://\(urlString)")
                return DeploymentResult(isSuccess: true, deploymentURL: fullURL, message: "Deployed to Vercel.")
            }
            return DeploymentResult(isSuccess: true, message: "Vercel deployment triggered successfully.")
        } else {
            let errorText = String(data: data, encoding: .utf8) ?? "HTTP \(statusCode)"
            return DeploymentResult(isSuccess: false, message: "Vercel error: \(errorText)")
        }
    }
}

/// Manager for deploying static sites to Netlify.
public actor NetlifyManager {
    public static let shared = NetlifyManager()

    private init() {}

    /// Deploys web output directory to Netlify.
    public func deploy(
        siteID: String,
        directoryURL: URL
    ) async throws -> DeploymentResult {
        guard let token = EditorKeychainManager.shared.get(forKey: "deploy_netlify_token"), !token.isEmpty else {
            return DeploymentResult(isSuccess: false, message: "Missing Netlify token in Keychain.")
        }

        let endpointString = "https://api.netlify.com/api/v1/sites/\(siteID)/deploys"
        guard let apiURL = URL(string: endpointString) else {
            return DeploymentResult(isSuccess: false, message: "Invalid Netlify endpoint URL.")
        }

        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/zip", forHTTPHeaderField: "Content-Type")

        let zipData = try createZipArchive(for: directoryURL)
        request.httpBody = zipData

        let (data, response) = try await URLSession.shared.data(for: request)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 500

        if statusCode >= 200 && statusCode < 300 {
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let urlString = (json["ssl_url"] as? String) ?? (json["url"] as? String) {
                return DeploymentResult(
                    isSuccess: true,
                    deploymentURL: URL(string: urlString),
                    message: "Deployed to Netlify."
                )
            }
            return DeploymentResult(isSuccess: true, message: "Netlify deployment completed.")
        } else {
            let errorText = String(data: data, encoding: .utf8) ?? "HTTP \(statusCode)"
            return DeploymentResult(isSuccess: false, message: "Netlify error: \(errorText)")
        }
    }

    /// Compresses a local directory into a zip archive.
    private func createZipArchive(for directoryURL: URL) throws -> Data {
        let tempZipURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("deploy_\(UUID().uuidString).zip")
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/zip")
        process.arguments = ["-r", "-q", tempZipURL.path, "."]
        process.currentDirectoryURL = directoryURL
        try process.run()
        process.waitUntilExit()

        defer { try? FileManager.default.removeItem(at: tempZipURL) }
        return try Data(contentsOf: tempZipURL)
    }
}

/// Manager for publishing static sites to GitHub Pages (gh-pages branch).
public actor GitHubPagesManager {
    public static let shared = GitHubPagesManager()

    private init() {}

    /// Automates pushing production output to gh-pages branch.
    public func deploy(
        projectURL: URL,
        buildFolder: String = "build"
    ) async throws -> DeploymentResult {
        let buildURL = projectURL.appendingPathComponent(buildFolder)
        guard FileManager.default.fileExists(atPath: buildURL.path) else {
            return DeploymentResult(isSuccess: false, message: "Build folder '\(buildFolder)' not found.")
        }

        // 1. Create temporary worktree or branch commit
        let initCommand = "git subtree push --prefix \(buildFolder) origin gh-pages"
        let result = try await CommandRunner.execute(command: initCommand, in: projectURL)

        if result.exitCode == 0 {
            return DeploymentResult(
                isSuccess: true,
                message: "Pushed '\(buildFolder)' to gh-pages branch successfully."
            )
        } else {
            return DeploymentResult(
                isSuccess: false,
                message: "GitHub Pages deploy failed:\n\(result.output)"
            )
        }
    }
}
