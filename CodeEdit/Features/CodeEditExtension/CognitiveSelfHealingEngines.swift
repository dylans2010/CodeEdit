//
//  CognitiveSelfHealingEngines.swift
//  UniversalIDE
//

import Foundation

public enum LoopFailurePattern: Sendable, Equatable {
    case infiniteLoop(reason: String)
    case oscillation(pattern: String)
    case noProgress(iterations: Int)
}

public final class AssistLoopStabilityRegulator: @unchecked Sendable {
    private var history: [String] = []

    public init() {}

    public func recordIteration(signature: String) -> LoopFailurePattern? {
        history.append(signature)
        if history.count > 15 {
            history.removeFirst()
        }

        let occurrences = history.filter { $0 == signature }.count
        if occurrences >= 4 {
            return .infiniteLoop(reason: "Repeated action '\(signature)' 4 times in recent history.")
        }

        if history.count >= 15 && Set(history).count <= 2 {
            return .oscillation(pattern: "Oscillating between alternating tool calls.")
        }

        if history.count >= 15 && Set(history).count == 1 {
            return .noProgress(iterations: history.count)
        }

        return nil
    }
}

public final class AssistContextDriftDetector: @unchecked Sendable {
    public init() {}

    public func computeDriftScore(originalGoal: String, currentIntent: String) -> Double {
        if originalGoal == currentIntent { return 0.0 }
        // Simple word overlap semantic similarity check
        let origWords = Set(originalGoal.lowercased().split(separator: " "))
        let currWords = Set(currentIntent.lowercased().split(separator: " "))
        let intersection = origWords.intersection(currWords)
        if origWords.isEmpty { return 0.0 }
        let similarity = Double(intersection.count) / Double(origWords.count)
        return 1.0 - similarity
    }
}

public enum CompilerDiagnosticRootCause: Sendable {
    case missingImport(moduleName: String)
    case typeMismatch(expected: String, actual: String)
    case unresolvedIdentifier(symbol: String)
    case accessViolation
    case unknown(String)
}

public final class AssistFailureRootCauseAnalyzer: @unchecked Sendable {
    public init() {}

    public func analyze(diagnosticMessage: String) -> CompilerDiagnosticRootCause {
        if diagnosticMessage.contains("cannot find type") || diagnosticMessage.contains("unresolved identifier") {
            let components = diagnosticMessage.components(separatedBy: "'")
            let symbol = components.count > 1 ? components[1] : "unknown"
            return .unresolvedIdentifier(symbol: symbol)
        } else if diagnosticMessage.contains("no such module") {
            let components = diagnosticMessage.components(separatedBy: "'")
            let module = components.count > 1 ? components[1] : "unknown"
            return .missingImport(moduleName: module)
        }
        return .unknown(diagnosticMessage)
    }
}

public final class AssistRecoveryStrategyGenerator: @unchecked Sendable {
    public init() {}

    public func generateRecoveryPrompt(cause: CompilerDiagnosticRootCause, targetGoal: String) -> String {
        switch cause {
        case .missingImport(let module):
            return "Missing module '\(module)'. Scanned project, please add 'import \(module)' to the file."
        case .unresolvedIdentifier(let symbol):
            return "Unresolved symbol '\(symbol)'. Check imports or define symbol before usage."
        case .typeMismatch(let expected, let actual):
            return "Type mismatch: Expected '\(expected)', got '\(actual)'. Convert type parameters."
        case .accessViolation:
            return "Access level violation. Adjust access modifiers (public/internal/private)."
        case .unknown(let msg):
            return "Fix compiler issue: \(msg)"
        }
    }
}

public struct Checkpoint: Identifiable, Sendable {
    public let id: String
    public let timestamp: Date
    public let fileSnapshots: [String: String]

    public init(id: String, timestamp: Date = Date(), fileSnapshots: [String: String]) {
        self.id = id
        self.timestamp = timestamp
        self.fileSnapshots = fileSnapshots
    }
}

public final class CodePatchEngine: @unchecked Sendable {
    private var checkpoints: [String: Checkpoint] = [:]

    public init() {}

    public func createCheckpoint(name: String, files: [String: String]) -> Checkpoint {
        let cp = Checkpoint(id: name, fileSnapshots: files)
        checkpoints[name] = cp
        return cp
    }

    public func rollbackToCheckpoint(name: String) -> [String: String]? {
        return checkpoints[name]?.fileSnapshots
    }
}

public final class AssistGoalExpansionEngine: @unchecked Sendable {
    public init() {}

    public func discoverFollowUpGoals(completedGoal: String, codebaseSummary: String) -> [String] {
        return [
            "Generate unit tests for newly added components",
            "Add DocC documentation for exported APIs",
            "Verify thread safety and Sendable conformance"
        ]
    }
}

public final class AssistTaskContinuationEngine: @unchecked Sendable {
    public init() {}

    public func shouldContinue(currentGoal: String, completedPlan: [String]) -> Bool {
        return true
    }
}
