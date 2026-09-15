//
//  AgenticFileTools.swift
//  CodeEdit
//

import Foundation

// MARK: - 1. CreateFile
public struct CreateFileTool: ExecutableTool {
    public let name = "CreateFile"
    public let description = "Creates a new file with specified content."
    public var parametersSchema: ToolParametersSchema {
        ToolParametersSchema(properties: [
            "path": ToolParameterProperty(type: "string", description: "Relative path to file"),
            "content": ToolParameterProperty(type: "string", description: "UTF-8 content to write"),
            "overwrite": ToolParameterProperty(type: "boolean", description: "Allow overwriting existing")
        ], required: ["path", "content"])
    }
    public func execute(arguments: [String: Any], context: ToolExecutionContext) async throws -> ToolResult {
        guard let path = arguments["path"] as? String,
              let content = arguments["content"] as? String else {
            return .failure("Missing required arguments 'path' or 'content'")
        }
        let url = try PathTraversalSanitizer.sanitize(path: path, relativeTo: context.projectRootURL)
        let overwrite = (arguments["overwrite"] as? Bool) ?? false
        let fm = FileManager.default
        if fm.fileExists(atPath: url.path) && !overwrite {
            return .failure("File already exists at \(path). Set overwrite=true to replace.")
        }
        try fm.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try content.write(to: url, atomically: true, encoding: .utf8)
        return .success("Successfully created file at \(path) (\(content.count) characters)")
    }
}

// MARK: - 2. ReadFile
public struct ReadFileTool: ExecutableTool {
    public let name = "ReadFile"
    public let description = "Reads content from a file with optional line ranges."
    public var parametersSchema: ToolParametersSchema {
        ToolParametersSchema(properties: [
            "path": ToolParameterProperty(type: "string", description: "Path to file"),
            "startLine": ToolParameterProperty(type: "integer", description: "1-indexed starting line"),
            "lineCount": ToolParameterProperty(type: "integer", description: "Number of lines to read")
        ], required: ["path"])
    }
    public func execute(arguments: [String: Any], context: ToolExecutionContext) async throws -> ToolResult {
        guard let path = arguments["path"] as? String else { return .failure("Missing 'path'") }
        let url = try PathTraversalSanitizer.sanitize(path: path, relativeTo: context.projectRootURL)
        let content = try String(contentsOf: url, encoding: .utf8)
        let lines = content.components(separatedBy: .newlines)
        if let start = arguments["startLine"] as? Int {
            let startIdx = max(0, start - 1)
            let count = (arguments["lineCount"] as? Int) ?? (lines.count - startIdx)
            let slice = lines[startIdx..<min(lines.count, startIdx + count)]
            return .success(slice.joined(separator: "\n"))
        }
        return .success(content)
    }
}

// MARK: - 3. ReadMultipleFiles
public struct ReadMultipleFilesTool: ExecutableTool {
    public let name = "ReadMultipleFiles"
    public let description = "Reads multiple files in parallel."
    public var parametersSchema: ToolParametersSchema {
        ToolParametersSchema(properties: [
            "paths": ToolParameterProperty(type: "array", description: "Array of paths")
        ], required: ["paths"])
    }
    public func execute(arguments: [String: Any], context: ToolExecutionContext) async throws -> ToolResult {
        guard let paths = arguments["paths"] as? [String] else { return .failure("Missing 'paths'") }
        var results: [String: String] = [:]
        for path in paths.prefix(20) {
            if let url = try? PathTraversalSanitizer.sanitize(path: path, relativeTo: context.projectRootURL),
               let text = try? String(contentsOf: url, encoding: .utf8) {
                results[path] = text
            }
        }
        let data = (try? JSONSerialization.data(withJSONObject: results, options: .prettyPrinted)) ?? Data()
        return .success(String(data: data, encoding: .utf8) ?? "{}")
    }
}

