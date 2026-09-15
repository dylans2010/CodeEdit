//
//  SwiftPackageBuildService.swift
//  CodeEdit
//
//

import Foundation

/// Represents a pinned package dependency from Package.resolved.
public struct PinnedPackageDependency: Identifiable, Codable, Sendable {
    public var id: String { identity }
    public let identity: String
    public let location: String
    public let version: String?
    public let revision: String?
    public let branch: String?

    public init(
        identity: String,
        location: String,
        version: String? = nil,
        revision: String? = nil,
        branch: String? = nil
    ) {
        self.identity = identity
        self.location = location
        self.version = version
        self.revision = revision
        self.branch = branch
    }
}

/// Service executing Swift Package Manager CLI commands and auditing dependencies.
public actor SwiftPackageBuildService {
    /// Shared singleton instance of SwiftPackageBuildService.
    public static let shared = SwiftPackageBuildService()

    private init() {}

    /// Executes `swift build` with optional target triple and flags.
    public func build(
        projectURL: URL,
        triple: String? = nil,
        extraFlags: [String] = []
    ) async throws -> BuildExecutionResult {
        let startTime = Date()
        var command = "swift build"
        if let targetTriple = triple, !targetTriple.isEmpty {
            command += " --triple \(targetTriple)"
        }
        for flag in extraFlags {
            command += " \(flag)"
        }

        let runResult = try await CommandRunner.execute(command: command, in: projectURL)
        let duration = Date().timeIntervalSince(startTime)
        let diagnostics = XcodeBuildService.parseCompilerDiagnostics(from: runResult.output)

        return BuildExecutionResult(
            isSuccess: runResult.exitCode == 0,
            rawOutput: runResult.output,
            diagnostics: diagnostics,
            linkerErrors: [],
            duration: duration
        )
    }

    /// Executes `swift test` with optional filter.
    public func test(
        projectURL: URL,
        filter: String? = nil
    ) async throws -> BuildExecutionResult {
        let startTime = Date()
        var command = "swift test"
        if let testFilter = filter, !testFilter.isEmpty {
            command += " --filter \(testFilter)"
        }

        let runResult = try await CommandRunner.execute(command: command, in: projectURL)
        let duration = Date().timeIntervalSince(startTime)
        let diagnostics = XcodeBuildService.parseCompilerDiagnostics(from: runResult.output)

        return BuildExecutionResult(
            isSuccess: runResult.exitCode == 0,
            rawOutput: runResult.output,
            diagnostics: diagnostics,
            linkerErrors: [],
            duration: duration
        )
    }

    /// Convenience method to build a package by string path.
    public func buildPackage(projectPath: String) async -> BuildExecutionResult? {
        let url = URL(fileURLWithPath: projectPath)
        return try? await build(projectURL: url)
    }

    /// Convenience method to run tests for a package by string path.
    public func runTests(projectPath: String) async -> BuildExecutionResult? {
        let url = URL(fileURLWithPath: projectPath)
        return try? await test(projectURL: url)
    }

    /// Audits and returns pinned dependencies by parsing Package.resolved (V1, V2, or V3).
    public func auditPinnedDependencies(projectURL: URL) throws -> [PinnedPackageDependency] {
        let resolvedURL = projectURL.appendingPathComponent("Package.resolved")
        guard FileManager.default.fileExists(atPath: resolvedURL.path) else {
            return []
        }

        let data = try Data(contentsOf: resolvedURL)
        guard let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return []
        }

        return parsePackageResolved(jsonObject: jsonObject)
    }

    private func parsePackageResolved(jsonObject: [String: Any]) -> [PinnedPackageDependency] {
        var results: [PinnedPackageDependency] = []

        // V2 & V3 schema: pins array under "pins"
        if let pins = jsonObject["pins"] as? [[String: Any]] {
            for pin in pins {
                let identity = (pin["identity"] as? String) ?? (pin["package"] as? String) ?? "unknown"
                let location = (pin["location"] as? String) ?? (pin["repositoryURL"] as? String) ?? ""
                let state = pin["state"] as? [String: Any]
                let version = state?["version"] as? String
                let revision = state?["revision"] as? String
                let branch = state?["branch"] as? String

                results.append(PinnedPackageDependency(
                    identity: identity,
                    location: location,
                    version: version,
                    revision: revision,
                    branch: branch
                ))
            }
        }
        // V1 schema: object.pins
        else if let object = jsonObject["object"] as? [String: Any],
                let pins = object["pins"] as? [[String: Any]] {
            for pin in pins {
                let package = (pin["package"] as? String) ?? "unknown"
                let repositoryURL = (pin["repositoryURL"] as? String) ?? ""
                let state = pin["state"] as? [String: Any]
                let version = state?["version"] as? String
                let revision = state?["revision"] as? String
                let branch = state?["branch"] as? String

                results.append(PinnedPackageDependency(
                    identity: package,
                    location: repositoryURL,
                    version: version,
                    revision: revision,
                    branch: branch
                ))
            }
        }

        return results
    }
}
