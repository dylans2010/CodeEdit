//
//  AgenticGitTools.swift
//  CodeEdit
//

import Foundation

public enum GitRunner {
    public static func run(arguments: [String], in directory: URL) async throws -> (output: String, exitCode: Int32) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = arguments
        process.currentDirectoryURL = directory

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        try process.run()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""
        return (output.trimmingCharacters(in: .whitespacesAndNewlines), process.terminationStatus)
    }
}

// MARK: - 26. GitStatus
public struct GitStatusTool: ExecutableTool {
    public let name = "GitStatus"
    public let description = "Returns clean/dirty state, branch name, staged, unstaged, and untracked files."
    public var parametersSchema: ToolParametersSchema { ToolParametersSchema() }
    public func execute(arguments: [String: Any], context: ToolExecutionContext) async throws -> ToolResult {
        let res = try await GitRunner.run(arguments: ["status", "--porcelain=v2", "-b"], in: context.projectRootURL)
        return .success(res.output)
    }
}

// MARK: - 27. GitAdd
public struct GitAddTool: ExecutableTool {
    public let name = "GitAdd"
    public let description = "Stages specified files or all."
    public var parametersSchema: ToolParametersSchema {
        ToolParametersSchema(properties: [
            "files": ToolParameterProperty(type: "array", description: "List of relative file paths or ['.']")
        ], required: ["files"])
    }
    public func execute(arguments: [String: Any], context: ToolExecutionContext) async throws -> ToolResult {
        guard let files = arguments["files"] as? [String] else { return .failure("Missing 'files'") }
        let res = try await GitRunner.run(arguments: ["add"] + files, in: context.projectRootURL)
        return res.exitCode == 0 ? .success("Staged \(files.joined(separator: ", "))") : .failure(res.output)
    }
}

// MARK: - 28. GitCommitTool
public struct GitCommitTool: ExecutableTool {
    public let name = "GitCommitTool"
    public let description = "Commits staged changes with a commit message."
    public var parametersSchema: ToolParametersSchema {
        ToolParametersSchema(properties: [
            "message": ToolParameterProperty(type: "string", description: "Commit message")
        ], required: ["message"])
    }
    public func execute(arguments: [String: Any], context: ToolExecutionContext) async throws -> ToolResult {
        guard let message = arguments["message"] as? String else { return .failure("Missing commit message") }
        let res = try await GitRunner.run(arguments: ["commit", "-m", message], in: context.projectRootURL)
        return res.exitCode == 0 ? .success(res.output) : .failure(res.output)
    }
}

// MARK: - 29. GitDiff
public struct GitDiffTool: ExecutableTool {
    public let name = "GitDiff"
    public let description = "Returns unified diff string."
    public var parametersSchema: ToolParametersSchema {
        ToolParametersSchema(properties: [
            "staged": ToolParameterProperty(type: "boolean", description: "Diff staged changes"),
            "filePath": ToolParameterProperty(type: "string", description: "Optional specific file")
        ])
    }
    public func execute(arguments: [String: Any], context: ToolExecutionContext) async throws -> ToolResult {
        var args = ["diff"]
        if (arguments["staged"] as? Bool) == true { args.append("--staged") }
        if let path = arguments["filePath"] as? String { args.append(path) }
        let res = try await GitRunner.run(arguments: args, in: context.projectRootURL)
        return .success(res.output)
    }
}

// MARK: - 30. GitLog
public struct GitLogTool: ExecutableTool {
    public let name = "GitLog"
    public let description = "Returns commit history."
    public var parametersSchema: ToolParametersSchema {
        ToolParametersSchema(properties: [
            "maxCount": ToolParameterProperty(type: "integer", description: "Max commits to retrieve")
        ])
    }
    public func execute(arguments: [String: Any], context: ToolExecutionContext) async throws -> ToolResult {
        let count = (arguments["maxCount"] as? Int) ?? 10
        let res = try await GitRunner.run(arguments: ["log", "-n", "\(count)", "--oneline"], in: context.projectRootURL)
        return .success(res.output)
    }
}

