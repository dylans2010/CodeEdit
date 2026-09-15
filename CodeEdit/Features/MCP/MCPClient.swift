//
//  MCPClient.swift
//  CodeEdit
//

import Foundation

// MARK: - JSON-RPC 2.0 Types

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
    public let jsonrpc: String
    public let id: JSONRPCID?
    public let method: String
    public let params: [String: String]?

    public init(id: JSONRPCID?, method: String, params: [String: String]? = nil) {
        self.jsonrpc = "2.0"
        self.id = id
        self.method = method
        self.params = params
    }
}

public struct JSONRPCResponse: Codable, Sendable {
    public let jsonrpc: String
    public let id: JSONRPCID?
    public let result: String?
    public let error: JSONRPCError?

    public var contentSummary: String {
        result ?? (error?.message ?? "No content returned")
    }
}

public struct JSONRPCNotification: Codable, Sendable {
    public let jsonrpc: String
    public let method: String
    public let params: [String: String]?

    public init(method: String, params: [String: String]? = nil) {
        self.jsonrpc = "2.0"
        self.method = method
        self.params = params
    }
}

public struct JSONRPCError: Codable, Sendable, Error {
    public let code: Int
    public let message: String
}

public enum MCPError: LocalizedError, Sendable {
    case invalidConfiguration(String)
    case connectionFailed(String)
    case requestValidationFailed(String)
    case decodingFailed(String)

    public var errorDescription: String? {
        switch self {
        case .invalidConfiguration(let msg),
             .connectionFailed(let msg),
             .requestValidationFailed(let msg),
             .decodingFailed(let msg):
            return msg
        }
    }
}

// MARK: - MCP Tool Schema

public struct MCPToolProperty: Codable, Sendable, Hashable {
    public let type: String
    public let description: String?
    public let `enum`: [String]?
}

public struct MCPToolSchema: Codable, Sendable, Hashable {
    public let type: String
    public let properties: [String: MCPToolProperty]?
    public let required: [String]?
}

public struct MCPTool: Codable, Sendable, Identifiable, Hashable {
    public var id: String { name }
    public let name: String
    public let description: String?
    public let inputSchema: MCPToolSchema
}

// MARK: - Transport Session Protocol

public protocol MCPTransportSession: Sendable {
    func connect(messageHandler: @escaping @Sendable (JSONRPCResponse) -> Void) async throws
    func send(request: JSONRPCRequest) async throws -> JSONRPCResponse
    func send(notification: JSONRPCNotification) async throws
    func disconnect()
}
