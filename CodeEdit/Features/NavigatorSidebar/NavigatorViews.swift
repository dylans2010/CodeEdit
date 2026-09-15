//
//  NavigatorViews.swift
//  CodeEdit
//
//

// swiftlint:disable file_length type_body_length line_length function_body_length

import SwiftUI

/// Represents an audited package dependency item.
struct PinnedDependencyItem: Hashable, Identifiable {
    var id: String { name }
    let name: String
    let version: String
    let url: String
}

/// Represents an AST parsed symbol item.
struct ParsedSymbolItem: Hashable, Identifiable {
    var id: String { name }
    let name: String
    let kind: String
    let icon: String
}

// MARK: - Dependencies Navigator View
struct DependenciesNavigatorView: View {
    @EnvironmentObject var workspace: WorkspaceDocument
    @State private var searchText = ""
    @State private var dependencies: [ScannedDependencyItem] = []
    @State private var isScanning = false
    @State private var showAddSheet = false

    var filteredDependencies: [ScannedDependencyItem] {
        if searchText.isEmpty {
            return dependencies
        }
        return dependencies.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.urlOrPath.localizedCaseInsensitiveContains(searchText) ||
            $0.versionOrRequirement.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            headerBar
            Divider()
            searchBar

            if isScanning && dependencies.isEmpty {
                VStack(spacing: 10) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Scanning Package.swift & Xcode projects...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if dependencies.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "shippingbox")
                        .font(.system(size: 32))
                        .foregroundStyle(.secondary)
                    Text("No Dependencies Found")
                        .font(.headline)
                    Text("No Swift packages found in Package.swift or Xcode project files.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)

                    Button("Add Package...") {
                        showAddSheet = true
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .padding(.top, 6)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    Section {
                        ForEach(filteredDependencies) { dependency in
                            HStack(spacing: 8) {
                                Image(systemName: "shippingbox.fill")
                                    .foregroundColor(dependency.origin == .xcodeProject ? .orange : .accentColor)
                                    .font(.system(size: 13))

                                VStack(alignment: .leading, spacing: 2) {
                                    HStack(spacing: 4) {
                                        Text(dependency.name)
                                            .font(.system(size: 12, weight: .medium))
                                        originBadge(for: dependency.origin)
                                    }

                                    HStack(spacing: 4) {
                                        Text(dependency.versionOrRequirement)
                                            .font(.system(size: 10, weight: .semibold))
                                            .foregroundColor(.primary)

                                        if let resolved = dependency.resolvedVersion, resolved != dependency.versionOrRequirement {
                                            Text("(\(resolved))")
                                                .font(.system(size: 10))
                                                .foregroundColor(.secondary)
                                        }

                                        Text("• \(dependency.urlOrPath)")
                                            .font(.system(size: 10))
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                    }
                                }
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.system(size: 11))
                            }
                            .padding(.vertical, 3)
                        }
                    } header: {
                        HStack {
                            Text("Packages")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(filteredDependencies.count)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .listStyle(.sidebar)
            }
        }
        .task {
            await loadDependencies()
        }
        .sheet(isPresented: $showAddSheet) {
            if let workspaceURL = workspace.fileURL {
                AddPackageDependencyView(
                    workspaceURL: workspaceURL,
                    isPresented: $showAddSheet
                ) {
                    Task {
                        await loadDependencies()
                    }
                }
            }
        }
    }

    private var headerBar: some View {
        HStack {
            Text("Dependencies")
                .font(.system(size: 12, weight: .semibold))
            Spacer()

            Button {
                Task { await loadDependencies() }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 11))
            }
            .buttonStyle(.plain)
            .help("Refresh dependencies")

            Button {
                showAddSheet = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 11))
            }
            .buttonStyle(.plain)
            .help("Add Package Dependency...")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
    }

    private func originBadge(for origin: DependencyOrigin) -> some View {
        Text(origin == .packageSwift ? "SPM" : origin == .xcodeProject ? "Xcode" : "Resolved")
            .font(.system(size: 8, weight: .bold))
            .padding(.horizontal, 4)
            .padding(.vertical, 1)
            .background(
                origin == .packageSwift ? Color.blue.opacity(0.15) :
                origin == .xcodeProject ? Color.orange.opacity(0.15) : Color.gray.opacity(0.15)
            )
            .foregroundColor(
                origin == .packageSwift ? .blue :
                origin == .xcodeProject ? .orange : .secondary
            )
            .cornerRadius(3)
    }

    private func loadDependencies() async {
        guard let workspaceURL = workspace.fileURL else { return }
        isScanning = true
        let items = await WorkspaceDependencyService.shared.scanDependencies(in: workspaceURL)
        await MainActor.run {
            self.dependencies = items
            self.isScanning = false
        }
    }

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
                .font(.system(size: 11))
            TextField("Filter Dependencies", text: $searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 12))
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.system(size: 11))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(6)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(6)
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
    }
}