// MARK: - 4. EditFile
public struct EditFileTool: ExecutableTool {
    public let name = "EditFile"
    public let description = "Replaces a specific target content block in a file."
    public var parametersSchema: ToolParametersSchema {
        ToolParametersSchema(properties: [
            "path": ToolParameterProperty(type: "string", description: "Path to file"),
            "targetContent": ToolParameterProperty(type: "string", description: "Exact target substring to replace"),
            "replacementContent": ToolParameterProperty(type: "string", description: "New replacement content")
        ], required: ["path", "targetContent", "replacementContent"])
    }
    public func execute(arguments: [String: Any], context: ToolExecutionContext) async throws -> ToolResult {
        guard let path = arguments["path"] as? String,
              let target = arguments["targetContent"] as? String,
              let rep = arguments["replacementContent"] as? String else {
            return .failure("Missing edit parameters")
        }
        let url = try PathTraversalSanitizer.sanitize(path: path, relativeTo: context.projectRootURL)
        var text = try String(contentsOf: url, encoding: .utf8)
        guard text.contains(target) else {
            return .failure("Target content not found in \(path)")
        }
        text = text.replacingOccurrences(of: target, with: rep)
        try text.write(to: url, atomically: true, encoding: .utf8)
        return .success("Replaced target block in \(path)")
    }
}

// MARK: - 5. WriteFile
public struct WriteFileTool: ExecutableTool {
    public let name = "WriteFile"
    public let description = "Overwrites an existing file completely."
    public var parametersSchema: ToolParametersSchema {
        ToolParametersSchema(properties: [
            "path": ToolParameterProperty(type: "string", description: "Path to file"),
            "content": ToolParameterProperty(type: "string", description: "New content")
        ], required: ["path", "content"])
    }
    public func execute(arguments: [String: Any], context: ToolExecutionContext) async throws -> ToolResult {
        guard let path = arguments["path"] as? String,
              let content = arguments["content"] as? String else { return .failure("Missing arguments") }
        let url = try PathTraversalSanitizer.sanitize(path: path, relativeTo: context.projectRootURL)
        try content.write(to: url, atomically: true, encoding: .utf8)
        return .success("Successfully overwrote \(path)")
    }
}

// MARK: - 6. CopyFile
public struct CopyFileTool: ExecutableTool {
    public let name = "CopyFile"
    public let description = "Copies a file to a new destination."
    public var parametersSchema: ToolParametersSchema {
        ToolParametersSchema(properties: [
            "sourcePath": ToolParameterProperty(type: "string", description: "Source path"),
            "destinationPath": ToolParameterProperty(type: "string", description: "Destination path")
        ], required: ["sourcePath", "destinationPath"])
    }
    public func execute(arguments: [String: Any], context: ToolExecutionContext) async throws -> ToolResult {
        guard let src = arguments["sourcePath"] as? String,
              let dst = arguments["destinationPath"] as? String else { return .failure("Missing paths") }
        let srcURL = try PathTraversalSanitizer.sanitize(path: src, relativeTo: context.projectRootURL)
        let dstURL = try PathTraversalSanitizer.sanitize(path: dst, relativeTo: context.projectRootURL)
        try FileManager.default.copyItem(at: srcURL, to: dstURL)
        return .success("Copied \(src) to \(dst)")
    }
}

// MARK: - 7. MoveFile
public struct MoveFileTool: ExecutableTool {
    public let name = "MoveFile"
    public let description = "Moves or renames a file."
    public var parametersSchema: ToolParametersSchema {
        ToolParametersSchema(properties: [
            "sourcePath": ToolParameterProperty(type: "string", description: "Source path"),
            "destinationPath": ToolParameterProperty(type: "string", description: "Destination path")
        ], required: ["sourcePath", "destinationPath"])
    }
    public func execute(arguments: [String: Any], context: ToolExecutionContext) async throws -> ToolResult {
        guard let src = arguments["sourcePath"] as? String,
              let dst = arguments["destinationPath"] as? String else { return .failure("Missing paths") }
        let srcURL = try PathTraversalSanitizer.sanitize(path: src, relativeTo: context.projectRootURL)
        let dstURL = try PathTraversalSanitizer.sanitize(path: dst, relativeTo: context.projectRootURL)
        try FileManager.default.moveItem(at: srcURL, to: dstURL)
        return .success("Moved \(src) to \(dst)")
    }
}

