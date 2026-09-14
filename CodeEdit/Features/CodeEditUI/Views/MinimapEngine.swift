//
//  MinimapEngine.swift
//  UniversalIDE
//

import SwiftUI
import Foundation

public enum DiagnosticSeverity: String, Codable, Sendable {
    case error
    case warning
    case info
}

public struct MinimapDiagnosticBadge: Identifiable, Sendable {
    public let id: UUID
    public let line: Int
    public let severity: DiagnosticSeverity
    public let message: String

    public init(id: UUID = UUID(), line: Int, severity: DiagnosticSeverity, message: String) {
        self.id = id
        self.line = line
        self.severity = severity
        self.message = message
    }
}

public enum GitGutterStatus: String, Codable, Sendable {
    case added
    case modified
    case deleted
}

public struct MinimapGitChange: Identifiable, Sendable {
    public let id: UUID
    public let line: Int
    public let status: GitGutterStatus

    public init(id: UUID = UUID(), line: Int, status: GitGutterStatus) {
        self.id = id
        self.line = line
        self.status = status
    }
}

public struct ASTFoldedRange: Identifiable, Codable, Sendable, Hashable {
    public var id: String { "\(startLine)-\(endLine)" }
    public let startLine: Int
    public let endLine: Int

    public init(startLine: Int, endLine: Int) {
        self.startLine = startLine
        self.endLine = endLine
    }
}

public final class ASTFoldingAnalyzer: @unchecked Sendable {
    public init() {}

    public func analyzeScopes(content: String) -> [ASTFoldedRange] {
        var ranges: [ASTFoldedRange] = []
        let lines = content.components(separatedBy: .newlines)
        var stack: [(line: Int, char: Character)] = []

        for (idx, line) in lines.enumerated() {
            let lineNumber = idx + 1
            for char in line {
                if char == "{" || char == "(" || char == "[" {
                    stack.append((line: lineNumber, char: char))
                } else if char == "}" || char == ")" || char == "]" {
                    if let top = stack.last {
                        let matches = (top.char == "{" && char == "}") ||
                                      (top.char == "(" && char == ")") ||
                                      (top.char == "[" && char == "]")
                        if matches {
                            stack.removeLast()
                            if lineNumber > top.line {
                                ranges.append(ASTFoldedRange(startLine: top.line, endLine: lineNumber))
                            }
                        }
                    }
                }
            }
        }
        return ranges
    }
}

@MainActor
public final class AISuggestionEngine: ObservableObject {
    public static let shared = AISuggestionEngine()

    @Published public var suggestedText: String = ""
    @Published public var isVisible: Bool = false

    private var debounceTimer: Timer?

    public init() {}

    public func triggerAutocomplete(content: String, cursorLine: Int, cursorColumn: Int, language: String) {
        debounceTimer?.invalidate()
        debounceTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { [weak self] _ in
            Task { @MainActor in
                let lines = content.components(separatedBy: .newlines)
                let startLine = max(0, cursorLine - 80)
                let endLine = min(lines.count, cursorLine + 30)

                let preContext = lines[startLine..<min(cursorLine, lines.count)].joined(separator: "\n")
                let postContext = cursorLine < lines.count ? lines[cursorLine..<endLine].joined(separator: "\n") : ""

                // Speculative AI ghost suggestion logic
                if preContext.contains("func ") && !preContext.contains("return") {
                    self?.suggestedText = " {\n    // AI suggested implementation\n}"
                    self?.isVisible = true
                } else {
                    self?.suggestedText = ""
                    self?.isVisible = false
                }
            }
        }
    }

    public func acceptSuggestion() -> String {
        let text = suggestedText
        dismiss()
        return text
    }

    public func acceptNextWord() -> String {
        let words = suggestedText.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: false)
        if words.count > 0 {
            let word = String(words[0]) + " "
            if words.count > 1 {
                suggestedText = String(words[1])
            } else {
                dismiss()
            }
            return word
        }
        dismiss()
        return ""
    }

    public func dismiss() {
        debounceTimer?.invalidate()
        suggestedText = ""
        isVisible = false
    }
}
