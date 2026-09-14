//
//  AssistAgentSessionModels.swift
//  UniversalIDE
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

    public init(timestamp: Date = Date(), fromState: AgentSessionStatus, toState: AgentSessionStatus, reason: String) {
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
        totalDuration: TimeInterval,
        toolCallCount: Int,
        filesCreatedCount: Int,
        filesModifiedCount: Int,
        filesDeletedCount: Int,
        validationCount: Int,
        reviewerConfidence: Double,
        finalOutcome: String
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

public struct AgentSessionState: Sendable {
    public var status: AgentSessionStatus
    public var stateHistory: [StateTransition]
    public var events: [AgentEvent]
    public var objective: String

    public init(
        status: AgentSessionStatus = .idle,
        stateHistory: [StateTransition] = [],
        events: [AgentEvent] = [],
        objective: String = ""
    ) {
        self.status = status
        self.stateHistory = stateHistory
        self.events = events
        self.objective = objective
    }
}

public final class DiagnosticEventBus: @unchecked Sendable {
    public static let shared = DiagnosticEventBus()

    private init() {}

    public func logEvent(component: String, severity: String, category: String, message: String) {
        print("[\(severity)] [\(component):\(category)] \(message)")
    }
}

@MainActor
public final class AssistAgentSession: ObservableObject {
    @Published public var state: AgentSessionState

    public init(objective: String = "") {
        self.state = AgentSessionState(objective: objective)
    }

    public func transition(to newState: AgentSessionStatus, reason: String, toolResult: String? = nil) {
        let oldState = self.state.status
        guard oldState != newState else { return }

        let transition = StateTransition(fromState: oldState, toState: newState, reason: reason)
        self.state.stateHistory.append(transition)
        self.state.status = newState

        DiagnosticEventBus.shared.logEvent(
            component: "AssistAgentSession",
            severity: "INFO",
            category: "state_transition",
            message: "Transitioned from \(oldState.rawValue) to \(newState.rawValue). Reason: \(reason)"
        )

        let event = AgentEvent(state: newState, summary: reason, toolResult: toolResult)
        self.state.events.append(event)
    }
}