// MARK: - 8. DeleteFile
public struct DeleteFileTool: ExecutableTool {
    public let name = "DeleteFile"
    public let description = "Deletes a file from the workspace."
    public var parametersSchema: ToolParametersSchema {
        ToolParametersSchema(properties: [
            "path": ToolParameterProperty(type: "string", description: "Path to file"),
            "moveToTrash": ToolParameterProperty(type: "boolean", description: "Move to system trash")
        ], required: ["path"])
    }
    public func execute(arguments: [String: Any], context: ToolExecutionContext) async throws -> ToolResult {
        guard let path = arguments["path"] as? String else { return .failure("Missing path") }
        let url = try PathTraversalSanitizer.sanitize(path: path, relativeTo: context.projectRootURL)
        let trash = (arguments["moveToTrash"] as? Bool) ?? false
        if trash {
            try FileManager.default.trashItem(at: url, resultingItemURL: nil)
            return .success("Moved \(path) to trash")
        } else {
            try FileManager.default.removeItem(at: url)
            return .success("Deleted \(path)")
        }
    }
}

// MARK: - 9. CreateDirectory
public struct CreateDirectoryTool: ExecutableTool {
    public let name = "CreateDirectory"
    public let description = "Creates a directory hierarchy."
    public var parametersSchema: ToolParametersSchema {
        ToolParametersSchema(properties: [
            "path": ToolParameterProperty(type: "string", description: "Directory path"),
            "recursive": ToolParameterProperty(type: "boolean", description: "Create parents")
        ], required: ["path"])
    }
    public func execute(arguments: [String: Any], context: ToolExecutionContext) async throws -> ToolResult {
        guard let path = arguments["path"] as? String else { return .failure("Missing path") }
        let url = try PathTraversalSanitizer.sanitize(path: path, relativeTo: context.projectRootURL)
        let rec = (arguments["recursive"] as? Bool) ?? true
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: rec)
        return .success("Created directory \(path)")
    }
}

// MARK: - 10. DeleteDirectory
public struct DeleteDirectoryTool: ExecutableTool {
    public let name = "DeleteDirectory"
    public let description = "Deletes a directory from the workspace."
    public var parametersSchema: ToolParametersSchema {
        ToolParametersSchema(properties: [
            "path": ToolParameterProperty(type: "string", description: "Path to directory"),
            "recursive": ToolParameterProperty(type: "boolean", description: "Allow recursive delete")
        ], required: ["path"])
    }
    public func execute(arguments: [String: Any], context: ToolExecutionContext) async throws -> ToolResult {
        guard let path = arguments["path"] as? String else { return .failure("Missing path") }
        let url = try PathTraversalSanitizer.sanitize(path: path, relativeTo: context.projectRootURL)
        try FileManager.default.removeItem(at: url)
        return .success("Deleted directory \(path)")
    }
}

// MARK: - 11. ListDirectory
public struct ListDirectoryTool: ExecutableTool {
    public let name = "ListDirectory"
    public let description = "Lists contents of a directory."
    public var parametersSchema: ToolParametersSchema {
        ToolParametersSchema(properties: [
            "path": ToolParameterProperty(type: "string", description: "Directory path"),
            "recursive": ToolParameterProperty(type: "boolean", description: "Recurse subdirectories"),
            "maxDepth": ToolParameterProperty(type: "integer", description: "Maximum depth")
        ], required: ["path"])
    }
    public func execute(arguments: [String: Any], context: ToolExecutionContext) async throws -> ToolResult {
        guard let path = arguments["path"] as? String else { return .failure("Missing path") }
        let url = try PathTraversalSanitizer.sanitize(path: path, relativeTo: context.projectRootURL)
        let items = try FileManager.default.contentsOfDirectory(atPath: url.path)
        return .success(items.joined(separator: "\n"))
    }
}

