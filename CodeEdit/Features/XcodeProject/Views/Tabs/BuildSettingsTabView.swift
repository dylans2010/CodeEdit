//
//  BuildSettingsTabView.swift
//  CodeEdit
//
//  Created by Austin Condiff on 14/09/26.
//

import SwiftUI

struct BuildSettingItem: Identifiable {
    var id: String { key }
    var key: String
    var title: String
    var category: String
    var defaultValue: String
}

struct BuildSettingsTabView: View {
    @ObservedObject var manager: XcodeProjectManager

    static let allSettings: [BuildSettingItem] = [
        // Architectures
        BuildSettingItem(key: "ARCHS", title: "Architectures", category: "Architectures", defaultValue: "$(ARCHS_STANDARD)"),
        BuildSettingItem(key: "SDKROOT", title: "Base SDK", category: "Architectures", defaultValue: "macosx"),
        BuildSettingItem(key: "SUPPORTED_PLATFORMS", title: "Supported Platforms", category: "Architectures", defaultValue: "macosx"),
        // Build Options
        BuildSettingItem(key: "DEBUG_INFORMATION_FORMAT", title: "Debug Information Format", category: "Build Options", defaultValue: "dwarf-with-dsym"),
        BuildSettingItem(key: "ENABLE_TESTABILITY", title: "Enable Testability", category: "Build Options", defaultValue: "YES"),
        BuildSettingItem(key: "VALIDATE_PRODUCT", title: "Validate Built Product", category: "Build Options", defaultValue: "NO"),
        // Code Signing
        BuildSettingItem(key: "CODE_SIGN_IDENTITY", title: "Code Signing Identity", category: "Code Signing", defaultValue: "Apple Development"),
        BuildSettingItem(key: "CODE_SIGN_STYLE", title: "Code Signing Style", category: "Code Signing", defaultValue: "Automatic"),
        BuildSettingItem(key: "DEVELOPMENT_TEAM", title: "Development Team", category: "Code Signing", defaultValue: ""),
        BuildSettingItem(key: "PROVISIONING_PROFILE_SPECIFIER", title: "Provisioning Profile", category: "Code Signing", defaultValue: ""),
        // Deployment
        BuildSettingItem(key: "MACOSX_DEPLOYMENT_TARGET", title: "macOS Deployment Target", category: "Deployment", defaultValue: "13.0"),
        BuildSettingItem(key: "IPHONEOS_DEPLOYMENT_TARGET", title: "iOS Deployment Target", category: "Deployment", defaultValue: "16.0"),
        BuildSettingItem(key: "INSTALL_PATH", title: "Installation Directory", category: "Deployment", defaultValue: "$(LOCAL_APPS_DIR)"),
        // Packaging
        BuildSettingItem(key: "PRODUCT_BUNDLE_IDENTIFIER", title: "Product Bundle Identifier", category: "Packaging", defaultValue: "com.example.app"),
        BuildSettingItem(key: "PRODUCT_NAME", title: "Product Name", category: "Packaging", defaultValue: "$(TARGET_NAME)"),
        BuildSettingItem(key: "INFOPLIST_FILE", title: "Info.plist File", category: "Packaging", defaultValue: "Info.plist"),
        BuildSettingItem(key: "GENERATE_INFOPLIST_FILE", title: "Generate Info.plist File", category: "Packaging", defaultValue: "YES"),
        // Search Paths
        BuildSettingItem(key: "FRAMEWORK_SEARCH_PATHS", title: "Framework Search Paths", category: "Search Paths", defaultValue: ""),
        BuildSettingItem(key: "HEADER_SEARCH_PATHS", title: "Header Search Paths", category: "Search Paths", defaultValue: ""),
        BuildSettingItem(key: "LIBRARY_SEARCH_PATHS", title: "Library Search Paths", category: "Search Paths", defaultValue: ""),
        // Swift Compiler
        BuildSettingItem(key: "SWIFT_VERSION", title: "Swift Language Version", category: "Swift Compiler - Language", defaultValue: "5.0"),
        BuildSettingItem(key: "SWIFT_OPTIMIZATION_LEVEL", title: "Optimization Level", category: "Swift Compiler - Code Generation", defaultValue: "-Onone"),
        BuildSettingItem(key: "SWIFT_COMPILATION_MODE", title: "Compilation Mode", category: "Swift Compiler - Code Generation", defaultValue: "singlefile")
    ]

    var categories: [String] {
        var result: [String] = []
        for setting in filteredSettings {
            if !result.contains(setting.category) {
                result.append(setting.category)
            }
        }
        return result
    }

    var filteredSettings: [BuildSettingItem] {
        var list = Self.allSettings

        if let currentConfig = manager.currentConfiguration {
            for (key, val) in currentConfig.buildSettings {
                if !list.contains(where: { $0.key == key }) {
                    list.append(BuildSettingItem(
                        key: key,
                        title: key,
                        category: "User-Defined",
                        defaultValue: val
                    ))
                }
            }
        }

        if manager.buildSettingsFilter == .customized {
            list = list.filter {
                !manager.getSetting($0.key).isEmpty
            }
        }

        if !manager.buildSettingsSearchText.isEmpty {
            let query = manager.buildSettingsSearchText.lowercased()
            list = list.filter {
                $0.title.lowercased().contains(query) ||
                $0.key.lowercased().contains(query) ||
                $0.category.lowercased().contains(query) ||
                manager.getSetting($0.key).lowercased().contains(query)
            }
        }

        return list
    }

    var body: some View {
        VStack(spacing: 0) {
            toolbarView
            Divider()
            settingsList
        }
    }

    private var toolbarView: some View {
        HStack(spacing: 12) {
            Picker("Configuration", selection: $manager.selectedConfigName) {
                if let target = manager.selectedTarget {
                    ForEach(target.configurations) { config in
                        Text(config.name).tag(config.name)
                    }
                } else if let project = manager.project {
                    ForEach(project.configurations) { config in
                        Text(config.name).tag(config.name)
                    }
                }
            }
            .pickerStyle(.menu)
            .frame(width: 140)

            Picker("", selection: $manager.buildSettingsFilter) {
                ForEach(BuildSettingsFilter.allCases, id: \.self) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 160)

            Spacer()

            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Filter build settings...", text: $manager.buildSettingsSearchText)
                    .textFieldStyle(.plain)
                    .frame(width: 180)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(6)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var settingsList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                ForEach(categories, id: \.self) { category in
                    VStack(alignment: .leading, spacing: 0) {
                        categoryHeader(category)

                        VStack(spacing: 0) {
                            ForEach(filteredSettings.filter { $0.category == category }) { item in
                                settingRow(item)
                                Divider()
                            }
                        }
                        .background(Color(nsColor: .controlBackgroundColor))
                        .cornerRadius(6)
                    }
                }
            }
            .padding(16)
        }
    }

    private func categoryHeader(_ category: String) -> some View {
        Text(category.uppercased())
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(.secondary)
            .padding(.horizontal, 4)
            .padding(.bottom, 6)
    }

    private func settingRow(_ item: BuildSettingItem) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.system(size: 13, weight: .medium))
                Text(item.key)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            .frame(width: 240, alignment: .leading)

            TextField(
                item.defaultValue,
                text: Binding(
                    get: { manager.getSetting(item.key, defaultValue: item.defaultValue) },
                    set: { manager.updateBuildSetting(key: item.key, value: $0) }
                )
            )
            .textFieldStyle(.plain)
            .font(.system(size: 12, design: .monospaced))
            .padding(4)
            .background(Color(nsColor: .quaternaryLabelColor).opacity(0.3))
            .cornerRadius(4)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }
}
