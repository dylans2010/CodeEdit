//
//  AISuggestionEngine.swift
//  CodeEdit
//

import Foundation
import SwiftUI
import Combine

public struct AutocompleteContext: Sendable {
    public let preCursorLines: [String]
    public let postCursorLines: [String]
    public let languageIdentifier: String
    public let declaredImports: [String]
    public let cursorPosition: CursorPosition
}

public struct InlineSuggestion: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let text: String
    public let targetPosition: CursorPosition

    public init(id: UUID = UUID(), text: String, targetPosition: CursorPosition) {
        self.id = id
        self.text = text
        self.targetPosition = targetPosition
    }
}

@MainActor
public final class AISuggestionEngine: ObservableObject {
    public static let shared = AISuggestionEngine()

    @Published public var currentSuggestion: InlineSuggestion?
    @Published public var isGenerating: Bool = false
    @Published public var debounceInterval: TimeInterval = 0.35

    private var debounceTimer: Timer?
    private var activeRequestTask: Task<Void, Never>?

    private init() {}

    // MARK: - Context Extraction

    public func extractContext(
        from documentContent: String,
        at cursor: CursorPosition,
        language: String = "swift"
    ) -> AutocompleteContext {
        let lines = documentContent.components(separatedBy: .newlines)
        let lineIndex = min(max(cursor.line - 1, 0), lines.count)

        // Pre-cursor context: up to 80 lines preceding cursor
        let preStart = max(0, lineIndex - 80)
        let preLines = Array(lines[preStart..<lineIndex])

        // Post-cursor context: up to 30 lines following cursor
        let postEnd = min(lines.count, lineIndex + 30)
        let postLines = lineIndex < lines.count ? Array(lines[lineIndex..<postEnd]) : []

        // Extract imports
        let imports = lines.compactMap { line -> String? in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("import ") {
                return trimmed.replacingOccurrences(of: "import ", with: "")
            }
            return nil
        }

        return AutocompleteContext(
            preCursorLines: preLines,
            postCursorLines: postLines,
            languageIdentifier: language,
            declaredImports: imports,
            cursorPosition: cursor
        )
    }

    // MARK: - Trigger & Debounce

    public func notifyTyping(
        documentContent: String,
        at cursor: CursorPosition,
        language: String = "swift",
        customPredictor: (@Sendable (AutocompleteContext) async -> String?)? = nil
    ) {
        dismiss()
        debounceTimer?.invalidate()

        debounceTimer = Timer.scheduledTimer(withTimeInterval: debounceInterval, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                await self.generateSuggestion(
                    documentContent: documentContent,
                    at: cursor,
                    language: language,
                    customPredictor: customPredictor
                )
            }
        }
    }

    private func generateSuggestion(
        documentContent: String,
        at cursor: CursorPosition,
        language: String,
        customPredictor: (@Sendable (AutocompleteContext) async -> String?)?
    ) async {
        let context = extractContext(from: documentContent, at: cursor, language: language)

        isGenerating = true
        defer { isGenerating = false }

        if let custom = customPredictor {
            if let suggested = await custom(context), !suggested.isEmpty {
                self.currentSuggestion = InlineSuggestion(text: suggested, targetPosition: cursor)
            }
        } else {
            // Native fallback completion heuristics (e.g. matching closing brackets, protocol stubs)
            if let heuristic = self.heuristicSuggestion(for: context) {
                self.currentSuggestion = InlineSuggestion(text: heuristic, targetPosition: cursor)
            }
        }
    }

    private func heuristicSuggestion(for context: AutocompleteContext) -> String? {
        guard let lastLine = context.preCursorLines.last?.trimmingCharacters(in: .whitespaces) else {
            return nil
        }

        if lastLine.hasPrefix("guard let ") && !lastLine.contains("else") {
            return " else { return }"
        }
        if lastLine.hasPrefix("if ") && lastLine.hasSuffix("{") {
            return "\n    \n}"
        }
        if lastLine.hasPrefix("func ") && lastLine.hasSuffix("(") {
            return ") -> Void {\n    \n}"
        }
        return nil
    }

    // MARK: - Key Interception Actions

    /// Commits the entire suggestion (triggered by Tab).
    public func acceptFullSuggestion() -> String? {
        guard let suggestion = currentSuggestion else { return nil }
        let text = suggestion.text
        dismiss()
        return text
    }

    /// Accepts next word of suggestion (triggered by Option + RightArrow).
    public func acceptNextWord() -> (word: String, remaining: String?)? {
        guard let suggestion = currentSuggestion else { return nil }
        let components = suggestion.text.components(separatedBy: " ")
        guard let firstWord = components.first else { return nil }

        let wordToCommit = firstWord + (components.count > 1 ? " " : "")
        let remaining = components.dropFirst().joined(separator: " ")

        if remaining.isEmpty {
            dismiss()
            return (wordToCommit, nil)
        } else {
            currentSuggestion = InlineSuggestion(
                text: remaining,
                targetPosition: CursorPosition(
                    line: suggestion.targetPosition.line,
                    column: suggestion.targetPosition.column + wordToCommit.count
                )
            )
            return (wordToCommit, remaining)
        }
    }

    /// Dismisses active suggestion without modifying document (triggered by Escape).
    public func dismiss() {
        debounceTimer?.invalidate()
        debounceTimer = nil
        currentSuggestion = nil
    }
}