// MARK: - 12. DownloadFile
public struct DownloadFileTool: ExecutableTool {
    public let name = "DownloadFile"
    public let description = "Downloads a file from a remote URL."
    public var parametersSchema: ToolParametersSchema {
        ToolParametersSchema(properties: [
            "url": ToolParameterProperty(type: "string", description: "Remote URL"),
            "destinationPath": ToolParameterProperty(type: "string", description: "Local destination path")
        ], required: ["url", "destinationPath"])
    }
    public func execute(arguments: [String: Any], context: ToolExecutionContext) async throws -> ToolResult {
        guard let urlStr = arguments["url"] as? String,
              let dst = arguments["destinationPath"] as? String,
              let remoteURL = URL(string: urlStr) else { return .failure("Invalid arguments") }
        let dstURL = try PathTraversalSanitizer.sanitize(path: dst, relativeTo: context.projectRootURL)
        let (data, _) = try await URLSession.shared.data(from: remoteURL)
        try data.write(to: dstURL)
        return .success("Downloaded \(data.count) bytes to \(dst)")
    }
}

// MARK: - 13. UploadFile
public struct UploadFileTool: ExecutableTool {
    public let name = "UploadFile"
    public let description = "Uploads a local file to a remote endpoint."
    public var parametersSchema: ToolParametersSchema {
        ToolParametersSchema(properties: [
            "filePath": ToolParameterProperty(type: "string", description: "Local file path"),
            "endpoint": ToolParameterProperty(type: "string", description: "Upload endpoint")
        ], required: ["filePath", "endpoint"])
    }
    public func execute(arguments: [String: Any], context: ToolExecutionContext) async throws -> ToolResult {
        guard let path = arguments["filePath"] as? String,
              let endStr = arguments["endpoint"] as? String,
              let endURL = URL(string: endStr) else { return .failure("Invalid parameters") }
        let url = try PathTraversalSanitizer.sanitize(path: path, relativeTo: context.projectRootURL)
        let data = try Data(contentsOf: url)
        var req = URLRequest(url: endURL)
        req.httpMethod = "POST"
        req.httpBody = data
        let (_, response) = try await URLSession.shared.data(for: req)
        let code = (response as? HTTPURLResponse)?.statusCode ?? 200
        return .success("Uploaded \(data.count) bytes, response status: \(code)")
    }
}

// MARK: - 14. TreeView
public struct TreeViewTool: ExecutableTool {
    public let name = "TreeView"
    public let description = "Generates an ASCII visualization of directory tree."
    public var parametersSchema: ToolParametersSchema {
        ToolParametersSchema(properties: [
            "path": ToolParameterProperty(type: "string", description: "Root folder"),
            "maxDepth": ToolParameterProperty(type: "integer", description: "Maximum recursion depth")
        ], required: ["path"])
    }
    public func execute(arguments: [String: Any], context: ToolExecutionContext) async throws -> ToolResult {
        guard let path = arguments["path"] as? String else { return .failure("Missing path") }
        let url = try PathTraversalSanitizer.sanitize(path: path, relativeTo: context.projectRootURL)
        let depth = (arguments["maxDepth"] as? Int) ?? 3
        var output = "\(url.lastPathComponent)/\n"
        func renderTree(dir: URL, currentDepth: Int, prefix: String) {
            if currentDepth > depth { return }
            guard let contents = try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) else { return }
            for item in contents.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
                if item.lastPathComponent.hasPrefix(".") { continue }
                var isDir: ObjCBool = false
                FileManager.default.fileExists(atPath: item.path, isDirectory: &isDir)
                if isDir.boolValue {
                    output += "\(prefix)├── \(item.lastPathComponent)/\n"
                    renderTree(dir: item, currentDepth: currentDepth + 1, prefix: prefix + "│   ")
                } else {
                    output += "\(prefix)├── \(item.lastPathComponent)\n"
                }
            }
        }
        renderTree(dir: url, currentDepth: 1, prefix: "")
        return .success(output)
    }
}
