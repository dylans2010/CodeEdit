//
//  DeviceConnectModels.swift
//  CodeEdit
//
//

import Foundation

/// Represents a connected physical Apple device.
public struct ConnectedPhysicalDevice: Identifiable, Codable, Sendable, Hashable {
    public var id: String { identifier }
    public let identifier: String
    public let name: String
    public let model: String
    public let osVersion: String
    public let platform: String // "iOS", "iPadOS", "watchOS", "tvOS", "visionOS"
    public let connectionType: String // "USB", "WiFi"
    public let isPaired: Bool

    public init(
        identifier: String,
        name: String,
        model: String,
        osVersion: String,
        platform: String = "iOS",
        connectionType: String = "USB",
        isPaired: Bool = true
    ) {
        self.identifier = identifier
        self.name = name
        self.model = model
        self.osVersion = osVersion
        self.platform = platform
        self.connectionType = connectionType
        self.isPaired = isPaired
    }
}

/// A line in the device sysdiagnose / unified log stream.
public struct SysdiagnoseLogEntry: Identifiable, Codable, Sendable {
    public let id: UUID
    public let timestamp: Date
    public let subsystem: String
    public let processID: Int
    public let message: String

    public init(
        subsystem: String,
        processID: Int,
        message: String,
        timestamp: Date = Date()
    ) {
        self.id = UUID()
        self.timestamp = timestamp
        self.subsystem = subsystem
        self.processID = processID
        self.message = message
    }
}

/// SwiftCode Connect Protocol V1 message envelope.
public struct SwiftCodeConnectEnvelope: Codable, Sendable {
    public let protocolVersion: Int
    public let messageID: UUID
    public let correlationID: UUID?
    public let type: String
    public let timestamp: Date
    public let payload: [String: String]

    public init(
        type: String,
        correlationID: UUID? = nil,
        payload: [String: String] = [:]
    ) {
        self.protocolVersion = 1
        self.messageID = UUID()
        self.correlationID = correlationID
        self.type = type
        self.timestamp = Date()
        self.payload = payload
    }
}

/// Granular permissions assigned to paired companion devices.
public struct CompanionPermissions: Codable, Sendable {
    public var canReadProject: Bool
    public var canReadGit: Bool
    public var canExecuteBuild: Bool
    public var canExecuteTests: Bool
    public var canReadLogs: Bool
    public var canExecuteTerminal: Bool
    public var canReadFiles: Bool
    public var canWriteFiles: Bool
    public var canUseAssist: Bool

    public init(
        canReadProject: Bool = true,
        canReadGit: Bool = true,
        canExecuteBuild: Bool = true,
        canExecuteTests: Bool = true,
        canReadLogs: Bool = true,
        canExecuteTerminal: Bool = false,
        canReadFiles: Bool = true,
        canWriteFiles: Bool = false,
        canUseAssist: Bool = true
    ) {
        self.canReadProject = canReadProject
        self.canReadGit = canReadGit
        self.canExecuteBuild = canExecuteBuild
        self.canExecuteTests = canExecuteTests
        self.canReadLogs = canReadLogs
        self.canExecuteTerminal = canExecuteTerminal
        self.canReadFiles = canReadFiles
        self.canWriteFiles = canWriteFiles
        self.canUseAssist = canUseAssist
    }
}

/// A paired companion device in the Trust Store.
public struct PairedCompanionDevice: Identifiable, Codable, Sendable {
    public var id: String { deviceID }
    public let deviceID: String
    public let deviceName: String
    public let model: String
    public let token: String
    public var permissions: CompanionPermissions
    public let pairedDate: Date

    public init(
        deviceID: String,
        deviceName: String,
        model: String,
        token: String,
        permissions: CompanionPermissions = CompanionPermissions(),
        pairedDate: Date = Date()
    ) {
        self.deviceID = deviceID
        self.deviceName = deviceName
        self.model = model
        self.token = token
        self.permissions = permissions
        self.pairedDate = pairedDate
    }
}