// MARK: - Tests Navigator View
struct TestsNavigatorView: View {
    @EnvironmentObject var workspace: WorkspaceDocument
    @State private var isRunningTests = false
    @State private var testResultsText: String = "Ready to run tests"
    @State private var testSuccess: Bool = true

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Test Navigator")
                    .font(.system(size: 12, weight: .semibold))
                Spacer()
                Button {
                    executeTests()
                } label: {
                    Label(
                        isRunningTests ? "Running..." : "Run Tests",
                        systemImage: isRunningTests ? "hourglass" : "play.fill"
                    )
                    .font(.system(size: 11))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(isRunningTests)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)

            Divider()

            VStack(spacing: 12) {
                if isRunningTests {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Executing workspace test suites via SwiftPM...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Image(systemName: testSuccess ? "checkmark.seal.fill" : "xmark.seal.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(testSuccess ? .green : .red)
                    Text(testSuccess ? "All Tests Passed" : "Tests Encountered Issues")
                        .font(.headline)
                    Text(testResultsText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func executeTests() {
        isRunningTests = true
        let path = workspace.fileURL?.path ?? "."
        Task {
            let result = await SwiftPackageBuildService.shared.runTests(projectPath: path)
            await MainActor.run {
                self.isRunningTests = false
                self.testSuccess = result?.isSuccess ?? false
                let output = result?.rawOutput ?? ""
                self.testResultsText = output.isEmpty ? "Executed test suites cleanly." : String(output.prefix(300))
            }
        }
    }
}

// MARK: - Issues Navigator View
struct IssuesNavigatorView: View {
    @EnvironmentObject var workspace: WorkspaceDocument
    @ObservedObject var buildManager = WorkspaceBuildManager.shared
    @State private var viewMode = 0 // 0: Issues, 1: xcodebuild Log
    @State private var selectedFilter = 0
    @State private var showBuildLogSheet = false
    @State private var expandedDiagnosticId: String?
    @State private var logSearchText = ""
    @State private var logOnlyErrors = false

    var filteredDiagnostics: [CompilerDiagnostic] {
        switch selectedFilter {
        case 1:
            return buildManager.diagnostics.filter { $0.severity == .error }
        case 2:
            return buildManager.diagnostics.filter { $0.severity == .warning }
        default:
            return buildManager.diagnostics
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            headerBar
            Divider()

            // View Mode Switcher: Issues vs Raw xcodebuild Log
            Picker("", selection: $viewMode) {
                Text("Issues (\(buildManager.errorCount + buildManager.warningCount))").tag(0)
                Text("xcodebuild Log").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)

            Divider()

            if viewMode == 0 {
                issuesContentView
            } else {
                inlineXcodebuildLogView
            }
        }
        .sheet(isPresented: $showBuildLogSheet) {
            buildLogView
        }
        .task {
            if let url = workspace.fileURL {
                await buildManager.loadSchemes(workspaceURL: url)
            }
        }
    }

    // MARK: - Issues Tab Content

    @ViewBuilder
    private var issuesContentView: some View {
        VStack(spacing: 0) {
            statusBar
            Divider()

            if buildManager.errorCount > 0 {
                errorQuickActionBanner
                Divider()
            }

            Picker("", selection: $selectedFilter) {
                Text("All (\(buildManager.diagnostics.count + buildManager.linkerErrors.count))").tag(0)
                Text("Errors (\(buildManager.errorCount))").tag(1)
                Text("Warnings (\(buildManager.warningCount))").tag(2)
            }
            .pickerStyle(.segmented)
            .padding(8)

            Divider()

            if buildManager.isBuilding {
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(0.9)
                    Text(buildManager.currentStatus)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if filteredDiagnostics.isEmpty && buildManager.linkerErrors.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(.green)
                    Text("No Issues Detected")
                        .font(.headline)
                    Text(buildManager.lastResult != nil ? "Build finished cleanly with zero issues." : "Ready to run xcodebuild.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    // Linker errors section
                    if !buildManager.linkerErrors.isEmpty && (selectedFilter == 0 || selectedFilter == 1) {
                        Section("Linker Errors (\(buildManager.linkerErrors.count))") {
                            ForEach(buildManager.linkerErrors) { linkerError in
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.red)
                                        .font(.system(size: 13))
                                        .padding(.top, 2)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Undefined symbol (\(linkerError.architecture))")
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundColor(.red)
                                        Text(linkerError.missingSymbol)
                                            .font(.system(size: 10, design: .monospaced))
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.vertical, 3)
                            }
                        }
                    }

                    // Compiler diagnostics section
                    Section("Diagnostics (\(filteredDiagnostics.count))") {
                        ForEach(filteredDiagnostics) { diag in
                            VStack(alignment: .leading, spacing: 0) {
                                Button {
                                    onSelectDiagnostic(diag)
                                } label: {
                                    HStack(alignment: .top, spacing: 8) {
                                        Image(systemName: diag.severity == .error ? "xmark.circle.fill" :
                                                diag.severity == .warning ? "exclamationmark.triangle.fill" : "info.circle.fill")
                                            .foregroundColor(diag.severity == .error ? .red :
                                                                diag.severity == .warning ? .yellow : .blue)
                                            .font(.system(size: 13))
                                            .padding(.top, 2)

                                        VStack(alignment: .leading, spacing: 2) {
                                            HStack {
                                                Text(fileDisplayName(for: diag.filePath))
                                                    .font(.system(size: 11, weight: .semibold))
                                                    .foregroundColor(.primary)
                                                Text(":\(diag.lineNumber):\(diag.columnOffset)")
                                                    .font(.system(size: 10))
                                                    .foregroundColor(.secondary)
                                                Spacer()
                                                if expandedDiagnosticId == diag.id {
                                                    Image(systemName: "sparkles")
                                                        .font(.system(size: 10))
                                                        .foregroundColor(.accentColor)
                                                }
                                            }

                                            Text(diag.message)
                                                .font(.system(size: 11))
                                                .foregroundColor(.primary)
                                                .lineLimit(expandedDiagnosticId == diag.id ? nil : 3)
                                                .multilineTextAlignment(.leading)
                                        }
                                    }
                                    .padding(.vertical, 4)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)

                                // AI Fix Inspector (shows when diagnostic is tapped)
                                if expandedDiagnosticId == diag.id {
                                    aiFixInspectorView(for: diag)
                                        .padding(.leading, 20)
                                        .padding(.vertical, 6)
                                }
                            }
                        }
                    }
                }
                .listStyle(.sidebar)
            }
        }
    }

    // MARK: - AI Fix Inspector View

    private func aiFixInspectorView(for diag: CompilerDiagnostic) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // xcodebuild Raw Error Log snippet
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Image(systemName: "terminal.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    Text("xcodebuild Error Log:")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.secondary)
                }

                Text(diag.rawLogSnippet ?? "\(diag.filePath):\(diag.lineNumber):\(diag.columnOffset): \(diag.severity.rawValue): \(diag.message)")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(diag.severity == .error ? .red : .primary)
                    .padding(6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(4)
                    .textSelection(.enabled)
            }

            // AI Diagnosis & Suggestions
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundColor(.accentColor)
                        .font(.system(size: 11))
                    Text("Ways to Fix with AI:")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.accentColor)
                    Spacer()
                    if buildManager.isAnalyzingAIFix {
                        ProgressView().controlSize(.small)
                    }
                }

