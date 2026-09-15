//
//  WorkspaceBuildManager.swift
//  CodeEdit
//
//

// swiftlint:disable line_length function_body_length

import Foundation
import Combine
import SwiftUI

/// Observable manager coordinating xcodebuild executions and workspace diagnostics for the Issues sidebar.
@MainActor
public final class WorkspaceBuildManager: ObservableObject {
    public static let shared = WorkspaceBuildManager()

    @Published public var isBuilding: Bool = false
    @Published public var currentStatus: String = "Ready to build"
    @Published public var lastResult: BuildExecutionResult?
    @Published public var diagnostics: [CompilerDiagnostic] = []
    @Published public var linkerErrors: [LinkerDiagnostic] = []
    @Published public var availableSchemes: [String] = []
    @Published public var selectedScheme: String = ""
    @Published public var selectedConfiguration: String = "Debug"
    @Published public var buildDuration: TimeInterval = 0
    @Published public var lastBuildDate: Date?

    public var errorCount: Int {
        diagnostics.filter { $0.severity == .error }.count + linkerErrors.count
    }

    public var warningCount: Int {
        diagnostics.filter { $0.severity == .warning }.count
    }

    public var noteCount: Int {
        diagnostics.filter { $0.severity == .note }.count
    }

    private init() {}

    /// Loads available schemes for the workspace URL.
    public func loadSchemes(workspaceURL: URL) async {
        let schemes = await XcodeBuildService.shared.listSchemes(projectURL: workspaceURL)
        self.availableSchemes = schemes
        if self.selectedScheme.isEmpty || !schemes.contains(self.selectedScheme) {
            self.selectedScheme = schemes.first ?? workspaceURL.lastPathComponent
        }
    }

    /// Triggers `xcodebuild` on the specified workspace project.
    public func build(workspaceURL: URL) async {
        guard !isBuilding else { return }
        isBuilding = true
        currentStatus = "Building \(selectedScheme.isEmpty ? workspaceURL.lastPathComponent : selectedScheme)..."

        if availableSchemes.isEmpty {
            await loadSchemes(workspaceURL: workspaceURL)
        }

        let config = BuildConfiguration(
            scheme: selectedScheme,
            configuration: selectedConfiguration
        )

        do {
            let result = try await XcodeBuildService.shared.build(projectURL: workspaceURL, config: config)
            self.lastResult = result
            self.diagnostics = result.diagnostics
            self.linkerErrors = result.linkerErrors
            self.buildDuration = result.duration
            self.lastBuildDate = Date()
            self.isBuilding = false

            if result.isSuccess {
                let warnMsg = warningCount > 0 ? " with \(warningCount) warning(s)" : ""
                self.currentStatus = "Build Succeeded\(warnMsg)"
            } else {
                let errs = errorCount > 0 ? "\(errorCount) error(s)" : "Issues encountered"
                self.currentStatus = "Build Failed: \(errs)"
            }
        } catch {
            self.isBuilding = false
            self.lastBuildDate = Date()
            let errMsg = error.localizedDescription
            self.currentStatus = "Build Failed"
            self.diagnostics = [CompilerDiagnostic(
                filePath: "xcodebuild",
                lineNumber: 1,
                columnOffset: 1,
                severity: .error,
                message: errMsg
            )]
        }
    }

    /// Triggers `xcodebuild clean`.
    public func clean(workspaceURL: URL) async {
        guard !isBuilding else { return }
        isBuilding = true
        currentStatus = "Cleaning build folder..."

        let scheme = selectedScheme.isEmpty ? workspaceURL.lastPathComponent : selectedScheme
        do {
            _ = try await XcodeBuildService.shared.clean(projectURL: workspaceURL, scheme: scheme)
            self.isBuilding = false
            self.currentStatus = "Clean Succeeded"
            self.diagnostics = []
            self.linkerErrors = []
            self.lastResult = nil
        } catch {
            self.isBuilding = false
            self.currentStatus = "Clean Failed: \(error.localizedDescription)"
        }
    }

    // MARK: - AI Fix Integration

    @Published public var selectedDiagnostic: CompilerDiagnostic?
    @Published public var currentAIFix: AIFixSuggestion?
    @Published public var isAnalyzingAIFix: Bool = false
    @Published public var aiFixSuccessMessage: String?

    /// Generates intelligent AI fix suggestions for a given compiler diagnostic.
    public func requestAIFix(for diagnostic: CompilerDiagnostic, workspaceURL: URL?) async {
        self.selectedDiagnostic = diagnostic
        self.isAnalyzingAIFix = true
        self.aiFixSuccessMessage = nil

        let suggestion = await AIIssueFixEngine.diagnose(diagnostic: diagnostic, workspaceURL: workspaceURL)
        self.currentAIFix = suggestion
        self.isAnalyzingAIFix = false
    }

