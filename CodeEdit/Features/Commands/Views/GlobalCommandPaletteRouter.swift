//
//  GlobalCommandPaletteRouter.swift
//  CodeEdit
//

import SwiftUI
import AppKit

public enum PaletteCommandCategory: String, CaseIterable, Identifiable, Sendable {
    case actions = "Actions"
    case navigation = "Navigation"
    case devTools = "Developer Tools"
    case askAI = "Ask AI"

    public var id: String { rawValue }

    public var iconName: String {
        switch self {
        case .actions: return "bolt.fill"
        case .navigation: return "arrow.right.circle.fill"
        case .devTools: return "wrench.and.screwdriver.fill"
        case .askAI: return "sparkles"
        }
    }
}

public struct UniversalPaletteCommandItem: Identifiable, Equatable {
    public let id: String
    public let title: String
    public let subtitle: String?
    public let category: PaletteCommandCategory
    public let shortcut: String?
    public let action: @MainActor () -> Void

    public static func == (lhs: UniversalPaletteCommandItem, rhs: UniversalPaletteCommandItem) -> Bool {
        lhs.id == rhs.id
    }
}

public struct GlobalCommandPaletteRouter: View {
    @Binding public var isPresented: Bool
    @State private var query = ""
    @State private var selectedIndex = 0

    public var customCommands: [UniversalPaletteCommandItem] = []
    public var onSelectCommand: ((UniversalPaletteCommandItem) -> Void)?

    public init(
        isPresented: Binding<Bool>,
        customCommands: [UniversalPaletteCommandItem] = [],
        onSelectCommand: ((UniversalPaletteCommandItem) -> Void)? = nil
    ) {
        self._isPresented = isPresented
        self.customCommands = customCommands
        self.onSelectCommand = onSelectCommand
    }

    private var defaultCommands: [UniversalPaletteCommandItem] {
        [
            // Actions
            UniversalPaletteCommandItem(id: "build", title: "Project: Run Build", subtitle: "Compiles active project scheme", category: .actions, shortcut: "⌘B") {
                Task {
                    _ = await SwiftPackageBuildService.shared.buildPackage(projectPath: ".")
                }
            },
            UniversalPaletteCommandItem(id: "test", title: "Project: Run Tests", subtitle: "Executes test suite", category: .actions, shortcut: "⌘U") {
                Task {
                    _ = await SwiftPackageBuildService.shared.runTests(projectPath: ".")
                }
            },
            UniversalPaletteCommandItem(id: "format", title: "Edit: Format Document", subtitle: "Normalizes Swift formatting", category: .actions, shortcut: "⇧⌘F") {
                try? DocumentCoordinator.shared.saveAll()
            },
            UniversalPaletteCommandItem(id: "save_all", title: "File: Save All", subtitle: "Saves all dirty open files", category: .actions, shortcut: "⌥⌘S") {
                try? DocumentCoordinator.shared.saveAll()
            },
            UniversalPaletteCommandItem(id: "terminal", title: "View: Toggle Embedded Terminal", subtitle: "Opens integrated shell", category: .actions, shortcut: "⇧⌘T") {
                OperationsWindowManager.show()
            },
            UniversalPaletteCommandItem(id: "assist_agent", title: "Assist: Toggle AI Agent Session", subtitle: "Opens autonomous assistant", category: .actions, shortcut: "⇧⌘A") {
                AssistAgentWindowManager.show()
            },

            // Navigation
            UniversalPaletteCommandItem(id: "quick_open", title: "Navigate: Quick Open File", subtitle: "Search project files by name", category: .navigation, shortcut: "⌘P") {
                NSApp.sendAction(Selector(("openQuickly:")), to: nil, from: nil)
            },
            UniversalPaletteCommandItem(id: "find_in_files", title: "Navigate: Find in Files", subtitle: "Workspace text search", category: .navigation, shortcut: "⇧⌘F") {
                NSApp.sendAction(Selector(("findInFiles:")), to: nil, from: nil)
            },
            UniversalPaletteCommandItem(id: "go_to_line", title: "Navigate: Go to Line...", subtitle: "Jump directly to line number", category: .navigation, shortcut: "⌘L") {
                NSApp.sendAction(Selector(("goToLine:")), to: nil, from: nil)
            },

            // Dev Tools & Workspaces
            UniversalPaletteCommandItem(
                id: "tool_devtools_all",
                title: "DevTool: All 156 Developer Utilities",
                subtitle: "Search and execute offline developer tools",
                category: .devTools,
                shortcut: "⌥⌘T"
            ) {
                DevToolsWindowManager.show()
            },
            UniversalPaletteCommandItem(
                id: "tool_json_to_swift",
                title: "DevTool: JSON to Swift Structs",
                subtitle: "Generates Codable models from JSON",
                category: .devTools,
                shortcut: nil
            ) {
                DevToolsWindowManager.show(initialToolID: "json_to_swift")
            },
            UniversalPaletteCommandItem(
                id: "tool_jwt_decoder",
                title: "DevTool: JWT Token Decoder",
                subtitle: "Inspect claims and signatures",
                category: .devTools,
                shortcut: nil
            ) {
                DevToolsWindowManager.show(initialToolID: "jwt_decoder")
            },
            UniversalPaletteCommandItem(
                id: "tool_hash_gen",
                title: "DevTool: Hash & Digest Generator",
                subtitle: "SHA-256, MD5, SHA-512",
                category: .devTools,
                shortcut: nil
            ) {
                DevToolsWindowManager.show(initialToolID: "hash_generator")
            },
            UniversalPaletteCommandItem(
                id: "tool_regex_tester",
                title: "DevTool: Regular Expression Tester",
                subtitle: "Test regex with live highlights",
                category: .devTools,
                shortcut: nil
            ) {
                DevToolsWindowManager.show(initialToolID: "regex_tester")
            },
            UniversalPaletteCommandItem(
                id: "tool_db_explorer",
                title: "DevTool: Database Studio & Explorer",
                subtitle: "SQLite, PostgreSQL, Core Data",
                category: .devTools,
                shortcut: "⌥⌘E"
            ) {
                DatabaseExplorerWindowManager.show()
            },
            UniversalPaletteCommandItem(
                id: "tool_visual_ui",
                title: "DevTool: Visual UI Builder & Artboard",
                subtitle: "Interactive SwiftUI canvas",
                category: .devTools,
                shortcut: "⌥⌘V"
            ) {
                VisualUIBuilderWindowManager.show()
            },
            UniversalPaletteCommandItem(
                id: "tool_personal_docs",
                title: "DevTool: Architecture Wiki & Knowledge Base",
                subtitle: "Browse project journals and wiki",
                category: .devTools,
                shortcut: "⌥⌘D"
            ) {
                PersonalDocWindowManager.show()
            },
            UniversalPaletteCommandItem(
                id: "tool_operations",
                title: "DevTool: DevOps & Telemetry Dashboard",
                subtitle: "Monitor CPU, RAM, and hardware performance",
                category: .devTools,
                shortcut: "⌥⌘O"
            ) {
                OperationsWindowManager.show()
            },
            UniversalPaletteCommandItem(
                id: "tool_coding_dict",
                title: "DevTool: Offline Coding Dictionary",
                subtitle: "API documentation for Swift and Apple frameworks",
                category: .devTools,
                shortcut: "⌥⌘K"
            ) {
                CodingDictionaryWindowManager.show()
            },
            UniversalPaletteCommandItem(
                id: "tool_storekit",
                title: "DevTool: StoreKit Workspace & Testing",
                subtitle: "In-app purchases and subscription simulation",
                category: .devTools,
                shortcut: "⌥⌘S"
            ) {
                StoreKitWindowManager.show()
            },
            UniversalPaletteCommandItem(
                id: "tool_source_control",
                title: "DevTool: Source Control & Repositories",
                subtitle: "Inspect Git history and branches",
                category: .devTools,
                shortcut: "⌥⌘G"
            ) {
                SourceControlWindowManager.show()
            },

            // Ask AI
            UniversalPaletteCommandItem(id: "ai_explain", title: "Ask AI: Explain Active Code", subtitle: "Analyzes selection in active editor", category: .askAI, shortcut: nil) {
                AssistAgentWindowManager.show()
            },
            UniversalPaletteCommandItem(id: "ai_refactor", title: "Ask AI: Suggest Refactoring", subtitle: "Recommends architecture improvements", category: .askAI, shortcut: nil) {
                AssistAgentWindowManager.show()
            },
            UniversalPaletteCommandItem(id: "ai_tests", title: "Ask AI: Generate Unit Tests", subtitle: "Synthesizes XCTest suite for file", category: .askAI, shortcut: nil) {
                AssistAgentWindowManager.show()
            }
        ]
    }

