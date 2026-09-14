import SwiftUI

// MARK: - Dependencies Navigator View
struct DependenciesNavigatorView: View {
    @EnvironmentObject var workspace: WorkspaceDocument
    @State private var searchText = ""

    private let sampleDependencies: [(name: String, version: String, url: String)] = [
        ("CodeEditKit", "main (branch)", "github.com/CodeEditApp/CodeEditKit"),
        ("CodeEditLanguages", "0.1.18", "github.com/CodeEditApp/CodeEditLanguages"),
        ("CodeEditSourceEditor", "main (branch)", "github.com/CodeEditApp/CodeEditSourceEditor"),
        ("CodeEditSymbols", "0.1.4", "github.com/CodeEditApp/CodeEditSymbols"),
        ("Sparkle", "2.6.4", "github.com/sparkle-project/Sparkle")
    ]

    var filteredDependencies: [(name: String, version: String, url: String)] {
        if searchText.isEmpty {
            return sampleDependencies
        }
        return sampleDependencies.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.url.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            searchBar

            List {
                Section {
                    ForEach(filteredDependencies, id: \.name) { dep in
                        HStack(spacing: 8) {
                            Image(systemName: "shippingbox.fill")
                                .foregroundColor(.accentColor)
                                .font(.system(size: 13))

                            VStack(alignment: .leading, spacing: 2) {
                                Text(dep.name)
                                    .font(.system(size: 12, weight: .medium))
                                Text("\(dep.version) • \(dep.url)")
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
    @State private var searchText = ""
    @State private var isRunningTests = false

    private let testSuites = [
        ("CodeEditUnitTests", [
            ("testWorkspaceDocumentInitialization", true),
            ("testFileItemCreation", true),
            ("testTabStateTransitions", true),
            ("testThemeLoading", true)
        ]),
        ("CodeEditSourceEditorTests", [
            ("testSyntaxHighlightingEngine", true),
            ("testLineNumberCalculation", true),
            ("testIndentationGuides", true)
        ]),
        ("CodeEditGitTests", [
            ("testGitBranchParsing", true),
            ("testGitCommitHistory", true)
        ])
    ]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Test Navigator")
                    .font(.system(size: 12, weight: .semibold))
                Spacer()
                Button {
                    withAnimation {
                        isRunningTests.toggle()
                    }
                } label: {
                    Label(isRunningTests ? "Stop" : "Run All", systemImage: isRunningTests ? "stop.fill" : "play.fill")
                        .font(.system(size: 11))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)

            Divider()

            List {
                ForEach(testSuites, id: \.0) { suite in
                    Section(header: Text(suite.0).font(.system(size: 11, weight: .bold))) {
                        ForEach(suite.1, id: \.0) { test in
                            HStack(spacing: 6) {
                                Image(systemName: isRunningTests ? "hourglass" : "checkmark.circle.fill")
                                    .foregroundColor(isRunningTests ? .orange : .green)
                                    .font(.system(size: 11))
                                Text(test.0)
                                    .font(.system(size: 11))
                                    .lineLimit(1)
                                Spacer()
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
            }
            .listStyle(.sidebar)
        }
    }
}

// MARK: - Issues Navigator View
struct IssuesNavigatorView: View {
    @EnvironmentObject var workspace: WorkspaceDocument
    @State private var selectedFilter = 0

    private let issues: [(severity: String, message: String, location: String)] = [
        ("warning", "DOCS TODO: Missing parameter documentation", "FileItem.swift:311"),
        ("warning", "DOCS TODO: Add documentation comments", "CodeEditKeychain.swift:4"),
        ("info", "Build target: CodeEdit (Debug)", "CodeEdit.xcodeproj"),
        ("info", "Hardened runtime configured", "Entitlements.plist")
    ]

    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $selectedFilter) {
                Text("All Issues").tag(0)
                Text("Errors (0)").tag(1)
                Text("Warnings (2)").tag(2)
            }
            .pickerStyle(.segmented)
            .padding(8)

            Divider()

            List {
                ForEach(issues, id: \.message) { issue in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: issue.severity == "warning" ? "exclamationmark.triangle.fill" : "info.circle.fill")
                            .foregroundColor(issue.severity == "warning" ? .orange : .blue)
                            .font(.system(size: 12))
                            .padding(.top, 2)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(issue.message)
                                .font(.system(size: 11, weight: .medium))
                                .fixedSize(horizontal: false, vertical: true)
                            Text(issue.location)
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .listStyle(.sidebar)
        }
    }
}

// MARK: - Symbols Navigator View
struct SymbolsNavigatorView: View {
    @EnvironmentObject var workspace: WorkspaceDocument
    @State private var searchText = ""

    private let symbols: [(name: String, kind: String, icon: String)] = [
        ("WorkspaceDocument", "Class", "c.square.fill"),
        ("FileItem", "Class", "c.square.fill"),
        ("addFile(fileName:)", "Method", "m.square.fill"),
        ("addFolder(folderName:)", "Method", "m.square.fill"),
        ("importFiles(from:)", "Method", "m.square.fill"),
        ("TabBarItemRepresentable", "Protocol", "p.square.fill"),
        ("WorkspaceSelectionState", "Struct", "s.square.fill")
    ]

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

            List {
                ForEach(symbols, id: \.name) { symbol in
                    HStack(spacing: 8) {
                        Image(systemName: symbol.icon)
                            .foregroundColor(symbol.kind == "Class" ? .purple : symbol.kind == "Method" ? .blue : .orange)
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
}

// MARK: - Utilities Navigator View
struct UtilitiesNavigatorView: View {
    @EnvironmentObject var workspace: WorkspaceDocument

    private let tools = [
        ("Quick Open", "command.square", "Open any file with Cmd+P"),
        ("Command Palette", "terminal.fill", "Access commands with Shift+Cmd+P"),
        ("Feedback for CodeEdit", "bubble.left.and.exclamationmark.bubble.right", "Submit feedback to dylans2010/CodeEdit"),
        ("Workspace Settings", "gearshape.fill", "Configure editor and project preferences"),
        ("Documentation", "book.closed.fill", "Browse CodeEdit guides and API docs")
    ]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Utilities & Quick Actions")
                    .font(.system(size: 12, weight: .semibold))
                Spacer()
            }
            .padding(10)

            Divider()

            List {
                ForEach(tools, id: \.0) { tool in
                    HStack(spacing: 10) {
                        Image(systemName: tool.1)
                            .font(.system(size: 14))
                            .foregroundColor(.accentColor)
                            .frame(width: 22)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(tool.0)
                                .font(.system(size: 11, weight: .medium))
                            Text(tool.2)
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            }
            .listStyle(.sidebar)
        }
    }
}
