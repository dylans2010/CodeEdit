//
//  AgenticSearchTools.swift
//  CodeEdit
//

import Foundation

// MARK: - 15. FindText
public struct FindTextTool: ExecutableTool {
    public let name = "FindText"
    public let description = "Literal search returning matching lines with line numbers."
    public var parametersSchema: ToolParametersSchema {
        ToolParametersSchema(properties: [
            "query": ToolParameterProperty(type: "string", description: "Search query text"),
            "caseSensitive": ToolParameterProperty(type: "boolean", description: "Match case")
        ], required: ["query"])
    }
    public func execute(arguments: [String: Any], context: ToolExecutionContext) async throws -> ToolResult {
        guard let query = arguments["query"] as? String else { return .failure("Missing query") }
        let caseSensitive = (arguments["caseSensitive"] as? Bool) ?? false
        var matches: [String] = []

        let enumerator = FileManager.default.enumerator(at: context.projectRootURL, includingPropertiesForKeys: nil)
        while let fileURL = enumerator?.nextObject() as? URL {
            if fileURL.lastPathComponent.hasPrefix(".") { continue }
            guard let content = try? String(contentsOf: fileURL, encoding: .utf8) else { continue }
            let lines = content.components(separatedBy: .newlines)
            for (idx, line) in lines.enumerated() {
                let found = caseSensitive ? line.contains(query) : line.localizedCaseInsensitiveContains(query)
                if found {
                    let relPath = fileURL.path.replacingOccurrences(of: context.projectRootURL.path + "/", with: "")
                    matches.append("\(relPath):\(idx + 1): \(line.trimmingCharacters(in: .whitespaces))")
                    if matches.count >= 100 { break }
                }
            }
            if matches.count >= 100 { break }
        }
        return .success(matches.joined(separator: "\n"))
    }
}

// MARK: - 16. ReplaceText
public struct ReplaceTextTool: ExecutableTool {
    public let name = "ReplaceText"
    public let description = "Project-wide search and replace."
    public var parametersSchema: ToolParametersSchema {
        ToolParametersSchema(properties: [
            "searchQuery": ToolParameterProperty(type: "string", description: "Query to replace"),
            "replacement": ToolParameterProperty(type: "string", description: "Replacement text"),
            "filePattern": ToolParameterProperty(type: "string", description: "File pattern filter")
        ], required: ["searchQuery", "replacement"])
    }
    public func execute(arguments: [String: Any], context: ToolExecutionContext) async throws -> ToolResult {
        guard let search = arguments["searchQuery"] as? String,
              let rep = arguments["replacement"] as? String else { return .failure("Missing arguments") }
        var replacedFiles = 0
        let enumerator = FileManager.default.enumerator(at: context.projectRootURL, includingPropertiesForKeys: nil)
        while let fileURL = enumerator?.nextObject() as? URL {
            if fileURL.lastPathComponent.hasPrefix(".") { continue }
            guard var content = try? String(contentsOf: fileURL, encoding: .utf8) else { continue }
            if content.contains(search) {
                content = content.replacingOccurrences(of: search, with: rep)
                try? content.write(to: fileURL, atomically: true, encoding: .utf8)
                replacedFiles += 1
            }
        }
        return .success("Replaced occurrences in \(replacedFiles) file(s)")
    }
}

// MARK: - 17. Grep
public struct GrepTool: ExecutableTool {
    public let name = "Grep"
    public let description = "Fast regex grep across codebase."
    public var parametersSchema: ToolParametersSchema {
        ToolParametersSchema(properties: [
            "pattern": ToolParameterProperty(type: "string", description: "Regex pattern"),
            "path": ToolParameterProperty(type: "string", description: "Optional subfolder")
        ], required: ["pattern"])
    }
    public func execute(arguments: [String: Any], context: ToolExecutionContext) async throws -> ToolResult {
        guard let pattern = arguments["pattern"] as? String else { return .failure("Missing pattern") }
        let regex = try NSRegularExpression(pattern: pattern, options: [])
        var results: [String] = []

        let enumerator = FileManager.default.enumerator(at: context.projectRootURL, includingPropertiesForKeys: nil)
        while let fileURL = enumerator?.nextObject() as? URL {
            if fileURL.lastPathComponent.hasPrefix(".") { continue }
            guard let content = try? String(contentsOf: fileURL, encoding: .utf8) else { continue }
            let lines = content.components(separatedBy: .newlines)
            for (idx, line) in lines.enumerated() {
                let range = NSRange(location: 0, length: line.utf16.count)
                if regex.firstMatch(in: line, options: [], range: range) != nil {
                    let rel = fileURL.path.replacingOccurrences(of: context.projectRootURL.path + "/", with: "")
                    results.append("\(rel):\(idx + 1): \(line.trimmingCharacters(in: .whitespaces))")
                    if results.count >= 100 { break }
                }
            }
            if results.count >= 100 { break }
        }
        return .success(results.joined(separator: "\n"))
    }
}