    /// Applies an AI suggested fix directly to the source file.
    public func applyAIFix(_ suggestion: AIFixSuggestion, workspaceURL: URL?) async throws {
        guard let replacement = suggestion.codeReplacementSnippet else { return }
        guard let diagnostic = selectedDiagnostic ?? diagnostics.first(where: { $0.id == suggestion.diagnosticId }) else { return }

        let fileURL: URL
        if diagnostic.filePath.hasPrefix("/") {
            fileURL = URL(fileURLWithPath: diagnostic.filePath)
        } else if let base = workspaceURL {
            fileURL = base.appendingPathComponent(diagnostic.filePath)
        } else {
            throw NSError(domain: "AIIssueFix", code: 404, userInfo: [NSLocalizedDescriptionKey: "Invalid file path for diagnostic"])
        }

        try AIIssueFixEngine.applyCodeReplacement(
            fileURL: fileURL,
            targetLineNumber: suggestion.targetLineNumber,
            replacement: replacement
        )

        self.aiFixSuccessMessage = "Fix applied successfully to \(fileURL.lastPathComponent):\(suggestion.targetLineNumber)"

        // Re-read or re-trigger build if workspace exists
        if let ws = workspaceURL {
            Task {
                try? await Task.sleep(nanoseconds: 500_000_000)
                await self.build(workspaceURL: ws)
            }
        }
    }
}

// MARK: - AI Issue Fix Engine

