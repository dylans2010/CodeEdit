//
//  PreferencesPlaceholderView.swift
//  CodeEdit
//
//

import SwiftUI
import Preferences

// MARK: - Behaviors Preferences View

struct BehaviorsPreferencesView: View {
    @AppStorage("behaviors.autoSaveBeforeBuild") private var autoSaveBeforeBuild = true
    @AppStorage("behaviors.clearConsoleOnRun") private var clearConsoleOnRun = true
    @AppStorage("behaviors.showBuildNotifications") private var showBuildNotifications = true
    @AppStorage("behaviors.reopenTabsOnLaunch") private var reopenTabsOnLaunch = true

    var body: some View {
        PreferencesContent {
            PreferencesSection("Build & Execution", hideLabels: false) {
                Toggle("Automatically save all open files before building", isOn: $autoSaveBeforeBuild)
                    .toggleStyle(.checkbox)
                Toggle("Clear terminal console when launching a new run", isOn: $clearConsoleOnRun)
                    .toggleStyle(.checkbox)
                Toggle("Show system banner notifications on build success/failure", isOn: $showBuildNotifications)
                    .toggleStyle(.checkbox)
            }

            PreferencesSection("Workspace Session", hideLabels: false) {
                Toggle("Reopen previously active tabs when opening workspace", isOn: $reopenTabsOnLaunch)
                    .toggleStyle(.checkbox)
            }
        }
    }
}

// MARK: - Navigation Preferences View

struct NavigationPreferencesView: View {
    @AppStorage("navigation.singleClickPreview") private var singleClickPreview = true
    @AppStorage("navigation.revealActiveFile") private var revealActiveFile = true
    @AppStorage("navigation.showHiddenDotfiles") private var showHiddenDotfiles = false
    @AppStorage("navigation.fuzzySymbolMatching") private var fuzzySymbolMatching = true

    var body: some View {
        PreferencesContent {
            PreferencesSection("File Navigator", hideLabels: false) {
                Toggle("Single-click opens files in transient preview tab", isOn: $singleClickPreview)
                    .toggleStyle(.checkbox)
                Toggle("Automatically reveal active editor document in file tree", isOn: $revealActiveFile)
                    .toggleStyle(.checkbox)
                Toggle("Show hidden files and dotfiles (.git, .env, .swiftpm)", isOn: $showHiddenDotfiles)
                    .toggleStyle(.checkbox)
            }

            PreferencesSection("Quick Open", hideLabels: false) {
                Toggle("Match symbol declarations in Quick Open (⌘P)", isOn: $fuzzySymbolMatching)
                    .toggleStyle(.checkbox)
            }
        }
    }
}

// MARK: - Components Preferences View

struct ComponentsPreferencesView: View {
    @ObservedObject private var mcpManager = MCPServerManager.shared

    var body: some View {
        PreferencesContent {
            PreferencesSection("Model Context Protocol (MCP)", hideLabels: false) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Configured MCP Servers (\(mcpManager.servers.count))")
                        .font(.headline)

                    ForEach(mcpManager.servers) { server in
                        HStack {
                            Image(systemName: "server.rack")
                                .foregroundStyle(server.status == .connected ? .green : .secondary)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(server.config.displayName)
                                    .font(.subheadline)
                                Text(server.config.executablePath ?? "")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Toggle("", isOn: Binding(
                                get: { server.status == .connected },
                                set: { isEnabled in
                                    if isEnabled {
                                        Task {
                                            try? await mcpManager.connect(to: server.id)
                                        }
                                    } else {
                                        mcpManager.disconnect(serverID: server.id)
                                    }
                                }
                            ))
                            .toggleStyle(.switch)
                        }
                        .padding(.vertical, 4)
                    }

                    HStack {
                        Button("Manage MCP Servers...") {
                            OperationsWindowManager.show()
                        }
                        .buttonStyle(.bordered)
                        Button("Reload Servers") {
                            mcpManager.loadPersistedServers()
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }

            PreferencesSection("Extensions & Plugins", hideLabels: false) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Universal IDE Plugin Architecture")
                        .font(.headline)
                    Text("Extensions dynamically load language grammars, snippets, and tools.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

// MARK: - Advanced Preferences View

struct AdvancedPreferencesView: View {
    @AppStorage("advanced.experimentalAST") private var experimentalAST = false
    @AppStorage("advanced.metalAcceleration") private var metalAcceleration = true
    @State private var showingResetAlert = false

    var body: some View {
        PreferencesContent {
            PreferencesSection("Compiler & Runtime", hideLabels: false) {
                Toggle("Enable experimental SwiftSyntax AST scope detector", isOn: $experimentalAST)
                    .toggleStyle(.checkbox)
                Toggle("Use Metal GPU acceleration for text rendering", isOn: $metalAcceleration)
                    .toggleStyle(.checkbox)
            }

            PreferencesSection("Maintenance & Reset", hideLabels: false) {
                VStack(alignment: .leading, spacing: 8) {
                    Button("Clear Derived Data & Caches") {
                        let derivedData = FileManager.default.homeDirectoryForCurrentUser
                            .appendingPathComponent("Library/Developer/Xcode/DerivedData")
                        try? FileManager.default.removeItem(at: derivedData)
                    }
                    .buttonStyle(.bordered)

                    Button("Reset All Preferences to Defaults...") {
                        showingResetAlert = true
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                }
            }
        }
        .alert("Reset All Preferences?", isPresented: $showingResetAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Reset to Defaults", role: .destructive) {
                AppPreferencesModel.shared.preferences = AppPreferences()
            }
        } message: {
            Text("This will restore all IDE preferences, keybindings, and editor settings to their initial values.")
        }
    }
}

/// Backward compatibility placeholder
struct PreferencesPlaceholderView: View {
    var body: some View {
        AdvancedPreferencesView()
    }
}
