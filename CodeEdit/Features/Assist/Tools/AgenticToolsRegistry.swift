//
//  AgenticToolsRegistry.swift
//  CodeEdit
//

import Foundation

public final class AgenticToolsRegistry: @unchecked Sendable {
    public static let shared = AgenticToolsRegistry()

    private let lock = NSLock()
    private var tools: [String: any ExecutableTool] = [:]

    private init() {
        registerDefaultTools()
    }

    private func registerDefaultTools() {
        let defaultToolList: [any ExecutableTool] = [
            // File & Directory (14)
            CreateFileTool(), ReadFileTool(), ReadMultipleFilesTool(), EditFileTool(),
            WriteFileTool(), CopyFileTool(), MoveFileTool(), DeleteFileTool(),
            CreateDirectoryTool(), DeleteDirectoryTool(), ListDirectoryTool(),
            DownloadFileTool(), UploadFileTool(), TreeViewTool(),

            // Search & Indexing (11)
            FindTextTool(), ReplaceTextTool(), GrepTool(), GlobSearchTool(),
            SearchFilesTool(), CodeIndexTool(), SemanticCodeSearchTool(),
            CrossReferenceSearchTool(), CallHierarchyTool(), DocumentationSearchTool(),
            APIReferenceSearchTool(),

            // Git (20)
            GitStatusTool(), GitAddTool(), GitCommitTool(), GitDiffTool(), GitLogTool(),
            GitBranchTool(), GitCheckoutTool(), GitPullTool(), GitPushTool(), GitMergeTool(),
            GitRebaseTool(), GitCherryPickTool(), GitStashTool(), GitResetTool(),
            GitRevertTool(), GitBlameTool(), GitShowTool(), GitTagTool(),
            GitWorktreeTool(), GitCloneTool(),

            // Build, Compilers & Static Analysis (12)
            XcodeBuildTool(), SwiftPackageManagerTool(), AndroidBuildTool(), RunBuildTool(),
            ReadBuildLogsTool(), RunLinterTool(), RunFormatterTool(), RunTypeCheckerTool(),
            RunStaticAnalysisTool(), CodeAnalysisTool(), DetectBugsTool(), FixBugsTool(),

            // Testing & QA (4)
            RunTestsTool(), GenerateUnitTestsTool(), GenerateIntegrationTestsTool(), RunBenchmarkTool(),

            // Package Managers (18)
            InstallDependenciesTool(), UpdateDependenciesTool(), RemoveDependenciesTool(),
            DependencyAuditTool(), DependencyGraphTool(), PackageSearchTool(), CocoaPodsTool(),
            CarthageTool(), NpmTool(), YarnTool(), PnpmTool(), BunTool(), PythonPipTool(),
            CargoTool(), GoBuildTool(), GradleTool(), JavaMavenTool(), DotNetCLITool(),

            // Containers & Mobile (8)
            DockerBuildTool(), DockerRunTool(), DockerComposeTool(), ViewContainerLogsTool(),
            KubernetesApplyTool(), ReactNativeTool(), FlutterTool(), ExpoTool(),

            // Database (3)
            SQLQueryTool(), DatabaseSchemaInspectorTool(), DatabaseMigrationTool(),

            // System, Shell & Net (12)
            ExecuteTerminalCommandTool(), StopRunningProcessTool(), GetProcessLogsTool(),
            RunApplicationTool(), ReadEnvironmentVariablesTool(), UpdateEnvironmentVariablesTool(),
            HTTPRequestTool(), FetchURLTool(), WebSearchTool(), OpenBrowserTool(),
            BrowserAutomationTool(), NetworkInspectorTool(),

            // Diagnostics & Profiling (8)
            CrashAnalyzerTool(), SymbolicateCrashLogsTool(), PerformanceProfilerTool(),
            MemoryProfilerTool(), UIInspectorTool(), AccessibilityInspectorTool(),
            LicenseScanTool(), SecurityScanTool(),

            // Code Gen & Docs (6)
            GenerateCodeTool(), ExplainCodeTool(), RefactorCodeTool(), ReviewCodeTool(),
            GenerateDocumentationTool(), GenerateCommentsTool(),

            // GitHub PRs & Issues (7)
            ReadIssuesTool(), CreateIssueTool(), UpdateIssueTool(), SearchIssuesTool(),
            ReadPullRequestTool(), CreatePullRequestTool(), ReviewPullRequestTool(),

            // Data Parsing (4)
            ParseJSONTool(), ParseXMLTool(), ParseYAMLTool(), ParseMarkdownTool(),

            // State & Memory (14)
            TaskPlannerTool(), ChecklistPlanTool(), ProgressTrackerTool(), AskUserTool(),
            QuestionHandlerTool(), AIContextMemoryTool(), CheckpointCreatorTool(),
            RollbackChangesTool(), TodoManagerTool(), ProjectAuditTool(),
            ProjectIndexingTool(), ManageSecretsTool(), TakeScreenshotTool(), ListToolsTool()
        ]

        for tool in defaultToolList {
            tools[tool.name] = tool
        }
    }

    public func tool(named name: String) -> (any ExecutableTool)? {
        lock.lock()
        defer { lock.unlock() }
        return tools[name]
    }

    public func getAllToolNames() -> [String] {
        lock.lock()
        defer { lock.unlock() }
        return Array(tools.keys).sorted()
    }

    public func getToolsSummary() -> String {
        lock.lock()
        defer { lock.unlock() }
        return tools.values.map { "- \($0.name): \($0.description)" }.sorted().joined(separator: "\n")
    }
}
