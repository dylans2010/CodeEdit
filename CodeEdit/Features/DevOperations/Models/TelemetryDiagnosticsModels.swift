//
//  TelemetryDiagnosticsModels.swift
//  CodeEdit
//
//

import Foundation

/// Realtime process hardware and performance telemetry snapshot.
public struct PerformanceMetricsSnapshot: Sendable {
    public let timestamp: Date
    public let cpuUsagePercent: Double
    public let memoryUsageMB: Double
    public let diskReadMBPerSec: Double
    public let diskWriteMBPerSec: Double
    public let networkInKBPerSec: Double
    public let networkOutKBPerSec: Double
    public let fps: Double

    public init(
        cpuUsagePercent: Double = 12.5,
        memoryUsageMB: Double = 148.2,
        diskReadMBPerSec: Double = 1.2,
        diskWriteMBPerSec: Double = 0.5,
        networkInKBPerSec: Double = 24.1,
        networkOutKBPerSec: Double = 8.4,
        fps: Double = 60.0
    ) {
        self.timestamp = Date()
        self.cpuUsagePercent = cpuUsagePercent
        self.memoryUsageMB = memoryUsageMB
        self.diskReadMBPerSec = diskReadMBPerSec
        self.diskWriteMBPerSec = diskWriteMBPerSec
        self.networkInKBPerSec = networkInKBPerSec
        self.networkOutKBPerSec = networkOutKBPerSec
        self.fps = fps
    }
}

/// Description of an active thread or dispatch queue.
public struct ThreadDiagnosticInfo: Identifiable, Sendable {
    public var id: Int { threadNumber }
    public let threadNumber: Int
    public let threadName: String
    public let isMainThread: Bool
    public let queueName: String
    public let topStackFrame: String

    public init(
        threadNumber: Int,
        threadName: String,
        isMainThread: Bool,
        queueName: String,
        topStackFrame: String
    ) {
        self.threadNumber = threadNumber
        self.threadName = threadName
        self.isMainThread = isMainThread
        self.queueName = queueName
        self.topStackFrame = topStackFrame
    }
}

/// Mach-O binary analysis results from lipo, otool, and nm.
public struct MachOBinaryAnalysis: Sendable {
    public let architectures: [String] // "arm64", "x86_64"
    public let linkedLibraries: [String]
    public let symbolsCount: Int
    public let hasCodeSignature: Bool

    public init(
        architectures: [String],
        linkedLibraries: [String],
        symbolsCount: Int,
        hasCodeSignature: Bool
    ) {
        self.architectures = architectures
        self.linkedLibraries = linkedLibraries
        self.symbolsCount = symbolsCount
        self.hasCodeSignature = hasCodeSignature
    }
}

/// Network inspector HTTP transaction capture.
public struct CapturedNetworkTransaction: Identifiable, Sendable {
    public let id: UUID
    public let method: String
    public let urlString: String
    public let statusCode: Int
    public let duration: TimeInterval
    public let responseSize: Int

    public init(
        method: String,
        urlString: String,
        statusCode: Int,
        duration: TimeInterval,
        responseSize: Int
    ) {
        self.id = UUID()
        self.method = method
        self.urlString = urlString
        self.statusCode = statusCode
        self.duration = duration
        self.responseSize = responseSize
    }
}

/// Feature flag item with developer override toggles.
public struct FeatureFlagItem: Identifiable, Sendable {
    public var id: String { key }
    public let key: String
    public let displayName: String
    public var isEnabled: Bool

    public init(key: String, displayName: String, isEnabled: Bool = false) {
        self.key = key
        self.displayName = displayName
        self.isEnabled = isEnabled
    }
}
