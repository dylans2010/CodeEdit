//
//  AssistEngineToolsSuite.swift
//  UniversalIDE
//

import Foundation

public struct AssistToolResult: Sendable {
    public let success: Bool
    public let output: String

    public init(success: Bool, output: String) {
        self.success = success
        self.output = output
    }

    public static func success(_ message: String) -> AssistToolResult {
        AssistToolResult(success: true, output: message)
    }

    public static func failure(_ message: String) -> AssistToolResult {
        AssistToolResult(success: false, output: message)
    }
}

public protocol AssistToolProtocol: Sendable {
    var toolID: String { get }
    var displayName: String { get }
    var usageDescription: String { get }
    func execute(input: [String: Any]) async throws -> AssistToolResult
}

public struct AssistToolBase: AssistToolProtocol {
    public let toolID: String
    public let displayName: String
    public let usageDescription: String

    public init(toolID: String, displayName: String, usageDescription: String = "") {
        self.toolID = toolID
        self.displayName = displayName
        self.usageDescription = usageDescription
    }

    public func execute(input: [String: Any]) async throws -> AssistToolResult {
        return .success("Executed internal assist tool '\(toolID)'.")
    }
}

public final class AssistToolCatalog: @unchecked Sendable {
    public static let shared = AssistToolCatalog()
    public private(set) var tools: [String: AssistToolProtocol] = [:]

    private init() {
        registerTools()
    }

    private func registerTools() {
        let toolIDs = [
            "AssistReadFileTool", "AssistWriteFileTool", "AssistAppendFileTool", "AssistInsertCodeBlockTool",
            "AssistReplaceInFileTool", "AssistMultiFileEditTool", "AssistDeleteFileTool", "AssistCopyFileTool",
            "AssistMoveFileTool", "AssistRenameFileTool", "AssistCreateFileTool", "AssistCreateDirectoryTool",
            "AssistDeleteDirectoryTool", "AssistReadDirectoryTool", "AssistTreeViewTool", "AssistSearchTool",
            "AssistRegexSearchTool", "AssistSymbolSearchTool", "AssistDiffTool", "AssistPatchApplicationEngine",
            "AssistUndoTool", "AssistSnapshotProjectTool", "AssistRestoreSnapshotTool", "AssistValidateChangesTool",
            "AssistFormatCodeTool", "AssistLintTool", "AssistAutoFixErrorsTool", "AssistBuildProjectTool",
            "AssistTestRunnerTool", "AssistTaskRunnerTool", "AssistEnvironmentInfoTool", "AssistExplainCodeTool",
            "AssistRefactorTool", "AssistGenerateFileTool", "AssistGenerateTestsTool", "AssistPlanTaskTool",
            "AssistBreakdownTaskTool", "AssistCodeSummaryTool", "AssistComplexityAnalysisTool", "AssistDependencyGraphTool",
            "AssistLogCaptureTool", "AssistStoreMemoryTool", "AssistRetrieveMemoryTool", "AssistClearMemoryTool",
            "AssistContextSnapshotTool", "AssistChangeLogTool", "AssistVersionControlOperator", "AssistProjectMutationController",
            "AssistAutomatedRepairEngine", "AssistAutonomousReviewEngine", "AssistCodeMutationEngine", "AssistCompilerDiagnosticsEngine",
            "AssistContextPersistenceStore", "AssistDependencyResolutionEngine", "AssistExternalResourceGateway", "AssistRuntimeDiagnosticsEngine",
            "AssistSemanticQueryEngine", "AssistSourceGraphBuilder", "AssistToolingSupport", "AssistTool",
            "CodeReview", "UseMCP", "UseTermFunction"
        ]

        for id in toolIDs {
            tools[id] = AssistToolBase(toolID: id, displayName: id)
        }
    }
}
