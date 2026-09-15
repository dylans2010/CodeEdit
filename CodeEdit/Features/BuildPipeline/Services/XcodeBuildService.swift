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

    /// Invokes `xcodebuild` for a scheme and captures execution result.
    public func build(
        projectURL: URL,
        config: BuildConfiguration
    ) async throws -> BuildExecutionResult {
        let startTime = Date()
        var arguments = ["-scheme", config.scheme, "-configuration", config.configuration]

        // Workspace or project detection
        let workspaceURL = projectURL.appendingPathComponent("\(config.scheme).xcworkspace")
        if FileManager.default.fileExists(atPath: workspaceURL.path) {
            arguments.append(contentsOf: ["-workspace", workspaceURL.lastPathComponent])
        }

        if let destination = config.destination, !destination.isEmpty {
            arguments.append(contentsOf: ["-destination", destination])
        }

        if let buildDir = config.buildDirectoryURL {
            arguments.append("SYMROOT=\(buildDir.path)")
        }

        arguments.append("build")

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

    /// Regex parser for Clang and Swiftc compiler diagnostics:
    /// `^(/[^:]+):(\d+):(\d+):\s*(error|warning|note):\s*(.+)$`
    public static func parseCompilerDiagnostics(from log: String) -> [CompilerDiagnostic] {
        var diagnostics: [CompilerDiagnostic] = []
        let pattern = #"^(/[^:]+):(\d+):(\d+):\s*(error|warning|note):\s*(.+)$"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines]) else {
            return []
        }

        let nsString = log as NSString
        let matches = regex.matches(in: log, options: [], range: NSRange(location: 0, length: nsString.length))

        for match in matches where match.numberOfRanges >= 6 {
            let path = nsString.substring(with: match.range(at: 1))
            let lineStr = nsString.substring(with: match.range(at: 2))
            let colStr = nsString.substring(with: match.range(at: 3))
            let severityStr = nsString.substring(with: match.range(at: 4))
            let message = nsString.substring(with: match.range(at: 5))

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
                message: message
            ))
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
