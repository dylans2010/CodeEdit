//
//  ASTScopeDetector.swift
//  CodeEdit
//

import Foundation
import Combine

public struct FoldableScope: Identifiable, Equatable, Sendable {
    public var id: String { "\(startLine)-\(endLine)" }
    public let startLine: Int
    public let endLine: Int
    public let scopeKeyword: String?
    public var isFolded: Bool

    public init(startLine: Int, endLine: Int, scopeKeyword: String? = nil, isFolded: Bool = false) {
        self.startLine = startLine
        self.endLine = endLine
        self.scopeKeyword = scopeKeyword
        self.isFolded = isFolded
    }
}

public final class ASTScopeDetector: ObservableObject, @unchecked Sendable {
    @Published public private(set) var detectedScopes: [FoldableScope] = []
    @Published public var foldedLineRanges: Set<ClosedRange<Int>> = []

    private let lock = NSLock()

    public init() {}

    /// Analyzes lines of code and returns foldable scopes based on scope delimiters and block keywords.
    public func analyzeScopes(in source: String) -> [FoldableScope] {
        let lines = source.components(separatedBy: .newlines)
        var stack: [(line: Int, keyword: String?)] = []
        var scopes: [FoldableScope] = []

        let keywords = ["func", "class", "struct", "enum", "if", "guard", "switch", "extension", "protocol", "for", "while"]

        for (index, line) in lines.enumerated() {
            let lineNumber = index + 1
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Extract keyword if line starts with any keyword
            var detectedKeyword: String?
            for keyword in keywords {
                if trimmed.hasPrefix(keyword + " ") || trimmed == keyword {
                    detectedKeyword = keyword
                    break
                }
            }

            // Count opening and closing braces
            for char in line {
                if char == "{" {
                    stack.append((line: lineNumber, keyword: detectedKeyword))
                } else if char == "}" {
                    if let top = stack.popLast() {
                        if lineNumber > top.line {
                            scopes.append(FoldableScope(startLine: top.line, endLine: lineNumber, scopeKeyword: top.keyword))
                        }
                    }
                }
            }
        }

        lock.lock()
        detectedScopes = scopes.sorted(by: { $0.startLine < $1.startLine })
        lock.unlock()

        return scopes
    }

    public func toggleFold(for scope: FoldableScope) {
        lock.lock()
        defer { lock.unlock() }

        let range = scope.startLine...scope.endLine
        if foldedLineRanges.contains(range) {
            foldedLineRanges.remove(range)
        } else {
            foldedLineRanges.insert(range)
        }
    }

    public func isLineFoldedHidden(_ lineNumber: Int) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        for range in foldedLineRanges {
            // Keep the start line visible with a placeholder "...", hide lines between start+1 and end
            if lineNumber > range.lowerBound && lineNumber <= range.upperBound {
                return true
            }
        }
        return false
    }

    public func isScopeFolded(atStartLine startLine: Int) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return foldedLineRanges.contains(where: { $0.lowerBound == startLine })
    }
}
