//
//  WorkspaceBuildManager.swift
//  CodeEdit
//
//

// swiftlint:disable line_length

import Foundation
import Combine
import SwiftUI

/// Observable manager coordinating xcodebuild executions and workspace diagnostics for the Issues sidebar.
@MainActor
public final class WorkspaceBuildManager: ObservableObject {
    public static let shared = WorkspaceBuildManager()

    @Published public var isBuilding: Bool = false
    @Published public var currentStatus: String = "Ready to build"
    @Published public var lastResult: BuildExecutionResult?
    @Published public var diagnostics: [CompilerDiagnostic] = []
    @Published public var linkerErrors: [LinkerDiagnostic] = []
    @Published public var availableSchemes: [String] = []
    @Published public var selectedScheme: String = ""
    @Published public var selectedConfiguration: String = "Debug"
    @Published public var buildDuration: TimeInterval = 0
    @Published public var lastBuildDate: Date?

    public var errorCount: Int {
        diagnostics.filter { $0.severity == .error }.count + linkerErrors.count
    }

    public var warningCount: Int {
        diagnostics.filter { $0.severity == .warning }.count
    }

    public var noteCount: Int {
        diagnostics.filter { $0.severity == .note }.count
    }

    private init() {}

    /// Loads available schemes for the workspace URL.
    public func loadSchemes(workspaceURL: URL) async {
        let schemes = await XcodeBuildService.shared.listSchemes(projectURL: workspaceURL)
        self.availableSchemes = schemes
        if self.selectedScheme.isEmpty || !schemes.contains(self.selectedScheme) {
            self.selectedScheme = schemes.first ?? workspaceURL.lastPathComponent
        }
    }

    /// Triggers `xcodebuild` on the specified workspace project.
    public func build(workspaceURL: URL) async {
        guard !isBuilding else { return }
        isBuilding = true
        currentStatus = "Building \(selectedScheme.isEmpty ? workspaceURL.lastPathComponent : selectedScheme)..."

        if availableSchemes.isEmpty {
            await loadSchemes(workspaceURL: workspaceURL)
        }

        let config = BuildConfiguration(
            scheme: selectedScheme,
            configuration: selectedConfiguration
        )

        do {
            let result = try await XcodeBuildService.shared.build(projectURL: workspaceURL, config: config)
            self.lastResult = result
            self.diagnostics = result.diagnostics
            self.linkerErrors = result.linkerErrors
            self.buildDuration = result.duration
            self.lastBuildDate = Date()
            self.isBuilding = false

            if result.isSuccess {
                let warnMsg = warningCount > 0 ? " with \(warningCount) warning(s)" : ""
                self.currentStatus = "Build Succeeded\(warnMsg)"
            } else {
                let errs = errorCount > 0 ? "\(errorCount) error(s)" : "Issues encountered"
                self.currentStatus = "Build Failed: \(errs)"
            }
        } catch {
            self.isBuilding = false
            self.lastBuildDate = Date()
            let errMsg = error.localizedDescription
            self.currentStatus = "Build Failed"
            self.diagnostics = [CompilerDiagnostic(
                filePath: "xcodebuild",
                lineNumber: 1,
                columnOffset: 1,
                severity: .error,
                message: errMsg
            )]
        }
    }

    /// Triggers `xcodebuild clean`.
    public func clean(workspaceURL: URL) async {
        guard !isBuilding else { return }
        isBuilding = true
        currentStatus = "Cleaning build folder..."

        let scheme = selectedScheme.isEmpty ? workspaceURL.lastPathComponent : selectedScheme
        do {
            _ = try await XcodeBuildService.shared.clean(projectURL: workspaceURL, scheme: scheme)
            self.isBuilding = false
            self.currentStatus = "Clean Succeeded"
            self.diagnostics = []
            self.linkerErrors = []
            self.lastResult = nil
        } catch {
            self.isBuilding = false
            self.currentStatus = "Clean Failed: \(error.localizedDescription)"
        }
    }
}