public enum AIIssueFixEngine {
    /// Diagnoses a compiler error and synthesizes actionable AI fix suggestions.
    public static func diagnose(
        diagnostic: CompilerDiagnostic,
        workspaceURL: URL?
    ) async -> AIFixSuggestion {
        let fileURL: URL?
        if diagnostic.filePath.hasPrefix("/") {
            fileURL = URL(fileURLWithPath: diagnostic.filePath)
        } else if let base = workspaceURL {
            fileURL = base.appendingPathComponent(diagnostic.filePath)
        } else {
            fileURL = nil
        }

        var sourceLine: String?
        if let url = fileURL, let content = try? String(contentsOf: url, encoding: .utf8) {
            let lines = content.components(separatedBy: .newlines)
            let idx = diagnostic.lineNumber - 1
            if idx >= 0 && idx < lines.count {
                sourceLine = lines[idx]
            }
        }

        let message = diagnostic.message
        let lineCode = sourceLine?.trimmingCharacters(in: .whitespaces) ?? ""

        // 1. Cannot find in scope
        if message.contains("cannot find") && message.contains("in scope") {
            let symbolName = extractQuotedSymbol(from: message) ?? "symbol"

            if ["View", "State", "Binding", "Color", "HStack", "VStack", "ZStack", "Text", "Image", "Button", "Spacer", "Divider"].contains(symbolName) {
                return AIFixSuggestion(
                    diagnosticId: diagnostic.id,
                    title: "Missing 'import SwiftUI'",
                    explanation: "'\(symbolName)' is a SwiftUI primitive. The file is missing 'import SwiftUI'.",
                    suggestedFixOptions: [
                        "Add 'import SwiftUI' at the top of the file",
                        "Ensure the target is configured to link SwiftUI.framework"
                    ],
                    codeReplacementSnippet: "import SwiftUI\n\(sourceLine ?? "")",
                    targetLineNumber: max(1, diagnostic.lineNumber)
                )
            } else if ["NSView", "NSColor", "NSWindow", "NSApplication", "NSApp", "NSHostingView"].contains(symbolName) {
                return AIFixSuggestion(
                    diagnosticId: diagnostic.id,
                    title: "Missing 'import AppKit'",
                    explanation: "'\(symbolName)' is an AppKit type. Add 'import AppKit' to make it available.",
                    suggestedFixOptions: [
                        "Add 'import AppKit' at the top of the file",
                        "Use SwiftUI alternatives if building cross-platform"
                    ],
                    codeReplacementSnippet: "import AppKit\n\(sourceLine ?? "")",
                    targetLineNumber: max(1, diagnostic.lineNumber)
                )
            } else if ["ObservableObject", "AnyCancellable", "Published", "PassthroughSubject"].contains(symbolName) {
                return AIFixSuggestion(
                    diagnosticId: diagnostic.id,
                    title: "Missing 'import Combine'",
                    explanation: "'\(symbolName)' is provided by the Combine framework.",
                    suggestedFixOptions: [
                        "Add 'import Combine' at the top of the file",
                        "Import the module defining '\(symbolName)'"
                    ],
                    codeReplacementSnippet: "import Combine\n\(sourceLine ?? "")",
                    targetLineNumber: max(1, diagnostic.lineNumber)
                )
            }

            return AIFixSuggestion(
                diagnosticId: diagnostic.id,
                title: "Undefined Symbol '\(symbolName)'",
                explanation: "The compiler cannot find '\(symbolName)' in the current scope. It might be misspelled, private in another module, or missing an import.",
                suggestedFixOptions: [
                    "Verify the spelling of '\(symbolName)'",
                    "Import the module where '\(symbolName)' is declared",
                    "Declare '\(symbolName)' with 'let' or 'var' before using it"
                ],
                codeReplacementSnippet: nil,
                targetLineNumber: diagnostic.lineNumber
            )
        }

        // 2. Mutating member on immutable value / let constant
        if message.contains("cannot use mutating member on immutable value") || message.contains("is a 'let' constant") {
            let fixedLine = sourceLine?.replacingOccurrences(of: "let ", with: "var ")
            return AIFixSuggestion(
                diagnosticId: diagnostic.id,
                title: "Change 'let' to 'var'",
                explanation: "You are attempting to modify an immutable constant. Changing the declaration to 'var' permits mutation.",
                suggestedFixOptions: [
                    "Change 'let' to 'var' at declaration",
                    "Create a mutable local copy before mutating"
                ],
                codeReplacementSnippet: fixedLine,
                targetLineNumber: diagnostic.lineNumber
            )
        }

        // 3. Optional unwrapping required
        if message.contains("value of optional type") && message.contains("must be unwrapped") {
            let fixedLine = sourceLine != nil ? "\(sourceLine!) ?? \"\"" : nil
            return AIFixSuggestion(
                diagnosticId: diagnostic.id,
                title: "Unwrap Optional Value",
                explanation: "The variable is an Optional and cannot be used directly where a non-optional value is expected.",
                suggestedFixOptions: [
                    "Provide a fallback default using nil-coalescing ('?? <default>')",
                    "Safely unwrap using 'if let' or 'guard let'",
                    "Use optional chaining '?.' if calling a method"
                ],
                codeReplacementSnippet: fixedLine,
                targetLineNumber: diagnostic.lineNumber
            )
        }

        // 4. Concurrency & Sendable
        if message.contains("Sendable") || message.contains("concurrency") || message.contains("actor") {
            return AIFixSuggestion(
                diagnosticId: diagnostic.id,
                title: "Swift 6 Concurrency Isolation Fix",
                explanation: "Values passed across actor boundaries must conform to 'Sendable' or be isolated using '@MainActor'.",
                suggestedFixOptions: [
                    "Add '@MainActor' to the enclosing class or function",
                    "Annotate closure with '@Sendable'",
                    "Conform the model type to 'Sendable'"
                ],
                codeReplacementSnippet: sourceLine != nil ? "@MainActor \(sourceLine!)" : nil,
                targetLineNumber: diagnostic.lineNumber
            )
        }

        // 5. Type mismatch
        if message.contains("cannot convert value of type") {
            return AIFixSuggestion(
                diagnosticId: diagnostic.id,
                title: "Type Conversion Required",
                explanation: "The provided argument type does not match the parameter type expected by the function or property.",
                suggestedFixOptions: [
                    "Wrap the value in an explicit type initializer (e.g. String(...), Int(...))",
                    "Bridge or cast using 'as' if types are convertible",
                    "Update the variable definition to match expected type"
                ],
                codeReplacementSnippet: nil,
                targetLineNumber: diagnostic.lineNumber
            )
        }

        // General fallback
        return AIFixSuggestion(
            diagnosticId: diagnostic.id,
            title: "Swift Compiler Diagnostic",
            explanation: message,
            suggestedFixOptions: [
                "Inspect line \(diagnostic.lineNumber) in \(diagnostic.filePath)",
                "Review recent code changes surrounding '\(lineCode)'",
                "Ensure required dependencies and frameworks are imported"
            ],
            codeReplacementSnippet: nil,
            targetLineNumber: diagnostic.lineNumber
        )
    }

    /// Extracts text between single quotes, e.g. 'foo' in "cannot find 'foo' in scope"
    private static func extractQuotedSymbol(from text: String) -> String? {
        let pattern = #"'([^']+)'"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let ns = text as NSString
        if let match = regex.firstMatch(in: text, range: NSRange(location: 0, length: ns.length)),
           match.numberOfRanges >= 2 {
            return ns.substring(with: match.range(at: 1))
        }
        return nil
    }

    /// Replaces the target line in a source file on disk.
    public static func applyCodeReplacement(
        fileURL: URL,
        targetLineNumber: Int,
        replacement: String
    ) throws {
        let content = try String(contentsOf: fileURL, encoding: .utf8)
        var lines = content.components(separatedBy: .newlines)
        let idx = targetLineNumber - 1
        guard idx >= 0 && idx < lines.count else {
            throw NSError(domain: "AIIssueFix", code: 400, userInfo: [NSLocalizedDescriptionKey: "Target line \(targetLineNumber) out of range."])
        }

        lines[idx] = replacement
        let updatedContent = lines.joined(separator: "\n")
        try updatedContent.write(to: fileURL, atomically: true, encoding: .utf8)
    }
}