// MARK: - 31. GitBranchTool
public struct GitBranchTool: ExecutableTool {
    public let name = "GitBranchTool"
    public let description = "Manages git branches (list, create, delete)."
    public var parametersSchema: ToolParametersSchema {
        ToolParametersSchema(properties: [
            "action": ToolParameterProperty(type: "string", description: "list, create, delete"),
            "name": ToolParameterProperty(type: "string", description: "Branch name")
        ], required: ["action"])
    }
    public func execute(arguments: [String: Any], context: ToolExecutionContext) async throws -> ToolResult {
        let action = (arguments["action"] as? String) ?? "list"
        let branchName = arguments["name"] as? String
        var args = ["branch"]
        if action == "create", let name = branchName { args.append(name) }
        else if action == "delete", let name = branchName { args += ["-D", name] }
        let res = try await GitRunner.run(arguments: args, in: context.projectRootURL)
        return .success(res.output)
    }
}

// MARK: - 32. GitCheckout
public struct GitCheckoutTool: ExecutableTool {
    public let name = "GitCheckout"
    public let description = "Switches branches or restores files."
    public var parametersSchema: ToolParametersSchema {
        ToolParametersSchema(properties: [
            "branchOrCommit": ToolParameterProperty(type: "string", description: "Target branch or commit hash"),
            "createBranch": ToolParameterProperty(type: "boolean", description: "Create new branch (-b)")
        ], required: ["branchOrCommit"])
    }
    public func execute(arguments: [String: Any], context: ToolExecutionContext) async throws -> ToolResult {
        guard let target = arguments["branchOrCommit"] as? String else { return .failure("Missing target") }
        let create = (arguments["createBranch"] as? Bool) ?? false
        var args = ["checkout"]
        if create { args.append("-b") }
        args.append(target)
        let res = try await GitRunner.run(arguments: args, in: context.projectRootURL)
        return res.exitCode == 0 ? .success(res.output) : .failure(res.output)
    }
}

// MARK: - 33. GitPull
public struct GitPullTool: ExecutableTool {
    public let name = "GitPull"
    public let description = "Pulls commits from remote repository."
    public var parametersSchema: ToolParametersSchema {
        ToolParametersSchema(properties: [
            "remote": ToolParameterProperty(type: "string", description: "Remote name (default origin)"),
            "branch": ToolParameterProperty(type: "string", description: "Remote branch"),
            "rebase": ToolParameterProperty(type: "boolean", description: "Use rebase")
        ])
    }
    public func execute(arguments: [String: Any], context: ToolExecutionContext) async throws -> ToolResult {
        var args = ["pull"]
        if (arguments["rebase"] as? Bool) == true { args.append("--rebase") }
        if let rem = arguments["remote"] as? String { args.append(rem) }
        if let br = arguments["branch"] as? String { args.append(br) }
        let res = try await GitRunner.run(arguments: args, in: context.projectRootURL)
        return .success(res.output)
    }
}

// MARK: - 34. GitPush
public struct GitPushTool: ExecutableTool {
    public let name = "GitPush"
    public let description = "Pushes local commits to remote repository."
    public var parametersSchema: ToolParametersSchema {
        ToolParametersSchema(properties: [
            "remote": ToolParameterProperty(type: "string", description: "Remote name (default origin)"),
            "branch": ToolParameterProperty(type: "string", description: "Remote branch"),
            "force": ToolParameterProperty(type: "boolean", description: "Force push")
        ])
    }
    public func execute(arguments: [String: Any], context: ToolExecutionContext) async throws -> ToolResult {
        var args = ["push"]
        if (arguments["force"] as? Bool) == true { args.append("--force") }
        if let rem = arguments["remote"] as? String { args.append(rem) }
        if let br = arguments["branch"] as? String { args.append(br) }
        let res = try await GitRunner.run(arguments: args, in: context.projectRootURL)
        return .success(res.output)
    }
}

// MARK: - 35. GitMerge
public struct GitMergeTool: ExecutableTool {
    public let name = "GitMerge"
    public let description = "Merges target branch into active branch."
    public var parametersSchema: ToolParametersSchema {
        ToolParametersSchema(properties: [
            "branch": ToolParameterProperty(type: "string", description: "Branch to merge")
        ], required: ["branch"])
    }
    public func execute(arguments: [String: Any], context: ToolExecutionContext) async throws -> ToolResult {
        guard let br = arguments["branch"] as? String else { return .failure("Missing branch") }
        let res = try await GitRunner.run(arguments: ["merge", br], in: context.projectRootURL)
        return .success(res.output)
    }
}

