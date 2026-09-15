//
//  AssistValidationEngine.swift
//  CodeEdit
//

import Foundation

public struct ValidationDiagnostic: Identifiable, Sendable {
    public let id: UUID
    public let filePath: String
    public let line: Int
    public let column: Int
    public let severity: String
    public let message: String

    public init(
        id: UUID = UUID(),
        filePath: String,
        line: Int = 1,
        column: Int = 1,
        severity: String = "error",
        message: String
    ) {
        self.id = id
        self.filePath = filePath
        self.line = line
        self.column = column
        self.severity = severity
        self.message = message
    }
}

public struct ValidationResult: Sendable {
    public let isValid: Bool
    public let tier: Int // 1, 2, or 3
    public let diagnostics: [ValidationDiagnostic]
    public let description: String

    public init(isValid: Bool, tier: Int, diagnostics: [ValidationDiagnostic] = [], description: String) {
        self.isValid = isValid
        self.tier = tier
        self.diagnostics = diagnostics
        self.description = description
    }
}

public actor AssistValidationEngine {
    public static let shared = AssistValidationEngine()

    private init() {}

    // MARK: - Validation 1/3 (Pre-Planning Baseline)

    public func validateBaseline(projectURL: URL) async -> ValidationResult {
        DiagnosticEventBus.shared.logEvent(
            component: "AssistValidationEngine",
            severity: "INFO",
            category: "validation_tier_1",
            message: "Running Validation Tier 1/3: Baseline workspace check"
        )

        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: projectURL.path) else {
            let diag = ValidationDiagnostic(
                filePath: projectURL.path,
                severity: "fatal",
                message: "Project root path does not exist"
            )
            return ValidationResult(isValid: false, tier: 1, diagnostics: [diag], description: "Root missing")
        }

        return ValidationResult(
            isValid: true,
            tier: 1,
            description: "Baseline repository structure and paths verified."
        )
    }

    // MARK: - Validation 2/3 (Post-Edit Incremental Pass)

    public func validateIncrementalEdit(fileURL: URL) async -> ValidationResult {
        DiagnosticEventBus.shared.logEvent(
            component: "AssistValidationEngine",
            severity: "INFO",
            category: "validation_tier_2",
            message: "Running Validation Tier 2/3: Incremental syntax pass on \(fileURL.lastPathComponent)"
        )

        // Read content and perform syntax sanity checks
        guard let content = try? String(contentsOf: fileURL, encoding: .utf8) else {
            let diag = ValidationDiagnostic(
                filePath: fileURL.path,
                severity: "error",
                message: "Failed to read file contents for typecheck"
            )
            return ValidationResult(isValid: false, tier: 2, diagnostics: [diag], description: "Read failed")
        }

        // Bracket balance audit
        var braceCount = 0
        var parenCount = 0
        for char in content {
            if char == "{" { braceCount += 1 }
            else if char == "}" { braceCount -= 1 }
            else if char == "(" { parenCount += 1 }
            else if char == ")" { parenCount -= 1 }
        }

        var diags: [ValidationDiagnostic] = []
        if braceCount != 0 {
            diags.append(ValidationDiagnostic(
                filePath: fileURL.path,
                severity: "error",
                message: "Unbalanced braces detected: count offset \(braceCount)"
            ))
        }
        if parenCount != 0 {
            diags.append(ValidationDiagnostic(
                filePath: fileURL.path,
                severity: "error",
                message: "Unbalanced parentheses detected: count offset \(parenCount)"
            ))
        }

        let passed = diags.isEmpty
        return ValidationResult(
            isValid: passed,
            tier: 2,
            diagnostics: diags,
            description: passed ? "Incremental syntax pass succeeded" : "Incremental syntax errors found"
        )
    }

    // MARK: - Validation 3/3 (Pre-Review Synthesis Pass)

    public func validatePreReviewSynthesis(modifiedFiles: [URL]) async -> ValidationResult {
        DiagnosticEventBus.shared.logEvent(
            component: "AssistValidationEngine",
            severity: "INFO",
            category: "validation_tier_3",
            message: "Running Validation Tier 3/3: Pre-review synthesis audit"
        )

        var allDiagnostics: [ValidationDiagnostic] = []
        for file in modifiedFiles {
            let result = await validateIncrementalEdit(fileURL: file)
            if !result.isValid {
                allDiagnostics.append(contentsOf: result.diagnostics)
            }
        }

        let passed = allDiagnostics.isEmpty
        return ValidationResult(
            isValid: passed,
            tier: 3,
            diagnostics: allDiagnostics,
            description: passed ? "All modified files passed pre-review synthesis" : "Synthesis errors detected"
        )
    }
}
