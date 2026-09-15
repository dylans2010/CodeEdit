//
//  GitPorcelainService.swift
//  CodeEdit
//
//

import Foundation

/// Git service utilizing --porcelain=v2 for deterministic status tracking and hunk staging.
public actor GitPorcelainService {
    /// Shared singleton instance of GitPorcelainService.
    public static let shared = GitPorcelainService()

    private init() {}

    /// Executes `git status --porcelain=v2` and parses output into structured entries.
    public func getStatus(projectURL: URL) async throws -> [GitPorcelainEntry] {
        let result = try await CommandRunner.execute(command: "git status --porcelain=v2", in: projectURL)
        guard result.exitCode == 0 else {
            return []
        }

        var entries: [GitPorcelainEntry] = []
        let lines = result.output.components(separatedBy: .newlines)

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }

            // Ordinary changed entry: "1 <XY> sub <mH> <mI> <mW> <hH> <hI> <path>"
            if trimmed.hasPrefix("1 ") {
                let parts = trimmed.components(separatedBy: " ")
                if parts.count >= 9 {
                    let xyCode = parts[1]
                    let staged = String(xyCode.prefix(1))
                    let unstaged = String(xyCode.suffix(1))
                    let filePath = parts[8...].joined(separator: " ")
                    entries.append(GitPorcelainEntry(stagedStatus: staged, unstagedStatus: unstaged, path: filePath))
                }
            }
            // Renamed or copied entry: "2 <XY> ... <path>\t<origPath>"
            else if trimmed.hasPrefix("2 ") {
                let tabParts = trimmed.components(separatedBy: "\t")
                let headerParts = tabParts[0].components(separatedBy: " ")
                if headerParts.count >= 2 {
                    let xyCode = headerParts[1]
                    let staged = String(xyCode.prefix(1))
                    let unstaged = String(xyCode.suffix(1))
                    let filePath = headerParts.last ?? ""
                    let origPath = tabParts.count > 1 ? tabParts[1] : nil
                    entries.append(GitPorcelainEntry(
                        stagedStatus: staged,
                        unstagedStatus: unstaged,
                        path: filePath,
                        originalPath: origPath
                    ))
                }
            }
            // Untracked entry: "? <path>"
            else if trimmed.hasPrefix("? ") {
                let filePath = String(trimmed.dropFirst(2))
                entries.append(GitPorcelainEntry(stagedStatus: "?", unstagedStatus: "?", path: filePath))
            }
        }

        return entries
    }

    /// Stages a single diff hunk using `git apply --cached -`.
    public func stageDiffHunk(hunkPatch: String, projectURL: URL) async throws {
        let tempPatchURL = projectURL.appendingPathComponent(".git/TEMP_HUNK.patch")
        try hunkPatch.write(to: tempPatchURL, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: tempPatchURL) }

        let command = "git apply --cached \"\(tempPatchURL.path)\""
        let result = try await CommandRunner.execute(command: command, in: projectURL)

        guard result.exitCode == 0 else {
            throw NSError(
                domain: "GitPorcelainService",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to stage hunk:\n\(result.output)"]
            )
        }
    }

    /// Discards changes for a file.
    public func discardChanges(filePath: String, projectURL: URL) async throws {
        _ = try await CommandRunner.execute(command: "git checkout -- \"\(filePath)\"", in: projectURL)
        _ = try await CommandRunner.execute(command: "git clean -f \"\(filePath)\"", in: projectURL)
    }

    /// Executes an arbitrary Git command in the given repository directory.
    @discardableResult
    public func execute(repositoryURL: URL, arguments: [String]) async throws -> String {
        let argsString = arguments.map { "\"\($0)\"" }.joined(separator: " ")
        let result = try await CommandRunner.execute(command: "git \(argsString)", in: repositoryURL)
        return result.output
    }

    /// Convenience runner for Git commands with optional repository URL.
    @discardableResult
    public func runGit(arguments: [String], repositoryURL: URL? = nil) async throws -> String {
        let repo = repositoryURL ?? URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        return try await execute(repositoryURL: repo, arguments: arguments)
    }
}