// MARK: - 36. GitRebase
public struct GitRebaseTool: ExecutableTool {
    public let name = "GitRebase"
    public let description = "Rebases active branch onto upstream."
    public var parametersSchema: ToolParametersSchema {
        ToolParametersSchema(properties: [
            "upstream": ToolParameterProperty(type: "string", description: "Upstream branch")
        ], required: ["upstream"])
    }
    public func execute(arguments: [String: Any], context: ToolExecutionContext) async throws -> ToolResult {
        guard let up = arguments["upstream"] as? String else { return .failure("Missing upstream") }
        let res = try await GitRunner.run(arguments: ["rebase", up], in: context.projectRootURL)
        return .success(res.output)
    }
}

// MARK: - 37. GitCherryPick
public struct GitCherryPickTool: ExecutableTool {
    public let name = "GitCherryPick"
    public let description = "Cherry-picks a commit onto current branch."
    public var parametersSchema: ToolParametersSchema {
        ToolParametersSchema(properties: [
            "commitHash": ToolParameterProperty(type: "string", description: "Commit hash")
        ], required: ["commitHash"])
    }
    public func execute(arguments: [String: Any], context: ToolExecutionContext) async throws -> ToolResult {
        guard let hash = arguments["commitHash"] as? String else { return .failure("Missing commitHash") }
        let res = try await GitRunner.run(arguments: ["cherry-pick", hash], in: context.projectRootURL)
        return .success(res.output)
    }
}

// MARK: - 38. GitStash
public struct GitStashTool: ExecutableTool {
    public let name = "GitStash"
    public let description = "Manages git stashes (save, pop, apply, list, drop)."
    public var parametersSchema: ToolParametersSchema {
        ToolParametersSchema(properties: [
            "action": ToolParameterProperty(type: "string", description: "save/pop/apply/list/drop"),
            "message": ToolParameterProperty(type: "string", description: "Stash message")
        ], required: ["action"])
    }
    public func execute(arguments: [String: Any], context: ToolExecutionContext) async throws -> ToolResult {
        let action = (arguments["action"] as? String) ?? "list"
        var args = ["stash", action]
        if let msg = arguments["message"] as? String { args.append(msg) }
        let res = try await GitRunner.run(arguments: args, in: context.projectRootURL)
        return .success(res.output)
    }
}

// MARK: - 39. GitReset
public struct GitResetTool: ExecutableTool {
    public let name = "GitReset"
    public let description = "Resets HEAD to target state (soft, mixed, hard)."
    public var parametersSchema: ToolParametersSchema {
        ToolParametersSchema(properties: [
            "target": ToolParameterProperty(type: "string", description: "Target commit/HEAD"),
            "mode": ToolParameterProperty(type: "string", description: "soft/mixed/hard")
        ], required: ["target"])
    }
    public func execute(arguments: [String: Any], context: ToolExecutionContext) async throws -> ToolResult {
        guard let target = arguments["target"] as? String else { return .failure("Missing target") }
        let mode = (arguments["mode"] as? String) ?? "mixed"
        let res = try await GitRunner.run(arguments: ["reset", "--\(mode)", target], in: context.projectRootURL)
        return .success(res.output)
    }
}

// MARK: - 40. GitRevert
public struct GitRevertTool: ExecutableTool {
    public let name = "GitRevert"
    public let description = "Creates a revert commit."
    public var parametersSchema: ToolParametersSchema {
        ToolParametersSchema(properties: [
            "commitHash": ToolParameterProperty(type: "string", description: "Commit hash to revert")
        ], required: ["commitHash"])
    }
    public func execute(arguments: [String: Any], context: ToolExecutionContext) async throws -> ToolResult {
        guard let hash = arguments["commitHash"] as? String else { return .failure("Missing commitHash") }
        let res = try await GitRunner.run(arguments: ["revert", "--no-edit", hash], in: context.projectRootURL)
        return .success(res.output)
    }
}

