//
//  ExecutableTool.swift
//  CodeEdit
//

import Foundation

public struct ToolParametersSchema: Codable, Sendable {
    public let type: String
    public let properties: [String: ToolParameterProperty]
    public let required: [String]

    public init(type: String = "object", properties: [String: ToolParameterProperty] = [:], required: [String] = []) {
        self.type = type
        self.properties = properties
        self.required = required
    }
}

public struct ToolParameterProperty: Codable, Sendable {
    public let type: String
    public let description: String?
    public let `enum`: [String]?

    public init(type: String, description: String? = nil, enumValues: [String]? = nil) {
        self.type = type
        self.description = description
        self.`enum` = enumValues
    }
}

public struct ToolExecutionContext: Sendable {
    public let projectRootURL: URL
    public let activeFileURL: URL?

    public init(projectRootURL: URL, activeFileURL: URL? = nil) {
        self.projectRootURL = projectRootURL
        self.activeFileURL = activeFileURL
    }
}

public struct ToolResult: Sendable {
    public let isSuccess: Bool
    public let output: String
    public let metadata: [String: String]

    public init(isSuccess: Bool, output: String, metadata: [String: String] = [:]) {
        self.isSuccess = isSuccess
        self.output = output
        self.metadata = metadata
    }

    public static func success(_ output: String, metadata: [String: String] = [:]) -> ToolResult {
        ToolResult(isSuccess: true, output: output, metadata: metadata)
    }

    public static func failure(_ output: String, metadata: [String: String] = [:]) -> ToolResult {
        ToolResult(isSuccess: false, output: output, metadata: metadata)
    }
}

public protocol ExecutableTool: Sendable {
    var name: String { get }
    var description: String { get }
    var parametersSchema: ToolParametersSchema { get }
    func execute(arguments: [String: Any], context: ToolExecutionContext) async throws -> ToolResult
}

// MARK: - Assist Engine Tool Interface

public struct JSONSchema: Codable, Sendable {
    public let type: String
    public let properties: [String: JSONSchemaProperty]?
    public let required: [String]?

    public init(type: String = "object", properties: [String: JSONSchemaProperty]? = nil, required: [String]? = nil) {
        self.type = type
        self.properties = properties
        self.required = required
    }
}

public struct JSONSchemaProperty: Codable, Sendable {
    public let type: String
    public let description: String?

    public init(type: String, description: String? = nil) {
        self.type = type
        self.description = description
    }
}

public struct AssistContext: Sendable {
    public let workspaceURL: URL

    public init(workspaceURL: URL) {
        self.workspaceURL = workspaceURL
    }
}

public struct AssistToolResult: Sendable {
    public let isSuccess: Bool
    public let summary: String

    public init(isSuccess: Bool, summary: String) {
        self.isSuccess = isSuccess
        self.summary = summary
    }

    public static func success(_ summary: String) -> AssistToolResult {
        AssistToolResult(isSuccess: true, summary: summary)
    }

    public static func failure(_ summary: String) -> AssistToolResult {
        AssistToolResult(isSuccess: false, summary: summary)
    }
}

public protocol AssistTool: Sendable {
    var id: String { get }
    var name: String { get }
    var description: String { get }
    var parametersSchema: JSONSchema { get }
    func execute(input: [String: Any], context: AssistContext) async throws -> AssistToolResult
}
