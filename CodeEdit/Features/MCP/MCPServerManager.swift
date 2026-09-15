//
//  MCPServerManager.swift
//  CodeEdit
//

import Foundation
import Combine

public enum MCPServerStatus: String, Codable, Sendable {
    case disconnected = "Disconnected"
    case connecting   = "Connecting"
    case connected    = "Connected"
    case failed       = "Failed"
}

public struct MCPServerInstance: Identifiable, Sendable {
    public let config: MCPServerConfig
    public var id: UUID { config.id }
    public var status: MCPServerStatus
    public var discoveredTools: [MCPTool]

    public init(config: MCPServerConfig, status: MCPServerStatus = .disconnected, discoveredTools: [MCPTool] = []) {
        self.config = config
        self.status = status
        self.discoveredTools = discoveredTools
    }
}

@MainActor
public final class MCPServerManager: ObservableObject {
    public static let shared = MCPServerManager()

    @Published public private(set) var servers: [MCPServerInstance] = []
    private var activeSessions: [UUID: StdioTransportSession] = [:]

    private init() {
        loadPersistedServers()
    }

    public func addServer(displayName: String, executablePath: String, arguments: [String] = []) {
        let config = MCPServerConfig(
            displayName: displayName,
            executablePath: executablePath,
            launchArguments: arguments
        )
        let instance = MCPServerInstance(config: config)
        servers.append(instance)
        saveServers()
    }

    public func connect(to serverID: UUID) async throws {
        guard let index = servers.firstIndex(where: { $0.id == serverID }) else { return }
        servers[index].status = .connecting

        let config = servers[index].config
        let session = StdioTransportSession(server: config)
        activeSessions[serverID] = session

        do {
            try await session.connect { [weak self] response in
                DiagnosticEventBus.shared.logEvent(
                    component: "MCPServerManager",
                    severity: "INFO",
                    category: "mcp_message",
                    message: "Received MCP message: \(response.contentSummary)"
                )
            }

            // Perform initialize handshake
            let initRequest = JSONRPCRequest(id: .integer(1), method: "initialize", params: ["protocolVersion": "2024-11-05"])
            let initResponse = try await session.send(request: initRequest)

            // Initialized notification
            try await session.send(notification: JSONRPCNotification(method: "notifications/initialized"))

            servers[index].status = .connected
            DiagnosticEventBus.shared.logEvent(
                component: "MCPServerManager",
                severity: "INFO",
                category: "mcp_connect",
                message: "MCP Server '\(config.displayName)' connected: \(initResponse.contentSummary)"
            )
        } catch {
            servers[index].status = .failed
            throw error
        }
    }

    public func disconnect(serverID: UUID) {
        if let session = activeSessions.removeValue(forKey: serverID) {
            session.disconnect()
        }
        if let index = servers.firstIndex(where: { $0.id == serverID }) {
            servers[index].status = .disconnected
        }
    }

    public func callTool(serverName: String, toolName: String, arguments: [String: String]) async throws -> String {
        guard let server = servers.first(where: { $0.config.displayName.lowercased() == serverName.lowercased() }),
              let session = activeSessions[server.id] else {
            throw MCPError.connectionFailed("Server '\(serverName)' not connected.")
        }

        let request = JSONRPCRequest(id: .integer(Int.random(in: 100...9999)), method: "tools/call", params: arguments)
        let response = try await session.send(request: request)
        return response.contentSummary
    }

    private var persistenceURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let directory = appSupport.appendingPathComponent("CodeEdit", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent("mcp_servers.json")
    }

    public func loadPersistedServers() {
        guard let data = try? Data(contentsOf: persistenceURL),
              let configs = try? JSONDecoder().decode([MCPServerConfig].self, from: data) else {
            return
        }
        self.servers = configs.map { MCPServerInstance(config: $0) }
    }

    private func saveServers() {
        let configs = servers.map { $0.config }
        guard let data = try? JSONEncoder().encode(configs) else { return }
        try? data.write(to: persistenceURL)
    }
}

// MARK: - UseMCP Tool
public struct UseMCPTool: AssistTool {
    public let id = "use_mcp"
    public let name = "Execute MCP Tool"
    public let description = "Executes a tool on a connected Model Context Protocol (MCP) server."

    public var parametersSchema: JSONSchema {
        JSONSchema(
            type: "object",
            properties: [
                "serverName": JSONSchemaProperty(type: "string", description: "The name of the connected MCP server."),
                "toolName": JSONSchemaProperty(type: "string", description: "The name of the target tool."),
                "arguments": JSONSchemaProperty(type: "string", description: "JSON-serialized object string of arguments.")
            ],
            required: ["serverName", "toolName", "arguments"]
        )
    }

    public init() {}

    public func execute(input: [String: Any], context: AssistContext) async throws -> AssistToolResult {
        guard let serverName = input["serverName"] as? String,
              let toolName = input["toolName"] as? String else {
            return .failure("Missing required arguments (serverName, toolName).")
        }

        do {
            let res = try await MCPServerManager.shared.callTool(serverName: serverName, toolName: toolName, arguments: [:])
            return .success(res)
        } catch {
            return .failure("MCP invocation error: \(error.localizedDescription)")
        }
    }
}
