//
//  BuildPipelineModels.swift
//  CodeEdit
//
//

import Foundation

/// Severity level for compiler diagnostics.
public enum DiagnosticSeverity: String, Codable, Sendable {
    case error
    case warning
    case note
}

/// A parsed compiler diagnostic item (Clang or Swiftc).
public struct CompilerDiagnostic: Identifiable, Codable, Sendable {
    public var id: String { "\(filePath):\(lineNumber):\(columnOffset):\(message.hashValue)" }
    public let filePath: String
    public let lineNumber: Int
    public let columnOffset: Int
    public let severity: DiagnosticSeverity
    public let message: String
    public let rawLogSnippet: String?

    public init(
        filePath: String,
        lineNumber: Int,
        columnOffset: Int,
        severity: DiagnosticSeverity,
        message: String,
        rawLogSnippet: String? = nil
    ) {
        self.filePath = filePath
        self.lineNumber = lineNumber
        self.columnOffset = columnOffset
        self.severity = severity
        self.message = message
        self.rawLogSnippet = rawLogSnippet
    }
}

/// An AI-generated fix suggestion for a compiler diagnostic.
public struct AIFixSuggestion: Identifiable, Codable, Sendable {
    public let id: UUID
    public let diagnosticId: String
    public let title: String
    public let explanation: String
    public let suggestedFixOptions: [String]
    public let codeReplacementSnippet: String?
    public let targetLineNumber: Int

    public init(
        id: UUID = UUID(),
        diagnosticId: String,
        title: String,
        explanation: String,
        suggestedFixOptions: [String] = [],
        codeReplacementSnippet: String? = nil,
        targetLineNumber: Int = 1
    ) {
        self.id = id
        self.diagnosticId = diagnosticId
        self.title = title
        self.explanation = explanation
        self.suggestedFixOptions = suggestedFixOptions
        self.codeReplacementSnippet = codeReplacementSnippet
        self.targetLineNumber = targetLineNumber
    }
}

/// A parsed linker missing-symbol diagnostic.
public struct LinkerDiagnostic: Identifiable, Codable, Sendable {
    public var id: String { "\(architecture):\(missingSymbol)" }
    public let architecture: String
    public let missingSymbol: String

    public init(architecture: String, missingSymbol: String) {
        self.architecture = architecture
        self.missingSymbol = missingSymbol
    }
}

/// Build configuration target.
public struct BuildConfiguration: Sendable {
    public let scheme: String
    public let configuration: String
    public let destination: String?
    public let buildDirectoryURL: URL?

    public init(
        scheme: String,
        configuration: String = "Debug",
        destination: String? = nil,
        buildDirectoryURL: URL? = nil
    ) {
        self.scheme = scheme
        self.configuration = configuration
        self.destination = destination
        self.buildDirectoryURL = buildDirectoryURL
    }
}

/// Build result with captured output and parsed diagnostics.
public struct BuildExecutionResult: Sendable {
    public let isSuccess: Bool
    public let rawOutput: String
    public let diagnostics: [CompilerDiagnostic]
    public let linkerErrors: [LinkerDiagnostic]
    public let duration: TimeInterval

    public init(
        isSuccess: Bool,
        rawOutput: String,
        diagnostics: [CompilerDiagnostic] = [],
        linkerErrors: [LinkerDiagnostic] = [],
        duration: TimeInterval = 0.0
    ) {
        self.isSuccess = isSuccess
        self.rawOutput = rawOutput
        self.diagnostics = diagnostics
        self.linkerErrors = linkerErrors
        self.duration = duration
    }
}

/// Signing methods for IPA export.
public enum IPASigningMethod: String, Codable, Sendable {
    case appStore = "app-store"
    case adHoc = "ad-hoc"
    case enterprise = "enterprise"
    case development = "development"
}

/// Configuration for IPA archiving and export.
public struct IPAExportConfiguration: Sendable {
    public let scheme: String
    public let signingMethod: IPASigningMethod
    public let teamID: String?
    public let outputDirectoryURL: URL

    public init(
        scheme: String,
        signingMethod: IPASigningMethod = .development,
        teamID: String? = nil,
        outputDirectoryURL: URL
    ) {
        self.scheme = scheme
        self.signingMethod = signingMethod
        self.teamID = teamID
        self.outputDirectoryURL = outputDirectoryURL
    }
}
