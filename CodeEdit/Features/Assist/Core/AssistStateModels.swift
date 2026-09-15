//
//  AssistStateModels.swift
//  CodeEdit
//

import Foundation
import Combine

public enum AgentSessionStatus: String, Codable, Sendable {
    case idle                  = "Idle"
    case receivingRequest      = "Receiving Request"
    case analyzingRepository   = "Analyzing Repository"
    case collectingContext     = "Collecting Context"
    case planning              = "Formulating Execution Plan"
    case selectingTools        = "Selecting Tools"
    case executingTool         = "Executing Tool"
    case validating            = "Validating Implementation"
    case reviewing             = "Autonomous Code Review"
    case generatingSummary     = "Compiling Summary"
    case completing            = "Finalizing Task"
    case terminated            = "Terminated / Succeeded"
    case failed                = "Execution Failed"
}

public struct StateTransition: Codable, Sendable {
    public let timestamp: Date
    public let fromState: AgentSessionStatus
    public let toState: AgentSessionStatus
    public let reason: String

    public init(fromState: AgentSessionStatus, toState: AgentSessionStatus, reason: String, timestamp: Date = Date()) {
        self.timestamp = timestamp
        self.fromState = fromState
        self.toState = toState
        self.reason = reason
    }
}

public struct AgentEvent: Identifiable, Codable, Sendable {
    public let id: UUID
    public let timestamp: Date
    public let state: AgentSessionStatus
    public let summary: String
    public let toolResult: String?

    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        state: AgentSessionStatus,
        summary: String,
        toolResult: String? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.state = state
        self.summary = summary
        self.toolResult = toolResult
    }
}

public struct ExecutionSummaryData: Codable, Sendable {
    public let objective: String
    public let totalDuration: TimeInterval
    public let toolCallCount: Int
    public let filesCreatedCount: Int
    public let filesModifiedCount: Int
    public let filesDeletedCount: Int
    public let validationCount: Int
    public let reviewerConfidence: Double
    public let finalOutcome: String

    public init(
        objective: String,
        totalDuration: TimeInterval = 0,
        toolCallCount: Int = 0,
        filesCreatedCount: Int = 0,
        filesModifiedCount: Int = 0,
        filesDeletedCount: Int = 0,
        validationCount: Int = 0,
        reviewerConfidence: Double = 0.0,
        finalOutcome: String = ""
    ) {
        self.objective = objective
        self.totalDuration = totalDuration
        self.toolCallCount = toolCallCount
        self.filesCreatedCount = filesCreatedCount
        self.filesModifiedCount = filesModifiedCount
        self.filesDeletedCount = filesDeletedCount
        self.validationCount = validationCount
        self.reviewerConfidence = reviewerConfidence
        self.finalOutcome = finalOutcome
    }
}

public final class DiagnosticEventBus: @unchecked Sendable {
    public static let shared = DiagnosticEventBus()

    private let lock = NSLock()
    private var logEntries: [String] = []

    private init() {}

    public func logEvent(component: String, severity: String, category: String, message: String) {
        lock.lock()
        defer { lock.unlock() }

        let timestamp = ISO8601DateFormatter().string(from: Date())
        let formatted = "[\(timestamp)] [\(severity)] [\(component):\(category)] \(message)"
        logEntries.append(formatted)
        if logEntries.count > 2000 {
            logEntries.removeFirst(200)
        }
        print(formatted)
    }

    public func getRecentLogs(maxCount: Int = 100) -> [String] {
        lock.lock()
        defer { lock.unlock() }
        return Array(logEntries.suffix(maxCount))
    }
}
