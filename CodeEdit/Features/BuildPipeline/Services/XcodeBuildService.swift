//
//  XcodeBuildService.swift
//  CodeEdit
//
//

import Foundation

/// Service wrapping `xcodebuild` CLI operations and diagnostic parsing.
public actor XcodeBuildService {
    public static let shared = XcodeBuildService()

    private init() {}

    /// Returns the currently active developer tools directory from `xcode-select -p`.
    public func getDeveloperDirectory() async throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/xcode-select")
        process.arguments = ["-p"]
        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        try process.run()
        process.waitUntilExit()

        let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let result = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
        return result ?? "/Applications/Xcode.app/Contents/Developer"
    }

    /// Lists available schemes for a project or workspace.
    public func listSchemes(projectURL: URL) async -> [String] {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/xcodebuild")
        process.arguments = ["-list", "-json"]
        process.currentDirectoryURL = projectURL

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()

        guard (try? process.run()) != nil else { return [] }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            // Fallback: check .xcodeproj or .xcworkspace files in directory
            var fallbackSchemes: [String] = []
            if let contents = try? FileManager.default.contentsOfDirectory(at: projectURL, includingPropertiesForKeys: nil) {
                for item in contents {
                    if item.pathExtension == "xcodeproj" || item.pathExtension == "xcworkspace" {
                        fallbackSchemes.append(item.deletingPathExtension().lastPathComponent)
                    }
                }
            }
            if fallbackSchemes.isEmpty && FileManager.default.fileExists(atPath: projectURL.appendingPathComponent("Package.swift").path) {
                fallbackSchemes.append(projectURL.lastPathComponent)
            }
            return fallbackSchemes
        }

        if let project = json["project"] as? [String: Any], let schemes = project["schemes"] as? [String] {
            return schemes
        } else if let workspace = json["workspace"] as? [String: Any], let schemes = workspace["schemes"] as? [String] {
            return schemes
        }

        return []
    }

    /// Invokes `xcodebuild` for a scheme and captures execution result.
    public func build(
        projectURL: URL,
        config: BuildConfiguration,
        onProgressUpdate: (@Sendable (String) -> Void)? = nil
    ) async throws -> BuildExecutionResult {
        let startTime = Date()
        var targetScheme = config.scheme
        if targetScheme.isEmpty {
            let schemes = await listSchemes(projectURL: projectURL)
            targetScheme = schemes.first ?? projectURL.lastPathComponent
        }

        var arguments = ["-scheme", targetScheme, "-configuration", config.configuration]

        // Robust workspace or project detection
        if projectURL.pathExtension == "xcworkspace" {
            arguments.append(contentsOf: ["-workspace", projectURL.lastPathComponent])
        } else if projectURL.pathExtension == "xcodeproj" {
            arguments.append(contentsOf: ["-project", projectURL.lastPathComponent])
        } else {
            let fileManager = FileManager.default
            let contents = (try? fileManager.contentsOfDirectory(at: projectURL, includingPropertiesForKeys: nil)) ?? []
            if let ws = contents.first(where: { $0.pathExtension == "xcworkspace" }) {
                arguments.append(contentsOf: ["-workspace", ws.lastPathComponent])
            } else if let proj = contents.first(where: { $0.pathExtension == "xcodeproj" }) {
                arguments.append(contentsOf: ["-project", proj.lastPathComponent])
            }
        }

        if let destination = config.destination, !destination.isEmpty {
            arguments.append(contentsOf: ["-destination", destination])
        }

        if let buildDir = config.buildDirectoryURL {
            arguments.append("SYMROOT=\(buildDir.path)")
        }

        arguments.append(contentsOf: ["build", "CODE_SIGNING_ALLOWED=NO"])

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/xcodebuild")
        process.arguments = arguments
        process.currentDirectoryURL = projectURL

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        let (outputData, errorData): (Data, Data) = await withTaskGroup(of: (Bool, Data).self) { group in
            group.addTask {
                let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
                return (true, data)
            }
            group.addTask {
                let data = errorPipe.fileHandleForReading.readDataToEndOfFile()
                return (false, data)
            }

            try? process.run()
            process.waitUntilExit()

            var out = Data()
            var err = Data()
            for await (isOut, data) in group {
                if isOut { out = data } else { err = data }
            }
            return (out, err)
        }

        let outString = String(data: outputData, encoding: .utf8) ?? ""
        let errString = String(data: errorData, encoding: .utf8) ?? ""
        let rawOutput = [outString, errString].filter { !$0.isEmpty }.joined(separator: "\n")
        let duration = Date().timeIntervalSince(startTime)
        let diagnostics = Self.parseCompilerDiagnostics(from: rawOutput)
        let linkerErrors = Self.parseLinkerDiagnostics(from: rawOutput)

        return BuildExecutionResult(
            isSuccess: process.terminationStatus == 0,
            rawOutput: rawOutput,
            diagnostics: diagnostics,
            linkerErrors: linkerErrors,
            duration: duration
        )
    }

    /// Invokes `xcodebuild clean`.
    public func clean(projectURL: URL, scheme: String) async throws -> BuildExecutionResult {
        let startTime = Date()
        var arguments = ["-scheme", scheme, "clean"]
        if projectURL.pathExtension == "xcworkspace" {
            arguments.append(contentsOf: ["-workspace", projectURL.lastPathComponent])
        } else if projectURL.pathExtension == "xcodeproj" {
            arguments.append(contentsOf: ["-project", projectURL.lastPathComponent])
        } else {
            let fileManager = FileManager.default
            let contents = (try? fileManager.contentsOfDirectory(at: projectURL, includingPropertiesForKeys: nil)) ?? []
            if let ws = contents.first(where: { $0.pathExtension == "xcworkspace" }) {
                arguments.append(contentsOf: ["-workspace", ws.lastPathComponent])
            } else if let proj = contents.first(where: { $0.pathExtension == "xcodeproj" }) {
                arguments.append(contentsOf: ["-project", proj.lastPathComponent])
            }
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/xcodebuild")
        process.arguments = arguments
        process.currentDirectoryURL = projectURL

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        try process.run()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()

        let rawOutput = String(data: data, encoding: .utf8) ?? ""
        let duration = Date().timeIntervalSince(startTime)

        return BuildExecutionResult(
            isSuccess: process.terminationStatus == 0,
            rawOutput: rawOutput,
            diagnostics: [],
            linkerErrors: [],
            duration: duration
        )
    }

    /// Regex parser for Clang and Swiftc compiler diagnostics:
    /// Matches both absolute and workspace-relative paths:
    /// `^(file_path):(\d+)(?::(\d+))?:\s*(error|warning|note):\s*(.+)$`
    public static func parseCompilerDiagnostics(from log: String) -> [CompilerDiagnostic] {
        var diagnostics: [CompilerDiagnostic] = []
        let pattern = #"^([^\s:][^:\r\n]+):(\d+)(?::(\d+))?:\s*(error|warning|note):\s*(.+)$"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines]) else {
            return []
        }

        let nsString = log as NSString
        let matches = regex.matches(in: log, options: [], range: NSRange(location: 0, length: nsString.length))

        for match in matches where match.numberOfRanges >= 5 {
            let path = nsString.substring(with: match.range(at: 1))
            let lineStr = nsString.substring(with: match.range(at: 2))

            var colStr = "1"
            if match.range(at: 3).location != NSNotFound {
                colStr = nsString.substring(with: match.range(at: 3))
            }

            let severityStr = nsString.substring(with: match.range(at: 4))
            let message = nsString.substring(with: match.range(at: 5))
            let fullLine = nsString.substring(with: match.range)

            let severity: DiagnosticSeverity
            switch severityStr.lowercased() {
            case "error": severity = .error
            case "warning": severity = .warning
            default: severity = .note
            }

            diagnostics.append(CompilerDiagnostic(
                filePath: path,
                lineNumber: Int(lineStr) ?? 1,
                columnOffset: Int(colStr) ?? 1,
                severity: severity,
                message: message,
                rawLogSnippet: fullLine
            ))
        }

        // Also capture non-file specific errors, e.g. "error: The scheme 'Foo' is not configured"
        let generalErrorPattern = #"^(?:error|fatal error|xcodebuild:\s*error):\s*(.+)$"#
        if let generalRegex = try? NSRegularExpression(pattern: generalErrorPattern, options: [.anchorsMatchLines, .caseInsensitive]) {
            let generalMatches = generalRegex.matches(in: log, options: [], range: NSRange(location: 0, length: nsString.length))
            for match in generalMatches where match.numberOfRanges >= 2 {
                let msg = nsString.substring(with: match.range(at: 1)).trimmingCharacters(in: .whitespacesAndNewlines)
                let snippet = nsString.substring(with: match.range)
                if !diagnostics.contains(where: { $0.message.contains(msg) }) {
                    diagnostics.append(CompilerDiagnostic(
                        filePath: "xcodebuild",
                        lineNumber: 1,
                        columnOffset: 1,
                        severity: .error,
                        message: msg,
                        rawLogSnippet: snippet
                    ))
                }
            }
        }

        return diagnostics
    }

    /// Regex parser for Linker diagnostics:
    /// `^Undefined symbols for architecture\s+(\w+):\s*"([^"]+)",\s*referenced from:`
    public static func parseLinkerDiagnostics(from log: String) -> [LinkerDiagnostic] {
        var errors: [LinkerDiagnostic] = []
        let pattern = #"Undefined symbols for architecture\s+(\w+):\s*"([^"]+)""#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return []
        }

        let nsString = log as NSString
        let matches = regex.matches(in: log, options: [], range: NSRange(location: 0, length: nsString.length))

        for match in matches where match.numberOfRanges >= 3 {
            let arch = nsString.substring(with: match.range(at: 1))
            let symbol = nsString.substring(with: match.range(at: 2))
            errors.append(LinkerDiagnostic(architecture: arch, missingSymbol: symbol))
        }

        return errors
    }
}
