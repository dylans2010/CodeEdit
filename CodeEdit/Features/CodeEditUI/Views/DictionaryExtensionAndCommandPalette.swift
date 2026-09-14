//
//  DictionaryExtensionAndCommandPalette.swift
//  UniversalIDE
//

import SwiftUI
import Foundation

// MARK: - Offline Coding Dictionary & API Reference System

public struct DictionaryParameter: Codable, Sendable {
    public let name: String
    public let type: String
    public let description: String

    public init(name: String, type: String, description: String) {
        self.name = name
        self.type = type
        self.description = description
    }
}

public struct DictionaryReturnValue: Codable, Sendable {
    public let type: String
    public let description: String

    public init(type: String, description: String) {
        self.type = type
        self.description = description
    }
}

public struct DictionaryExample: Codable, Sendable {
    public let title: String
    public let code: String

    public init(title: String, code: String) {
        self.title = title
        self.code = code
    }
}

public struct DictionaryMistake: Codable, Sendable {
    public let description: String
    public let explanation: String
    public let fix: String

    public init(description: String, explanation: String, fix: String) {
        self.description = description
        self.explanation = explanation
        self.fix = fix
    }
}

public struct DictionaryEntry: Codable, Identifiable, Sendable {
    public let id: String
    public let name: String
    public let framework: String
    public let declaration: String
    public let summary: String
    public let parameters: [DictionaryParameter]
    public let returnValue: DictionaryReturnValue?
    public let examples: [DictionaryExample]
    public let commonMistakes: [DictionaryMistake]

    public init(
        id: String,
        name: String,
        framework: String,
        declaration: String,
        summary: String,
        parameters: [DictionaryParameter] = [],
        returnValue: DictionaryReturnValue? = nil,
        examples: [DictionaryExample] = [],
        commonMistakes: [DictionaryMistake] = []
    ) {
        self.id = id
        self.name = name
        self.framework = framework
        self.declaration = declaration
        self.summary = summary
        self.parameters = parameters
        self.returnValue = returnValue
        self.examples = examples
        self.commonMistakes = commonMistakes
    }
}

public final class DictionaryManager: @unchecked Sendable {
    public static let shared = DictionaryManager()

    private init() {}

    public func searchAPIs(query: String) async -> [DictionaryEntry] {
        return [
            DictionaryEntry(
                id: "swiftui.view.task",
                name: "task(priority:_:)",
                framework: "SwiftUI",
                declaration: "func task(priority: TaskPriority = .userInitiated, _ action: @escaping () async -> Void) -> some View",
                summary: "Adds an asynchronous task to perform before this view appears.",
                parameters: [
                    DictionaryParameter(name: "priority", type: "TaskPriority", description: "The task priority."),
                    DictionaryParameter(name: "action", type: "() async -> Void", description: "The async closure to execute.")
                ],
                returnValue: DictionaryReturnValue(type: "some View", description: "View modified with async task."),
                examples: [
                    DictionaryExample(title: "Fetch Data On Appear", code: ".task {\n    await viewModel.loadData()\n}")
                ],
                commonMistakes: [
                    DictionaryMistake(description: "Blocking main thread", explanation: "Never perform synchronous heavy work inside task.", fix: "Use async/await.")
                ]
            )
        ]
    }
}

// MARK: - Extension & Plugin Ecosystem

public struct ExtensionConfigField: Codable, Sendable {
    public let key: String
    public let type: String
    public let defaultValue: String
    public let description: String

    public init(key: String, type: String, defaultValue: String, description: String) {
        self.key = key
        self.type = type
        self.defaultValue = defaultValue
        self.description = description
    }
}

public struct ExtensionManifest: Codable, Identifiable, Sendable {
    public let id: String
    public let name: String
    public let version: String
    public let description: String
    public let author: String
    public let category: String
    public let capabilities: [String]
    public let entryPoint: String
    public let swiftCodeAssistCapable: Bool
    public let configFields: [ExtensionConfigField]

    public init(
        id: String,
        name: String,
        version: String,
        description: String,
        author: String,
        category: String,
        capabilities: [String],
        entryPoint: String,
        swiftCodeAssistCapable: Bool,
        configFields: [ExtensionConfigField] = []
    ) {
        self.id = id
        self.name = name
        self.version = version
        self.description = description
        self.author = author
        self.category = category
        self.capabilities = capabilities
        self.entryPoint = entryPoint
        self.swiftCodeAssistCapable = swiftCodeAssistCapable
        self.configFields = configFields
    }
}

public final class ExtensionManager: @unchecked Sendable {
    public static let shared = ExtensionManager()

    private init() {}

    public func parseManifest(jsonString: String) throws -> ExtensionManifest {
        let data = jsonString.data(using: .utf8) ?? Data()
        return try JSONDecoder().decode(ExtensionManifest.self, from: data)
    }

    public func executeExtensionScript(manifest: ExtensionManifest, input: String) async throws -> String {
        return "Extension '\(manifest.name)' executed successfully."
    }
}

// MARK: - Global Command Palette Router

public struct CommandPaletteItem: Identifiable, Sendable {
    public let id: UUID
    public let title: String
    public let category: String // Action, Navigation, DevTool, Ask AI
    public let shortcut: String?

    public init(id: UUID = UUID(), title: String, category: String, shortcut: String? = nil) {
        self.id = id
        self.title = title
        self.category = category
        self.shortcut = shortcut
    }
}

@MainActor
public final class CommandPaletteRouter: ObservableObject {
    public static let shared = CommandPaletteRouter()

    @Published public var isVisible: Bool = false
    @Published public var searchQuery: String = ""
    @Published public var items: [CommandPaletteItem] = [
        CommandPaletteItem(title: "Save File", category: "Action", shortcut: "Cmd + S"),
        CommandPaletteItem(title: "Run Build", category: "Action", shortcut: "Cmd + B"),
        CommandPaletteItem(title: "Toggle AI Agent", category: "Action", shortcut: "Cmd + Shift + A"),
        CommandPaletteItem(title: "Embedded Terminal", category: "Navigation", shortcut: "Cmd + Shift + T"),
        CommandPaletteItem(title: "Database Explorer", category: "Navigation", shortcut: "Cmd + Opt + E"),
        CommandPaletteItem(title: "JSON to Swift Codable", category: "DevTool", shortcut: nil)
    ]

    private init() {}

    public func togglePalette() {
        isVisible.toggle()
    }

    public func executeCommand(_ item: CommandPaletteItem) {
        isVisible = false
    }
}

public struct CommandPaletteView: View {
    @ObservedObject var router = CommandPaletteRouter.shared

    public init() {}

    public var body: some View {
        if router.isVisible {
            VStack(spacing: 0) {
                TextField("Search commands, tools, or ask AI...", text: $router.searchQuery)
                    .textFieldStyle(.plain)
                    .padding()
                    .font(.title3)

                Divider()

                List(router.items.filter { router.searchQuery.isEmpty || $0.title.localizedCaseInsensitiveContains(router.searchQuery) }) { item in
                    HStack {
                        Text("[\(item.category)]").font(.caption).bold()
                        Text(item.title)
                        Spacer()
                        if let sc = item.shortcut {
                            Text(sc).font(.caption).foregroundColor(.secondary)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        router.executeCommand(item)
                    }
                }
            }
            .frame(width: 600, height: 400)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(radius: 20)
        }
    }
}
