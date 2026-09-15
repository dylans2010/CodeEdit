//
//  StdioTransportSession.swift
//  CodeEdit
//

import Foundation

public struct MCPServerConfig: Identifiable, Codable, Sendable {
    public let id: UUID
    public var displayName: String
    public var executablePath: String?
    public var launchArguments: [String]?
    public var envVariables: [String: String]?

    public init(
        id: UUID = UUID(),
        displayName: String,
        executablePath: String? = nil,
        launchArguments: [String]? = nil,
        envVariables: [String: String]? = nil
    ) {
        self.id = id
        self.displayName = displayName
        self.executablePath = executablePath
        self.launchArguments = launchArguments
        self.envVariables = envVariables
    }
}

public final class StdioTransportSession: MCPTransportSession, @unchecked Sendable {
    private let server: MCPServerConfig
    private let lock = NSLock()
    private var activeProcess: Process?
    private var writePipe: Pipe?
    private var stdioOutputTask: Task<Void, Never>?
    private var pendingRequests: [Int: CheckedContinuation<JSONRPCResponse, Error>] = [:]

    public init(server: MCPServerConfig) {
        self.server = server
    }

    public func connect(messageHandler: @escaping @Sendable (JSONRPCResponse) -> Void) async throws {
        guard let exePath = server.executablePath, !exePath.isEmpty else {
            throw MCPError.invalidConfiguration("Executable path is missing for stdio transport")
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: exePath)
        process.arguments = server.launchArguments ?? []

        var fullEnv = ProcessInfo.processInfo.environment
        if let envVars = server.envVariables {
            for (key, value) in envVars { fullEnv[key] = value }
        }
        process.environment = fullEnv

        let inPipe = Pipe()
        let outPipe = Pipe()
        let errPipe = Pipe()

        process.standardInput = inPipe
        process.standardOutput = outPipe
        process.standardError = errPipe

        try process.run()

        lock.lock()
        self.activeProcess = process
        self.writePipe = inPipe
        lock.unlock()

        let outputHandle = outPipe.fileHandleForReading
        let task = Task.detached { [weak self] in
            guard let self = self else { return }
            do {
                for try await line in outputHandle.bytes.lines {
                    guard let data = line.data(using: .utf8) else { continue }
                    if let response = try? JSONDecoder().decode(JSONRPCResponse.self, from: data) {
                        if let rpcID = response.id, let idVal = rpcID.integerValue {
                            self.lock.lock()
                            let continuation = self.pendingRequests.removeValue(forKey: idVal)
                            self.lock.unlock()
                            continuation?.resume(returning: response)
                        } else {
                            messageHandler(response)
                        }
                    }
                }
            } catch {
                DiagnosticEventBus.shared.logEvent(
                    component: "StdioTransportSession",
                    severity: "ERROR",
                    category: "stream",
                    message: "Stdio stream closed: \(error.localizedDescription)"
                )
            }
        }

        lock.lock()
        self.stdioOutputTask = task
        lock.unlock()
    }

    public func send(request: JSONRPCRequest) async throws -> JSONRPCResponse {
        lock.lock()
        guard let writeHandle = writePipe?.fileHandleForWriting else {
            lock.unlock()
            throw MCPError.connectionFailed("Stdio pipe unavailable.")
        }
        lock.unlock()

        let data = try JSONEncoder().encode(request)
        guard var lineData = String(data: data, encoding: .utf8) else {
            throw MCPError.decodingFailed("Failed to encode request payload.")
        }
        lineData += "\n"

        guard let reqID = request.id?.integerValue else {
            throw MCPError.requestValidationFailed("Request missing integer ID")
        }

        return try await withCheckedThrowingContinuation { continuation in
            lock.lock()
            pendingRequests[reqID] = continuation
            lock.unlock()
            do {
                try writeHandle.write(contentsOf: lineData.data(using: .utf8)!)
            } catch {
                lock.lock()
                _ = pendingRequests.removeValue(forKey: reqID)
                lock.unlock()
                continuation.resume(throwing: error)
            }
        }
    }

    public func send(notification: JSONRPCNotification) async throws {
        lock.lock()
        guard let writeHandle = writePipe?.fileHandleForWriting else {
            lock.unlock()
            throw MCPError.connectionFailed("Stdio pipe unavailable.")
        }
        lock.unlock()

        let data = try JSONEncoder().encode(notification)
        if var lineData = String(data: data, encoding: .utf8) {
            lineData += "\n"
            try writeHandle.write(contentsOf: lineData.data(using: .utf8)!)
        }
    }

    public func disconnect() {
        lock.lock()
        defer { lock.unlock() }

        stdioOutputTask?.cancel()
        stdioOutputTask = nil
        activeProcess?.terminate()
        activeProcess = nil
        writePipe = nil
    }
}