// MARK: - 41. GitBlame
public struct GitBlameTool: ExecutableTool {
    public let name = "GitBlame"
    public let description = "Returns per-line commit hash and author attribution."
    public var parametersSchema: ToolParametersSchema {
        ToolParametersSchema(properties: [
            "filePath": ToolParameterProperty(type: "string", description: "File path")
        ], required: ["filePath"])
    }
    public func execute(arguments: [String: Any], context: ToolExecutionContext) async throws -> ToolResult {
        guard let path = arguments["filePath"] as? String else { return .failure("Missing filePath") }
        let res = try await GitRunner.run(arguments: ["blame", "-s", path], in: context.projectRootURL)
        return .success(res.output)
    }
}

// MARK: - 42. GitShow
public struct GitShowTool: ExecutableTool {
    public let name = "GitShow"
    public let description = "Shows commit metadata and unified diff."
    public var parametersSchema: ToolParametersSchema {
        ToolParametersSchema(properties: [
            "object": ToolParameterProperty(type: "string", description: "Commit hash or tag")
        ], required: ["object"])
    }
    public func execute(arguments: [String: Any], context: ToolExecutionContext) async throws -> ToolResult {
        guard let obj = arguments["object"] as? String else { return .failure("Missing object") }
        let res = try await GitRunner.run(arguments: ["show", "--stat", obj], in: context.projectRootURL)
        return .success(res.output)
    }
}

// MARK: - 43. GitTag
public struct GitTagTool: ExecutableTool {
    public let name = "GitTag"
    public let description = "Manages git tags (list, create, push, delete)."
    public var parametersSchema: ToolParametersSchema {
        ToolParametersSchema(properties: [
            "action": ToolParameterProperty(type: "string", description: "list/create/push/delete"),
            "name": ToolParameterProperty(type: "string", description: "Tag name")
        ], required: ["action"])
    }
    public func execute(arguments: [String: Any], context: ToolExecutionContext) async throws -> ToolResult {
        let action = (arguments["action"] as? String) ?? "list"
        var args = ["tag"]
        if action == "create", let name = arguments["name"] as? String { args.append(name) }
        else if action == "delete", let name = arguments["name"] as? String { args += ["-d", name] }
        let res = try await GitRunner.run(arguments: args, in: context.projectRootURL)
        return .success(res.output)
    }
}

// MARK: - 44. GitWorktreeTool
public struct GitWorktreeTool: ExecutableTool {
    public let name = "GitWorktreeTool"
    public let description = "Manages linked git worktrees."
    public var parametersSchema: ToolParametersSchema {
        ToolParametersSchema(properties: [
            "action": ToolParameterProperty(type: "string", description: "list/add/remove"),
            "path": ToolParameterProperty(type: "string", description: "Worktree path"),
            "branch": ToolParameterProperty(type: "string", description: "Target branch")
        ], required: ["action"])
    }
    public func execute(arguments: [String: Any], context: ToolExecutionContext) async throws -> ToolResult {
        let action = (arguments["action"] as? String) ?? "list"
        var args = ["worktree", action]
        if let path = arguments["path"] as? String { args.append(path) }
        if let br = arguments["branch"] as? String { args.append(br) }
        let res = try await GitRunner.run(arguments: args, in: context.projectRootURL)
        return .success(res.output)
    }
}

// MARK: - 45. GitClone
public struct GitCloneTool: ExecutableTool {
    public let name = "GitClone"
    public let description = "Clones a remote git repository."
    public var parametersSchema: ToolParametersSchema {
        ToolParametersSchema(properties: [
            "url": ToolParameterProperty(type: "string", description: "Repository URL"),
            "targetDirectory": ToolParameterProperty(type: "string", description: "Target folder")
        ], required: ["url", "targetDirectory"])
    }
    public func execute(arguments: [String: Any], context: ToolExecutionContext) async throws -> ToolResult {
        guard let url = arguments["url"] as? String,
              let target = arguments["targetDirectory"] as? String else { return .failure("Missing arguments") }
        let res = try await GitRunner.run(arguments: ["clone", url, target], in: context.projectRootURL)
        return res.exitCode == 0 ? .success("Cloned \(url) into \(target)") : .failure(res.output)
    }
}
