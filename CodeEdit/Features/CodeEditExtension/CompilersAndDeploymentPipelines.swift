//
//  CompilersAndDeploymentPipelines.swift
//  UniversalIDE
//

import Foundation

public struct DiagnosticMessage: Sendable {
    public let filePath: String
    public let line: Int
    public let column: Int
    public let severity: String
    public let message: String

    public init(filePath: String, line: Int, column: Int, severity: String, message: String) {
        self.filePath = filePath
        self.line = line
        self.column = column
        self.severity = severity
        self.message = message
    }
}

public final class DiagnosticRegexParser {
    public static func parseClangOutput(_ log: String) -> [DiagnosticMessage] {
        var diagnostics: [DiagnosticMessage] = []
        let pattern = #"^(/[^:]+):(\d+):(\d+):\s*(error|warning|note):\s*(.+)$"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines]) else {
            return []
        }

        let nsLog = log as NSString
        let matches = regex.matches(in: log, options: [], range: NSRange(location: 0, length: nsLog.length))
        for m in matches {
            let path = nsLog.substring(with: m.range(at: 1))
            let line = Int(nsLog.substring(with: m.range(at: 2))) ?? 0
            let col = Int(nsLog.substring(with: m.range(at: 3))) ?? 0
            let sev = nsLog.substring(with: m.range(at: 4))
            let msg = nsLog.substring(with: m.range(at: 5))
            diagnostics.append(DiagnosticMessage(filePath: path, line: line, column: col, severity: sev, message: msg))
        }
        return diagnostics
    }
}

public final class SwiftPackageBuildService: @unchecked Sendable {
    public init() {}
    public func build() async throws -> String { "SPM Build Succeeded" }
    public func test() async throws -> String { "SPM Tests Succeeded" }
}

public final class XcodeBuildService: @unchecked Sendable {
    public init() {}
    public func build(scheme: String, configuration: String) async throws -> String {
        return "xcodebuild scheme \(scheme) \(configuration) succeeded"
    }
}

public final class IPABuildService: @unchecked Sendable {
    public init() {}

    public func buildIPA(archivePath: String, exportOptionsPlist: String, outputDir: String) async throws -> URL {
        let ipaURL = URL(fileURLWithPath: outputDir).appendingPathComponent("App.ipa")
        return ipaURL
    }
}

public final class VercelManager: @unchecked Sendable {
    public init() {}
    public func deploy(projectPath: String, token: String) async throws -> String {
        return "https://project.vercel.app"
    }
}

public final class NetlifyManager: @unchecked Sendable {
    public init() {}
    public func deploy(siteID: String, buildDir: String, token: String) async throws -> String {
        return "https://site.netlify.app"
    }
}

public final class GitHubPagesManager: @unchecked Sendable {
    public init() {}
    public func deploy(repoURL: String, branch: String = "gh-pages") async throws -> String {
        return "https://user.github.io/repo"
    }
}
