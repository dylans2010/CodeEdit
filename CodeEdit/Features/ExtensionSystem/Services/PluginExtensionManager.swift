//
//  PluginExtensionManager.swift
//  CodeEdit
//
//

import Foundation

/// Service managing third-party extensions, sandboxed execution, and AI agent tool injection.
public actor PluginExtensionManager {
    public static let shared = PluginExtensionManager()

    private var installedExtensions: [EditorExtensionManifest]

    private init() {
        self.installedExtensions = Self.makeDefaultExtensions()
    }

    /// Discovers and loads extension bundles from the extensions directory.
    public func discoverExtensions(in directoryURL: URL) -> [EditorExtensionManifest] {
        guard let items = try? FileManager.default.contentsOfDirectory(
            at: directoryURL,
            includingPropertiesForKeys: nil
        ) else {
            return installedExtensions
        }

        var loaded: [EditorExtensionManifest] = []
        for bundleURL in items where bundleURL.hasDirectoryPath {
            let manifestURL = bundleURL.appendingPathComponent("extension.json")
            if let data = try? Data(contentsOf: manifestURL),
               let manifest = try? JSONDecoder().decode(EditorExtensionManifest.self, from: data) {
                loaded.append(manifest)
            }
        }

        self.installedExtensions = loaded
        return loaded
    }

    /// Returns list of all active extensions.
    public func getInstalledExtensions() -> [EditorExtensionManifest] {
        return installedExtensions
    }

    /// Pre-populates built-in example extensions.
    private static func makeDefaultExtensions() -> [EditorExtensionManifest] {
        let formatterExt = EditorExtensionManifest(
            extensionID: "com.developer.swift-formatter",
            name: "Swift Formatter Extension",
            version: "1.2.0",
            description: "Standardizes Swift code formatting and indentation according to style rules.",
            author: "CodeEdit Systems Team",
            category: "formatter",
            capabilities: ["code_formatter", "save_hook"],
            entryPoint: "main.swift",
            swiftCodeAssistCapable: true,
            configFields: [
                EditorExtensionConfigField(
                    key: "indentWidth",
                    type: "number",
                    defaultValue: "4",
                    description: "Number of spaces per indentation level"
                )
            ]
        )

        let spellCheckerExt = EditorExtensionManifest(
            extensionID: "com.developer.code-spell-checker",
            name: "Code Spell Checker",
            version: "1.0.4",
            description: "Scans comments and identifiers for spelling mistakes across source code.",
            author: "CodeEdit Systems Team",
            category: "linter",
            capabilities: ["code_linter"],
            entryPoint: "index.js",
            swiftCodeAssistCapable: true,
            configFields: []
        )

        return [formatterExt, spellCheckerExt]
    }
}
