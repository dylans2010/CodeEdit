//
//  SwiftCodeConnectProtocol.swift
//  UniversalIDE
//

import Foundation

public struct ConnectMessageEnvelope<T: Codable & Sendable>: Codable, Sendable {
    public let protocolVersion: Int = 1
    public let messageID: UUID
    public let correlationID: UUID?
    public let type: String
    public let timestamp: Date
    public let payload: T

    public init(
        messageID: UUID = UUID(),
        correlationID: UUID? = nil,
        type: String,
        timestamp: Date = Date(),
        payload: T
    ) {
        self.messageID = messageID
        self.correlationID = correlationID
        self.type = type
        self.timestamp = timestamp
        self.payload = payload
    }
}

public struct PairingChallengeRequest: Codable, Sendable {
    public let deviceID: String
    public let deviceModel: String
    public let userName: String

    public init(deviceID: String, deviceModel: String, userName: String) {
        self.deviceID = deviceID
        self.deviceModel = deviceModel
        self.userName = userName
    }
}

public struct PairingChallengeResponse: Codable, Sendable {
    public let isApproved: Bool
    public let sessionToken: String?

    public init(isApproved: Bool, sessionToken: String? = nil) {
        self.isApproved = isApproved
        self.sessionToken = sessionToken
    }
}

public struct CompanionDevicePermissions: Codable, Sendable {
    public var projectRead: Bool = true
    public var gitRead: Bool = true
    public var buildExecute: Bool = true
    public var testsExecute: Bool = true
    public var logsRead: Bool = true
    public var terminalExecute: Bool = false
    public var filesRead: Bool = true
    public var filesWrite: Bool = true
    public var assistUse: Bool = true

    public init() {}
}

@MainActor
public final class SwiftCodeConnectServer: ObservableObject {
    public static let shared = SwiftCodeConnectServer()

    @Published public var isBonjourPublishing: Bool = false
    @Published public var connectedClients: [String: CompanionDevicePermissions] = [:]

    private init() {}

    public func startBonjourService() {
        // Publishes _swiftcodeconnect._tcp on TCP port 8088
        isBonjourPublishing = true
    }

    public func verifyPinChallenge(enteredPin: String, expectedPin: String) -> Bool {
        return enteredPin == expectedPin
    }
}
