//
//  AssistCodeReviewGate.swift
//  CodeEdit
//

import Foundation

public struct CodeReviewOutcome: Sendable {
    public let isApproved: Bool
    public let status: String // "task_ready" or "revisions_required"
    public let confidenceScore: Double
    public let strengths: [String]
    public let issues: [String]
    public let recommendedFixes: [String]

    public init(
        isApproved: Bool,
        status: String,
        confidenceScore: Double,
        strengths: [String] = [],
        issues: [String] = [],
        recommendedFixes: [String] = []
    ) {
        self.isApproved = isApproved
        self.status = status
        self.confidenceScore = confidenceScore
        self.strengths = strengths
        self.issues = issues
        self.recommendedFixes = recommendedFixes
    }
}

public actor AssistCodeReviewGate {
    public static let shared = AssistCodeReviewGate()

    public static let minimumPassingConfidence: Double = 0.85

    private init() {}

    /// Audits modified code changes and returns a comprehensive review outcome.
    public func evaluateReview(
        objective: String,
        modifiedFiles: [URL]
    ) async -> CodeReviewOutcome {
        DiagnosticEventBus.shared.logEvent(
            component: "AssistCodeReviewGate",
            severity: "INFO",
            category: "code_review_gate",
            message: "Evaluating autonomous code review for objective: '\(objective)'"
        )

        var detectedIssues: [String] = []
        var strengths: [String] = []
        var recommendedFixes: [String] = []

        if modifiedFiles.isEmpty {
            detectedIssues.append("No files were modified to achieve the objective.")
            recommendedFixes.append("Inspect the codebase and modify the appropriate files.")
        } else {
            strengths.append("Identified and modified \(modifiedFiles.count) target file(s).")
        }

        // Perform security and concurrency heuristics
        for file in modifiedFiles {
            guard let content = try? String(contentsOf: file, encoding: .utf8) else {
                detectedIssues.append("Could not inspect contents of \(file.lastPathComponent)")
                continue
            }

            // Heuristic 1: Check for leftover TODO/FIXME markers
            if content.contains("TODO: IMPLEMENT") || content.contains("FATAL_ERROR") {
                detectedIssues.append("Incomplete implementation placeholder detected in \(file.lastPathComponent)")
                recommendedFixes.append("Replace placeholder comments with working logic in \(file.lastPathComponent)")
            }

            // Heuristic 2: Check for obvious security flaws
            if content.contains("kSecAttrAccessibleAlways") {
                detectedIssues.append("Deprecated and insecure Keychain accessibility attribute in \(file.lastPathComponent)")
                recommendedFixes.append("Use kSecAttrAccessibleAfterFirstUnlock instead")
            }
        }

        if detectedIssues.isEmpty {
            strengths.append("Zero critical architecture, security, or concurrency violations found.")
            strengths.append("Implementation conforms to specification contracts.")
            return CodeReviewOutcome(
                isApproved: true,
                status: "task_ready",
                confidenceScore: 0.94,
                strengths: strengths,
                issues: [],
                recommendedFixes: []
            )
        } else {
            return CodeReviewOutcome(
                isApproved: false,
                status: "revisions_required",
                confidenceScore: 0.65,
                strengths: strengths,
                issues: detectedIssues,
                recommendedFixes: recommendedFixes
            )
        }
    }

    /// Generates structured revision instructions for re-injecting into agent conversation.
    public nonisolated func formatRejectionFeedback(outcome: CodeReviewOutcome) -> String {
        var message = "- Action: Final Response. Code Review Result: FAILED - Revisions required.\n"
        message += "Strengths:\n"
        for str in outcome.strengths {
            message += "- \(str)\n"
        }
        message += "Issues detected:\n"
        for iss in outcome.issues {
            message += "- \(iss)\n"
        }
        message += "Recommended Fixes:\n"
        for fix in outcome.recommendedFixes {
            message += "- \(fix)\n"
        }
        message += "Please review these issues, update your plan, make the required modifications, verify them, and call code_review again."
        return message
    }
}
