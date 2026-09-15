//
//  AssistCognitiveEngines.swift
//  CodeEdit
//

import Foundation

// MARK: - Loop Stability Regulator

public enum ExecutionLoopFailure: Equatable, Sendable {
    case infiniteLoop(reason: String)
    case oscillation(pattern: String)
    case noProgress(iterations: Int)
}

public actor AssistLoopStabilityRegulator {
    public static let shared = AssistLoopStabilityRegulator()

    private var recentToolSignatures: [String] = []
    private var iterationsWithoutFileChange = 0

    private init() {}

    public func recordIteration(toolName: String, argumentsJSON: String, didMutateDisk: Bool) -> ExecutionLoopFailure? {
        let signature = "\(toolName)::\(argumentsJSON)"
        recentToolSignatures.append(signature)
        if recentToolSignatures.count > 15 {
            recentToolSignatures.removeFirst()
        }

        if didMutateDisk {
            iterationsWithoutFileChange = 0
        } else {
            iterationsWithoutFileChange += 1
        }

        // 1. Infinite loop check: last 3 calls identical
        if recentToolSignatures.count >= 3 {
            let lastThree = Array(recentToolSignatures.suffix(3))
            if lastThree[0] == lastThree[1] && lastThree[1] == lastThree[2] {
                return .infiniteLoop(reason: "Repeated identical tool call: \(toolName)")
            }
        }

        // 2. Oscillation check: alternating A-B-A-B pattern
        if recentToolSignatures.count >= 4 {
            let lastFour = Array(recentToolSignatures.suffix(4))
            if lastFour[0] == lastFour[2] && lastFour[1] == lastFour[3] && lastFour[0] != lastFour[1] {
                return .oscillation(pattern: "Alternating tool calls: \(lastFour[0]) <-> \(lastFour[1])")
            }
        }

        // 3. No progress check
        if iterationsWithoutFileChange >= 15 {
            return .noProgress(iterations: iterationsWithoutFileChange)
        }

        return nil
    }

    public func generateEscapePrompt(for goal: String) -> String {
        return "Break out of loop/stagnation. Try a completely different technique for: \(goal)"
    }

    public func reset() {
        recentToolSignatures.removeAll()
        iterationsWithoutFileChange = 0
    }
}

// MARK: - Context Drift Detector

public actor AssistContextDriftDetector {
    public static let shared = AssistContextDriftDetector()

    private init() {}

    public func computeDriftScore(originalGoal: String, currentIntent: String) -> Double {
        let originalWords = Set(originalGoal.lowercased().components(separatedBy: .whitespacesAndNewlines))
        let currentWords = Set(currentIntent.lowercased().components(separatedBy: .whitespacesAndNewlines))

        guard !originalWords.isEmpty, !currentWords.isEmpty else { return 0.0 }
        let intersection = originalWords.intersection(currentWords)
        let similarity = Double(intersection.count) / Double(max(originalWords.count, currentWords.count))
        let driftScore = 1.0 - similarity
        return driftScore
    }
}

// MARK: - Root Cause Analyzer & Recovery Strategy

public enum DiagnosticRootCause: Sendable {
    case missingImport(moduleName: String)
    case typeMismatch(details: String)
    case unresolvedIdentifier(symbolName: String)
    case accessViolation(details: String)
    case generic(String)
}

public actor AssistFailureRootCauseAnalyzer {
    public static let shared = AssistFailureRootCauseAnalyzer()

    private init() {}

    public func analyzeDiagnostic(message: String) -> DiagnosticRootCause {
        if message.contains("cannot find type '") || message.contains("cannot find '") {
            let symbol = message.components(separatedBy: "'").dropFirst().first ?? "Unknown"
            return .unresolvedIdentifier(symbolName: symbol)
        } else if message.contains("cannot convert value of type") {
            return .typeMismatch(details: message)
        } else if message.contains("is inaccessible due to") {
            return .accessViolation(details: message)
        } else if message.contains("no such module") {
            let module = message.components(separatedBy: "'").dropFirst().first ?? "Unknown"
            return .missingImport(moduleName: module)
        }
        return .generic(message)
    }

    public func generateRecoveryPrompt(cause: DiagnosticRootCause) -> String {
        switch cause {
        case .missingImport(let module):
            return "Compiler error: Missing module '\(module)'. Add 'import \(module)' to the file."
        case .unresolvedIdentifier(let symbol):
            return "Compiler error: Unresolved symbol '\(symbol)'. Declare this symbol or import its parent module."
        case .typeMismatch(let details):
            return "Compiler error: Type mismatch - \(details). Cast or convert the value appropriately."
        case .accessViolation(let details):
            return "Compiler error: Access control violation - \(details). Make symbol public or internal."
        case .generic(let msg):
            return "Compiler error encountered: \(msg). Investigate and repair the code."
        }
    }
}

// MARK: - Goal Expansion & Task Continuation

public actor AssistGoalExpansionEngine {
    public static let shared = AssistGoalExpansionEngine()

    private init() {}

    public func expandGoals(completedGoal: String, modifiedFiles: [String]) -> [String] {
        var expanded: [String] = []
        expanded.append("Generate comprehensive unit tests for \(completedGoal)")
        expanded.append("Add DocC documentation for modified public APIs")
        expanded.append("Audit edge cases and error handling for: \(completedGoal)")
        return expanded
    }
}

public actor AssistTaskContinuationEngine {
    public static let shared = AssistTaskContinuationEngine()

    private init() {}

    public func shouldContinue(currentGoal: String, completedCount: Int, maxLimit: Int = 10) -> Bool {
        return completedCount < maxLimit && !currentGoal.isEmpty
    }
}
