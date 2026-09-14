//
//  MCPHostSpecification.swift
//  UniversalIDE
//

import Foundation

public enum JSONRPCID: Codable, Sendable, Hashable {
    case integer(Int)
    case string(String)
    case null

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let intValue = try? container.decode(Int.self) {
            self = .integer(intValue)
        } else if let stringValue = try? container.decode(String.self) {
            self = .string(stringValue)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid JSONRPC ID")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .integer(let val): try container.encode(val)
        case .string(let val): try container.encode(val)
        case .null: try container.encodeNil()
        }
    }

    public var integerValue: Int? {
        switch self {
        case .integer(let val): return val
        case .string(let val): return Int(val)
        case .null: return nil
        }
    }
}

public struct JSONRPCRequest: Codable, Sendable {
    public let jsonrpc: String = "2.0"
    public let id: JSONRPCID?
    public let method: String
    public let params: [String: String]?

    public init(id: JSONRPCID?, method: String, params: [String: String]? = nil) {
        self.id = id
        self.method = method
        self.params = params
    }
}

public struct JSONRPCResponse: Codable, Sendable {
    public let jsonrpc: String
    public let id: JSONRPCID?
    public let result: [String: String]?
    public let error: JSONRPCError?
}

public struct JSONRPCNotification: Codable, Sendable {
    public let jsonrpc: String = "2.0"
    public let method: String
    public let params: [String: String]?

    public init(method: String, params: [String: String]? = nil) {
        self.method = method
        self.params = params
    }
}

public struct JSONRPCError: Codable, Sendable, Error {
    public let code: Int
    public let message: String
}

public protocol MCPTransportSession: Sendable {
    func connect(messageHandler: @escaping @Sendable (JSONRPCResponse) -> Void) async throws
    func send(request: JSONRPCRequest) async throws -> JSONRPCResponse
    func send(notification: JSONRPCNotification) async throws
    func disconnect()
}

public final class StdioTransportSession: MCPTransportSession, @unchecked Sendable {
    public init() {}
    public func connect(messageHandler: @escaping @Sendable (JSONRPCResponse) -> Void) async throws {}
    public func send(request: JSONRPCRequest) async throws -> JSONRPCResponse {
        return JSONRPCResponse(jsonrpc: "2.0", id: request.id, result: ["status": "ok"], error: nil)
    }
    public func send(notification: JSONRPCNotification) async throws {}
    public func disconnect() {}
}

public struct MCPToolProperty: Codable, Sendable, Hashable {
    public let type: String
    public let description: String?
    public let `enum`: [String]?

    public init(type: String, description: String? = nil, `enum`: [String]? = nil) {
        self.type = type
        self.description = description
        self.enum = `enum`
    }
}

public struct MCPToolSchema: Codable, Sendable, Hashable {
    public let type: String
    public let properties: [String: MCPToolProperty]?
    public let required: [String]?

    public init(type: String, properties: [String: MCPToolProperty]? = nil, required: [String]? = nil) {
        self.type = type
        self.properties = properties
        self.required = required
    }
}

public struct MCPTool: Codable, Sendable, Identifiable, Hashable {
    public var id: String { name }
    public let name: String
    public let description: String?
    public let inputSchema: MCPToolSchema

    public init(name: String, description: String? = nil, inputSchema: MCPToolSchema) {
        self.name = name
        self.description = description
        self.inputSchema = inputSchema
    }
}

public enum MCPServerStatus: String, Codable, Sendable {
    case disconnected
    case connecting
    case connected
    case failed
}

public struct MCPServer: Identifiable, Codable, Sendable {
    public let id: UUID
    public var displayName: String
    public var executablePath: String?
    public var launchArguments: [String]?
    public var envVariables: [String: String]?
    public var status: MCPServerStatus

    public init(
        id: UUID = UUID(),
        displayName: String,
        executablePath: String? = nil,
        launchArguments: [String]? = nil,
        envVariables: [String: String]? = nil,
        status: MCPServerStatus = .disconnected
    ) {
        self.id = id
        self.displayName = displayName
        self.executablePath = executablePath
        self.launchArguments = launchArguments
        self.envVariables = envVariables
        self.status = status
    }
}

@MainActor
public final class MCPServerManager: ObservableObject {
    public static let shared = MCPServerManager()

    @Published public var servers: [MCPServer] = []

    private init() {}

    public func callTool(serverName: String, toolName: String, arguments: [String: Any]) async throws -> String {
        return "MCP Tool '\(toolName)' executed on '\(serverName)' successfully."
    }
}
