//
//  AssistAgentSession.swift
//  CodeEdit
//

import Foundation
import SwiftUI
import Combine

public struct AgentTurn: Identifiable, Sendable {
    public let id: UUID
    public let role: String // "user", "assistant", "system", "tool"
    public let content: String
    public let toolId: String?
    public let timestamp: Date

    public init(id: UUID = UUID(), role: String, content: String, toolId: String? = nil, timestamp: Date = Date()) {
        self.id = id
        self.role = role
        self.content = content
        self.toolId = toolId
        self.timestamp = timestamp
    }
}

public struct AgentChecklistItem: Identifiable, Equatable, Sendable {
    public let id: UUID
    public var title: String
    public var isCompleted: Bool

    public init(id: UUID = UUID(), title: String, isCompleted: Bool = false) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
    }
}

@MainActor
public final class AssistAgentSession: ObservableObject {
    public static let shared = AssistAgentSession()

    @Published public private(set) var status: AgentSessionStatus = .idle
    @Published public private(set) var stateHistory: [StateTransition] = []
    @Published public private(set) var events: [AgentEvent] = []
    @Published public private(set) var turns: [AgentTurn] = []
    @Published public private(set) var checklist: [AgentChecklistItem] = []
    @Published public var currentObjective: String = ""
    @Published public var isRunning: Bool = false
    @Published public var takeoverEnabled: Bool = false
    @Published public var summaryData: ExecutionSummaryData?

    private var sessionStartTime: Date?
    private var toolCallCounter = 0
    private var codeReviewAttempts = 0

    private init() {}

    // MARK: - State Transitions

    public func transition(to newState: AgentSessionStatus, reason: String, toolResult: String? = nil) {
        let oldState = self.status
        guard oldState != newState else { return }

        let stateTransition = StateTransition(fromState: oldState, toState: newState, reason: reason)
        self.stateHistory.append(stateTransition)
        self.status = newState

        DiagnosticEventBus.shared.logEvent(
            component: "AssistAgentSession",
            severity: "INFO",
            category: "state_transition",
            message: "Transitioned from \(oldState.rawValue) to \(newState.rawValue). Reason: \(reason)"
        )

        let event = AgentEvent(state: newState, summary: reason, toolResult: toolResult)
        self.events.append(event)
    }

    // MARK: - Session Control

    public func startSession(objective: String) {
        self.currentObjective = objective
        self.isRunning = true
        self.sessionStartTime = Date()
        self.toolCallCounter = 0
        self.codeReviewAttempts = 0
        self.turns = []
        self.checklist = []
        self.summaryData = nil

        transition(to: .receivingRequest, reason: "Session started with objective: \(objective)")
        turns.append(AgentTurn(role: "user", content: objective))
    }

    public func cancelSession() {
        transition(to: .terminated, reason: "Session cancelled by user")
        isRunning = false
    }

    public func addChecklistItem(title: String) {
        checklist.append(AgentChecklistItem(title: title))
    }

    public func setItemCompleted(id: UUID, isCompleted: Bool) {
        if let index = checklist.firstIndex(where: { $0.id == id }) {
            checklist[index].isCompleted = isCompleted
        }
    }

    // MARK: - JSON Extraction Protocol

    public func extractJSON(from response: String) -> [String: Any]? {
        let trimmed = response.trimmingCharacters(in: .whitespacesAndNewlines)

        // 1. Direct JSON attempt
        if let data = trimmed.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            return json
        }

        // 2. Fenced Markdown block extraction (```json ... ```)
        if let startRange = trimmed.range(of: "```json"),
           let endRange = trimmed.range(of: "```", range: startRange.upperBound..<trimmed.endIndex) {
            let block = trimmed[startRange.upperBound..<endRange.lowerBound]
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if let data = block.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                return json
            }
        }

        // 3. Regex boundary scanner ({ ... })
        if let firstBrace = trimmed.firstIndex(of: "{"),
           let lastBrace = trimmed.lastIndex(of: "}") {
            let block = trimmed[firstBrace...lastBrace]
            if let data = block.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                return json
            }
        }

        return nil
    }

    // MARK: - Prompt Assembly

    public func buildSystemPrompt(
        objective: String,
        activeFilePath: String? = nil,
        activeContent: String? = nil,
        availableToolsSummary: String = ""
    ) -> String {
        return """
        # HIDDEN RUNTIME INSTRUCTIONS & ROLE
        Execution Key: com.SwiftCode.Assist-Agent
        Execution Mode: com.SwiftCode.Assist-Agent

        You are an autonomous Swift/macOS coding agent working in the Universal Code Editor.
        Your goal is: "\(objective)"

        You can execute local actions by outputting a JSON object.
        Choose one of the available tools, or output a final response when the task is complete.

        You MUST respond in exactly this JSON format (no markdown backticks, no text outside the JSON):
        {
          "toolId": "the_tool_id",
          "input": { "key": "value" },
          "explanation": "Why you are using this tool"
        }
        OR, if the goal is fully achieved and no more tools are needed:
        {
          "finalResponse": "A clear, detailed description of your achievements and the files modified"
        }

        # ACTIVE FILE
        \(activeFilePath ?? "None")
        \(activeContent ?? "")

        # AVAILABLE TOOLS
        \(availableToolsSummary)

        # SECURITY CONSTRAINTS
        - Never use relative traversal (e.g. "..") or root paths (e.g. "/").
        - Always double check file paths before reading/writing.
        """
    }

    public func finalizeSuccess(outcome: String, modifiedFiles: Int, createdFiles: Int) {
        let duration = sessionStartTime.map { Date().timeIntervalSince($0) } ?? 0
        let summary = ExecutionSummaryData(
            objective: currentObjective,
            totalDuration: duration,
            toolCallCount: toolCallCounter,
            filesCreatedCount: createdFiles,
            filesModifiedCount: modifiedFiles,
            filesDeletedCount: 0,
            validationCount: 3,
            reviewerConfidence: 0.95,
            finalOutcome: outcome
        )
        self.summaryData = summary
        transition(to: .completing, reason: "Assembling final summary")
        transition(to: .terminated, reason: "Task successfully completed")
        isRunning = false
    }
}