                if let fix = buildManager.currentAIFix, fix.diagnosticId == diag.id {
                    Text(fix.explanation)
                        .font(.system(size: 10))
                        .foregroundColor(.primary)

                    ForEach(Array(fix.suggestedFixOptions.enumerated()), id: \.offset) { idx, option in
                        HStack(alignment: .top, spacing: 4) {
                            Text("\(idx + 1).")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.secondary)
                            Text(option)
                                .font(.system(size: 10))
                                .foregroundColor(.primary)
                        }
                    }

                    if let replacement = fix.codeReplacementSnippet {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Suggested Code Patch:")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(.secondary)
                            Text(replacement)
                                .font(.system(size: 10, design: .monospaced))
                                .padding(6)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.green.opacity(0.12))
                                .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.green.opacity(0.3), lineWidth: 0.8))
                                .cornerRadius(4)
                        }

                        HStack(spacing: 8) {
                            Button {
                                Task {
                                    try? await buildManager.applyAIFix(fix, workspaceURL: workspace.fileURL)
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Apply AI Fix")
                                }
                                .font(.system(size: 10, weight: .medium))
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)

                            Button {
                                NotificationCenter.default.post(
                                    name: NSNotification.Name("OpenAIAssistantWithPrompt"),
                                    object: "Help me fix this compiler error in \(diag.filePath):\(diag.lineNumber): \(diag.message)"
                                )
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "bubble.left.and.bubble.right")
                                    Text("Ask AI Assistant")
                                }
                                .font(.system(size: 10))
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                        .padding(.top, 2)
                    }

                    if let successMsg = buildManager.aiFixSuccessMessage {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text(successMsg)
                                .font(.system(size: 9))
                                .foregroundColor(.green)
                        }
                    }
                } else if !buildManager.isAnalyzingAIFix {
                    Button {
                        Task {
                            await buildManager.requestAIFix(for: diag, workspaceURL: workspace.fileURL)
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "sparkles")
                            Text("Analyze & Generate Fix Options")
                        }
                        .font(.system(size: 10))
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
            .padding(8)
            .background(Color.accentColor.opacity(0.08))
            .cornerRadius(6)
        }
        .padding(8)
        .background(Color(NSColor.windowBackgroundColor).opacity(0.6))
        .cornerRadius(6)
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.secondary.opacity(0.2), lineWidth: 0.8))
    }

    // MARK: - Inline xcodebuild Log View

    private var inlineXcodebuildLogView: some View {
        VStack(spacing: 0) {
            // Log controls toolbar
            HStack(spacing: 8) {
                HStack(spacing: 4) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                        .font(.system(size: 10))
                    TextField("Filter build log...", text: $logSearchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 11))
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(4)

                Toggle("Errors", isOn: $logOnlyErrors)
                    .font(.system(size: 10))
                    .toggleStyle(.button)
                    .controlSize(.small)

                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(buildManager.lastResult?.rawOutput ?? "", forType: .string)
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 10))
                }
                .buttonStyle(.borderless)
                .help("Copy Raw Log to Clipboard")
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)

            Divider()

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 2) {
                    if filteredLogLines.isEmpty {
                        Text(buildManager.lastResult == nil ? "No xcodebuild log captured yet. Run a build above." : "No matching log lines.")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .padding(12)
                    } else {
                        ForEach(Array(filteredLogLines.enumerated()), id: \.offset) { _, line in
                            Text(line)
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(
                                    line.contains("error:") || line.contains("BUILD FAILED") ? .red :
                                    line.contains("warning:") ? .yellow :
                                    line.hasPrefix("CompileSwift") || line.hasPrefix("Ld") ? .blue : .primary
                                )
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .textSelection(.enabled)
                        }
                    }
                }
                .padding(8)
            }
            .background(Color(NSColor.textBackgroundColor))
        }
    }

    private var filteredLogLines: [String] {
        guard let output = buildManager.lastResult?.rawOutput else { return [] }
        var lines = output.components(separatedBy: .newlines)
        if logOnlyErrors {
            lines = lines.filter { $0.contains("error:") || $0.contains("fatal error:") || $0.contains("BUILD FAILED") }
        }
        if !logSearchText.isEmpty {
            lines = lines.filter { $0.localizedCaseInsensitiveContains(logSearchText) }
        }
        return lines
    }

    private var errorQuickActionBanner: some View {
        HStack(spacing: 6) {
            Image(systemName: "xmark.circle.fill")
                .foregroundColor(.red)
                .font(.system(size: 12))
            Text("\(buildManager.errorCount) error(s) in xcodebuild")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.red)
            Spacer()
            Button("View Error Log") {
                viewMode = 1
                logOnlyErrors = true
            }
            .font(.system(size: 10, weight: .medium))
            .buttonStyle(.bordered)
            .controlSize(.mini)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color.red.opacity(0.12))
    }

    private func onSelectDiagnostic(_ diag: CompilerDiagnostic) {
        openDiagnosticFile(diag)
        if expandedDiagnosticId == diag.id {
            expandedDiagnosticId = nil
        } else {
            expandedDiagnosticId = diag.id
            Task {
                await buildManager.requestAIFix(for: diag, workspaceURL: workspace.fileURL)
            }
        }
    }

    private var headerBar: some View {
        HStack {
            Text("Issue Navigator")
                .font(.system(size: 12, weight: .semibold))
            Spacer()

            if !buildManager.availableSchemes.isEmpty {
                Menu {
                    ForEach(buildManager.availableSchemes, id: \.self) { scheme in
                        Button(scheme) {
                            buildManager.selectedScheme = scheme
                        }
                    }
                } label: {
                    Text(buildManager.selectedScheme.isEmpty ? "Scheme" : buildManager.selectedScheme)
                        .font(.system(size: 10, weight: .medium))
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
            }

            Button {
                triggerBuild()
            } label: {
                Label(
                    buildManager.isBuilding ? "Building..." : "Build",
                    systemImage: buildManager.isBuilding ? "hourglass" : "hammer.fill"
                )
                .font(.system(size: 11))
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .disabled(buildManager.isBuilding)

            Menu {
                Button("Clean Build Folder") {
                    cleanBuild()
                }
                Button("View Raw Build Log in Sheet") {
                    showBuildLogSheet = true
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 12))
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .frame(width: 20)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
    }

    private var statusBar: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(
                    buildManager.isBuilding ? Color.blue :
                    buildManager.errorCount > 0 ? Color.red :
                    buildManager.warningCount > 0 ? Color.yellow :
                    buildManager.lastResult != nil ? Color.green : Color.secondary
                )
                .frame(width: 7, height: 7)

            Text(buildManager.currentStatus)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
                .lineLimit(1)

            Spacer()

            if buildManager.buildDuration > 0 {
                Text(String(format: "%.1fs", buildManager.buildDuration))
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.4))
    }

    private var buildLogView: some View {
        VStack(spacing: 0) {
            HStack {
                Text("xcodebuild Output Log")
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                Button("Close") {
                    showBuildLogSheet = false
                }
                .keyboardShortcut(.cancelAction)
            }
            .padding(14)
            Divider()

            ScrollView {
                Text(buildManager.lastResult?.rawOutput ?? "No build log captured yet.")
                    .font(.system(size: 11, design: .monospaced))
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
        }
        .frame(width: 600, height: 400)
    }

    private func triggerBuild() {
        guard let url = workspace.fileURL else { return }
        Task {
            await buildManager.build(workspaceURL: url)
        }
    }

    private func cleanBuild() {
        guard let url = workspace.fileURL else { return }
        Task {
            await buildManager.clean(workspaceURL: url)
        }
    }

    private func fileDisplayName(for path: String) -> String {
        (path as NSString).lastPathComponent
    }

    private func openDiagnosticFile(_ diag: CompilerDiagnostic) {
        guard diag.filePath != "xcodebuild" else { return }
        let fileURL: URL
        if diag.filePath.hasPrefix("/") {
            fileURL = URL(fileURLWithPath: diag.filePath)
        } else if let base = workspace.fileURL {
            fileURL = base.appendingPathComponent(diag.filePath)
        } else {
            return
        }

        CodeEditDocumentController.shared.openDocument(withContentsOf: fileURL, display: true) { doc, _, _ in
            if let codeDoc = doc as? CodeFileDocument {
                codeDoc.cursorPosition = (diag.lineNumber, max(1, diag.columnOffset))
            }
        }
    }
}

// MARK: - Symbols Navigator View
struct SymbolsNavigatorView: View {
    @EnvironmentObject var workspace: WorkspaceDocument
    @State private var searchText = ""
    @State private var symbols: [ParsedSymbolItem] = []

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .font(.system(size: 11))
                TextField("Filter Symbols", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
            }
            .padding(6)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(6)
            .padding(8)

            Divider()

            if symbols.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "character.cursor.ibeam")
                        .font(.system(size: 28))
                        .foregroundStyle(.secondary)
                    Text("No Symbols Loaded")
                        .font(.headline)
                    Text("Open a Swift source file to parse symbols.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(symbols) { symbol in
                        HStack(spacing: 8) {
                            Image(systemName: symbol.icon)
                                .foregroundColor(
                                    symbol.kind == "Class" ? .purple :
                                    symbol.kind == "Method" ? .blue : .orange
                                )
                                .font(.system(size: 13))

                            VStack(alignment: .leading, spacing: 1) {
                                Text(symbol.name)
                                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                                Text(symbol.kind)
                                    .font(.system(size: 9))
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 2)
                    }
                }
                .listStyle(.sidebar)
            }
        }
        .task {
            loadSymbols()
        }
    }

    private func loadSymbols() {
        guard let item = workspace.selectionState.openFileItems.first(where: {
            $0.tabID == workspace.selectionState.selectedId
        }), let codeFile = workspace.selectionState.openedCodeFiles[item] else { return }

        let text = codeFile.content
        var detected: [ParsedSymbolItem] = []
        let lines = text.components(separatedBy: .newlines)
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("struct ") {
                let name = trimmed.split(separator: " ")[1].split(separator: ":")[0]
                detected.append(ParsedSymbolItem(name: String(name), kind: "Struct", icon: "s.square.fill"))
            } else if trimmed.hasPrefix("class ") {
                let name = trimmed.split(separator: " ")[1].split(separator: ":")[0]
                detected.append(ParsedSymbolItem(name: String(name), kind: "Class", icon: "c.square.fill"))
            } else if trimmed.hasPrefix("protocol ") {
                let name = trimmed.split(separator: " ")[1].split(separator: ":")[0]
                detected.append(ParsedSymbolItem(name: String(name), kind: "Protocol", icon: "p.square.fill"))
            } else if trimmed.hasPrefix("func ") {
                let name = trimmed.split(separator: " ")[1].split(separator: "(")[0]
                detected.append(ParsedSymbolItem(name: String(name) + "()", kind: "Method", icon: "m.square.fill"))
            }
        }
        self.symbols = detected
    }
}
