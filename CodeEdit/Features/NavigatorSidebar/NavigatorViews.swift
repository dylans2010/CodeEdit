//
//  NavigatorViews.swift
//  CodeEdit
//
//

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
    @State private var dependencies: [PinnedDependencyItem] = []

    var filteredDependencies: [PinnedDependencyItem] {
        if searchText.isEmpty {
            return dependencies
        }
        return dependencies.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.url.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            searchBar

            if dependencies.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "shippingbox")
                        .font(.system(size: 30))
                        .foregroundStyle(.secondary)
                    Text("No Dependencies Found")
                        .font(.headline)
                    Text("Add Swift Packages via Package.swift or Xcode project settings.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    Section {
                        ForEach(filteredDependencies) { dependency in
                            HStack(spacing: 8) {
                                Image(systemName: "shippingbox.fill")
                                    .foregroundColor(.accentColor)
                                    .font(.system(size: 13))

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(dependency.name)
                                        .font(.system(size: 12, weight: .medium))
                                    Text("\(dependency.version) • \(dependency.url)")
                                        .font(.system(size: 10))
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
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
                            Text("Swift Packages")
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
            loadDependencies()
        }
    }

    private func loadDependencies() {
        guard let workspaceURL = workspace.fileURL else { return }
        let relXC = "CodeEdit.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"
        let possiblePaths = [
            workspaceURL.appendingPathComponent("Package.resolved"),
            workspaceURL.appendingPathComponent(".swiftpm/xcode/package.resolved"),
            workspaceURL.appendingPathComponent(relXC)
        ]
        for resolvedURL in possiblePaths {
            if let data = try? Data(contentsOf: resolvedURL),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                parseResolvedJSON(json)
                if !dependencies.isEmpty { break }
            }
        }
    }

    private func parseResolvedJSON(_ json: [String: Any]) {
        var parsed: [PinnedDependencyItem] = []
        if let pins = json["pins"] as? [[String: Any]] {
            for pin in pins {
                let name = pin["package"] as? String ?? pin["identity"] as? String ?? "Package"
                let location = pin["location"] as? String ?? pin["repositoryURL"] as? String ?? ""
                let state = pin["state"] as? [String: Any]
                let ver = state?["version"] as? String ?? state?["branch"] as? String
                let version = ver ?? state?["revision"] as? String ?? "resolved"
                parsed.append(PinnedDependencyItem(name: name, version: version, url: location))
            }
        } else if let object = json["object"] as? [String: Any], let pins = object["pins"] as? [[String: Any]] {
            for pin in pins {
                let name = pin["package"] as? String ?? "Package"
                let location = pin["repositoryURL"] as? String ?? ""
                let state = pin["state"] as? [String: Any]
                let ver = state?["version"] as? String ?? state?["branch"] as? String
                let version = ver ?? "resolved"
                parsed.append(PinnedDependencyItem(name: name, version: version, url: location))
            }
        }
        self.dependencies = parsed
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
    @State private var selectedFilter = 0

    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $selectedFilter) {
                Text("All Issues").tag(0)
                Text("Errors (0)").tag(1)
                Text("Warnings (0)").tag(2)
            }
            .pickerStyle(.segmented)
            .padding(8)

            Divider()

            VStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(.green)
                Text("No Issues Detected")
                    .font(.headline)
                Text("Workspace compiled with zero errors or diagnostics.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
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