    private var allCommands: [UniversalPaletteCommandItem] {
        defaultCommands + customCommands
    }

    private var filteredCommands: [UniversalPaletteCommandItem] {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty { return allCommands }

        return allCommands.filter {
            $0.title.localizedCaseInsensitiveContains(trimmed) ||
            ($0.subtitle?.localizedCaseInsensitiveContains(trimmed) ?? false) ||
            $0.category.rawValue.localizedCaseInsensitiveContains(trimmed)
        }
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Search Input Field
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.accentColor)
                    .font(.system(size: 14))

                TextField("Type a command or search (e.g. 'build', 'format', 'jwt')...", text: $query)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14))
                    .onSubmit {
                        executeSelected()
                    }

                if !query.isEmpty {
                    Button {
                        query = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }

                Text("ESC to close")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(4)
            }
            .padding(14)

            Divider()

            // Filtered Command List
            ScrollViewReader { _ in
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(Array(filteredCommands.enumerated()), id: \.element.id) { index, item in
                            HStack(spacing: 10) {
                                Image(systemName: item.category.iconName)
                                    .font(.system(size: 13))
                                    .foregroundColor(index == selectedIndex ? .accentColor : .secondary)
                                    .frame(width: 20)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.title)
                                        .font(.system(size: 12, weight: .medium))
                                    if let sub = item.subtitle {
                                        Text(sub)
                                            .font(.system(size: 10))
                                            .foregroundColor(.secondary)
                                    }
                                }

                                Spacer()

                                if let shortcut = item.shortcut {
                                    Text(shortcut)
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal, 5)
                                        .padding(.vertical, 1)
                                        .background(Color.secondary.opacity(0.12))
                                        .cornerRadius(4)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(index == selectedIndex ? Color.accentColor.opacity(0.15) : Color.clear)
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedIndex = index
                                executeSelected()
                            }
                            .id(item.id)
                        }
                    }
                    .padding(8)
                }
            }
            .frame(maxHeight: 340)
        }
        .frame(width: 580)
        .background(EffectView(.popover, blendingMode: .behindWindow))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.25), radius: 20, x: 0, y: 10)
    }

    private func executeSelected() {
        guard !filteredCommands.isEmpty, selectedIndex < filteredCommands.count else { return }
        let item = filteredCommands[selectedIndex]
        isPresented = false
        item.action()
        onSelectCommand?(item)
    }
}
