//
//  GitPorcelainModels.swift
//  CodeEdit
//
//

import Foundation

/// Git file status parsed from --porcelain=v2.
public struct GitPorcelainEntry: Identifiable, Sendable {
    public var id: String { path }
    public let stagedStatus: String // "M", "A", "D", "R", "."
    public let unstagedStatus: String // "M", "A", "D", "R", "?"
    public let path: String
    public let originalPath: String?

    public init(
        stagedStatus: String,
        unstagedStatus: String,
        path: String,
        originalPath: String? = nil
    ) {
        self.stagedStatus = stagedStatus
        self.unstagedStatus = unstagedStatus
        self.path = path
        self.originalPath = originalPath
    }
}

/// A conflict hunk within a conflicted source file.
public struct ConflictHunk: Identifiable, Sendable {
    public let id: UUID
    public let currentText: String
    public let incomingText: String
    public let baseText: String?
    public let startOffset: Int
    public let endOffset: Int

    public init(
        currentText: String,
        incomingText: String,
        baseText: String? = nil,
        startOffset: Int,
        endOffset: Int
    ) {
        self.id = UUID()
        self.currentText = currentText
        self.incomingText = incomingText
        self.baseText = baseText
        self.startOffset = startOffset
        self.endOffset = endOffset
    }
}

/// Resolution choice for a merge conflict hunk.
public enum ConflictResolutionAction: Sendable {
    case acceptCurrent
    case acceptIncoming
    case acceptBoth
    case custom(String)
}

/// Step types for the visual CI/CD pipeline workflow manager.
public enum WorkflowStepType: String, Codable, CaseIterable, Sendable {
    case checkout = "Checkout Repository"
    case shellCommand = "Shell Command"
    case runLinter = "Run Linter"
    case buildScheme = "Build Scheme"
    case runTests = "Run Test Target"
    case deploy = "Deploy Artifacts"
}

/// A configurable step in a CI/CD workflow pipeline.
public struct WorkflowStep: Identifiable, Codable, Sendable {
    public let id: UUID
    public var name: String
    public var stepType: WorkflowStepType
    public var command: String
    public var environmentVariables: [String: String]

    public init(
        name: String,
        stepType: WorkflowStepType,
        command: String = "",
        environmentVariables: [String: String] = [:]
    ) {
        self.id = UUID()
        self.name = name
        self.stepType = stepType
        self.command = command
        self.environmentVariables = environmentVariables
    }
}