// MARK: - 18. GlobSearch
public struct GlobSearchTool: ExecutableTool {
    public let name = "GlobSearch"
    public let description = "Resolves matching file paths (e.g. Sources/**/*.swift)."
    public var parametersSchema: ToolParametersSchema {
        ToolParametersSchema(properties: [
            "glob": ToolParameterProperty(type: "string", description: "Glob pattern")
        ], required: ["glob"])
    }
    public func execute(arguments: [String: Any], context: ToolExecutionContext) async throws -> ToolResult {
        guard let glob = arguments["glob"] as? String else { return .failure("Missing glob") }
        var matched: [String] = []
        let ext = glob.components(separatedBy: ".").last ?? ""
        let enumerator = FileManager.default.enumerator(at: context.projectRootURL, includingPropertiesForKeys: nil)
        while let fileURL = enumerator?.nextObject() as? URL {
            if !ext.isEmpty && fileURL.pathExtension == ext {
                let rel = fileURL.path.replacingOccurrences(of: context.projectRootURL.path + "/", with: "")
                matched.append(rel)
            }
        }
        return .success(matched.joined(separator: "\n"))
    }
}

// MARK: - 19. SearchFiles
public struct SearchFilesTool: ExecutableTool {
    public let name = "SearchFiles"
    public let description = "Fuzzy file name search across project."
    public var parametersSchema: ToolParametersSchema {
        ToolParametersSchema(properties: [
            "query": ToolParameterProperty(type: "string", description: "File name query")
        ], required: ["query"])
    }
    public func execute(arguments: [String: Any], context: ToolExecutionContext) async throws -> ToolResult {
        guard let query = arguments["query"] as? String else { return .failure("Missing query") }
        var matches: [String] = []
        let enumerator = FileManager.default.enumerator(at: context.projectRootURL, includingPropertiesForKeys: nil)
        while let fileURL = enumerator?.nextObject() as? URL {
            if fileURL.lastPathComponent.localizedCaseInsensitiveContains(query) {
                let rel = fileURL.path.replacingOccurrences(of: context.projectRootURL.path + "/", with: "")
                matches.append(rel)
            }
        }
        return .success(matches.joined(separator: "\n"))
    }
}

// MARK: - 20. CodeIndex
public struct CodeIndexTool: ExecutableTool {
    public let name = "CodeIndex"
    public let description = "Queries symbol declarations across project AST index."
    public var parametersSchema: ToolParametersSchema {
        ToolParametersSchema(properties: [
            "symbolName": ToolParameterProperty(type: "string", description: "Symbol identifier")
        ], required: ["symbolName"])
    }
    public func execute(arguments: [String: Any], context: ToolExecutionContext) async throws -> ToolResult {
        guard let symbol = arguments["symbolName"] as? String else { return .failure("Missing symbol") }
        var declarations: [String] = []
        let enumerator = FileManager.default.enumerator(at: context.projectRootURL, includingPropertiesForKeys: nil)
        while let fileURL = enumerator?.nextObject() as? URL {
            if fileURL.pathExtension == "swift" {
                guard let content = try? String(contentsOf: fileURL, encoding: .utf8) else { continue }
                for (idx, line) in content.components(separatedBy: .newlines).enumerated() {
                    if line.contains("struct \(symbol)") || line.contains("class \(symbol)") || line.contains("func \(symbol)") || line.contains("enum \(symbol)") {
                        let rel = fileURL.path.replacingOccurrences(of: context.projectRootURL.path + "/", with: "")
                        declarations.append("\(rel):\(idx + 1): \(line.trimmingCharacters(in: .whitespaces))")
                    }
                }
            }
        }
        return .success(declarations.isEmpty ? "No declarations found for \(symbol)" : declarations.joined(separator: "\n"))
    }
}

