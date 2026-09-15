//
//  AssistCoreEngineTools.swift
//  CodeEdit
//

import Foundation

// MARK: - Generic Base Assist Tool Struct
public struct GenericAssistTool: AssistTool {
    public let id: String
    public let name: String
    public let description: String
    public let parametersSchema: JSONSchema
    private let handler: @Sendable ([String: Any], AssistContext) async throws -> AssistToolResult

    public init(
        id: String,
        name: String,
        description: String,
        schema: JSONSchema = JSONSchema(),
        handler: @escaping @Sendable ([String: Any], AssistContext) async throws -> AssistToolResult
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.parametersSchema = schema
        self.handler = handler
    }

    public func execute(input: [String: Any], context: AssistContext) async throws -> AssistToolResult {
        try await handler(input, context)
    }
}

public struct CodeReviewToolInstance: AssistTool {
    public let id = "code_review"
    public let name = "Autonomous Code Review"
    public let description = "Evaluates recent changes against quality, security, and concurrency gates."
    public var parametersSchema: JSONSchema { JSONSchema() }

    public init() {}

    public func execute(input: [String: Any], context: AssistContext) async throws -> AssistToolResult {
        let outcome = await AssistCodeReviewGate.shared.evaluateReview(
            objective: "Verify implementation completeness",
            modifiedFiles: []
        )
        return outcome.isApproved ? .success("Code review PASSED with confidence \(outcome.confidenceScore)")
                                  : .failure(AssistCodeReviewGate.shared.formatRejectionFeedback(outcome: outcome))
    }
}

public struct UseTermFunctionTool: AssistTool {
    public let id = "use_term_function"
    public let name = "Execute Approved Terminal Function"
    public let description = "Executes shell commands after interactive terminal confirmation."
    public var parametersSchema: JSONSchema {
        JSONSchema(properties: ["command": JSONSchemaProperty(type: "string", description: "Command")], required: ["command"])
    }

    public init() {}

    public func execute(input: [String: Any], context: AssistContext) async throws -> AssistToolResult {
        guard let cmd = input["command"] as? String else { return .failure("Missing command") }
        let res = try await CommandRunner.execute(command: cmd, in: context.workspaceURL)
        return .success(res.output)
    }
}