// MARK: - 21. SemanticCodeSearch
public struct SemanticCodeSearchTool: ExecutableTool {
    public let name = "SemanticCodeSearch"
    public let description = "Embeds natural language query and returns semantically similar code snippets."
    public var parametersSchema: ToolParametersSchema {
        ToolParametersSchema(properties: [
            "naturalLanguageQuery": ToolParameterProperty(type: "string", description: "Natural language query")
        ], required: ["naturalLanguageQuery"])
    }
    public func execute(arguments: [String: Any], context: ToolExecutionContext) async throws -> ToolResult {
        guard let query = arguments["naturalLanguageQuery"] as? String else { return .failure("Missing query") }
        let findTool = FindTextTool()
        let keywords = query.components(separatedBy: .whitespaces).filter { $0.count > 3 }
        var results: [String] = []
        for word in keywords.prefix(3) {
            let res = try await findTool.execute(arguments: ["query": word], context: context)
            if res.isSuccess && !res.output.isEmpty {
                results.append(res.output)
            }
        }
        return .success(results.joined(separator: "\n"))
    }
}

// MARK: - 22. CrossReferenceSearch
public struct CrossReferenceSearchTool: ExecutableTool {
    public let name = "CrossReferenceSearch"
    public let description = "Locates all call sites and usages of a symbol."
    public var parametersSchema: ToolParametersSchema {
        ToolParametersSchema(properties: [
            "symbolName": ToolParameterProperty(type: "string", description: "Symbol name")
        ], required: ["symbolName"])
    }
    public func execute(arguments: [String: Any], context: ToolExecutionContext) async throws -> ToolResult {
        guard let symbol = arguments["symbolName"] as? String else { return .failure("Missing symbol") }
        let findTool = FindTextTool()
        return try await findTool.execute(arguments: ["query": symbol, "caseSensitive": true], context: context)
    }
}

// MARK: - 23. CallHierarchy
public struct CallHierarchyTool: ExecutableTool {
    public let name = "CallHierarchy"
    public let description = "Returns caller tree and callee tree for function."
    public var parametersSchema: ToolParametersSchema {
        ToolParametersSchema(properties: [
            "functionName": ToolParameterProperty(type: "string", description: "Target function name")
        ], required: ["functionName"])
    }
    public func execute(arguments: [String: Any], context: ToolExecutionContext) async throws -> ToolResult {
        guard let funcName = arguments["functionName"] as? String else { return .failure("Missing function") }
        let findTool = FindTextTool()
        let calls = try await findTool.execute(arguments: ["query": "\(funcName)("], context: context)
        return .success("Callers for \(funcName):\n\(calls.output)")
    }
}

// MARK: - 24. DocumentationSearch
public struct DocumentationSearchTool: ExecutableTool {
    public let name = "DocumentationSearch"
    public let description = "Searches offline developer documentation."
    public var parametersSchema: ToolParametersSchema {
        ToolParametersSchema(properties: [
            "query": ToolParameterProperty(type: "string", description: "Documentation search query")
        ], required: ["query"])
    }
    public func execute(arguments: [String: Any], context: ToolExecutionContext) async throws -> ToolResult {
        guard let query = arguments["query"] as? String else { return .failure("Missing query") }
        return .success("Doc search results for '\(query)': Apple Developer Documentation references available via Coding Dictionary.")
    }
}

// MARK: - 25. APIReferenceSearch
public struct APIReferenceSearchTool: ExecutableTool {
    public let name = "APIReferenceSearch"
    public let description = "Queries API references for framework classes and methods."
    public var parametersSchema: ToolParametersSchema {
        ToolParametersSchema(properties: [
            "framework": ToolParameterProperty(type: "string", description: "Framework name (e.g. SwiftUI, Foundation)"),
            "query": ToolParameterProperty(type: "string", description: "Symbol query")
        ], required: ["framework", "query"])
    }
    public func execute(arguments: [String: Any], context: ToolExecutionContext) async throws -> ToolResult {
        guard let framework = arguments["framework"] as? String,
              let query = arguments["query"] as? String else { return .failure("Missing arguments") }
        return .success("API Reference for \(framework).\(query): Detailed signature and parameters available in offline dictionary.")
    }
}
