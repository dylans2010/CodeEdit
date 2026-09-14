//
//  AppleProjectSetupView.swift
//  CodeEdit
//
//  Created by CodeEdit on 2024/09/14.
//

import SwiftUI
import AppKit

struct AppleProjectSetupView: View {
    let template: ProjectTemplate
    @Binding var isPresented: Bool
    let onBack: () -> Void
    let openDocument: (URL?, @escaping () -> Void) -> Void
    let dismissWindow: () -> Void

    @State private var appName: String
    @State private var orgIdentifier = "com.example"
    @State private var appVersion = "1.0.0"
    @State private var buildNumber = "1"
    @State private var appDescription = "A modern native app for Apple devices."
    @State private var selectedPlatforms: Set<String>
    @State private var errorMessage: String?
    @State private var showErrorAlert = false

    init(
        template: ProjectTemplate,
        isPresented: Binding<Bool>,
        onBack: @escaping () -> Void,
        openDocument: @escaping (URL?, @escaping () -> Void) -> Void,
        dismissWindow: @escaping () -> Void
    ) {
        self.template = template
        self._isPresented = isPresented
        self.onBack = onBack
        self.openDocument = openDocument
        self.dismissWindow = dismissWindow

        _appName = State(initialValue: template.defaultProjectName)
        _selectedPlatforms = State(initialValue: Self.defaultPlatforms(for: template))
    }

    private var bundleIdentifier: String {
        let cleanOrg = orgIdentifier.trimmingCharacters(in: .whitespaces)
        let cleanName = appName.trimmingCharacters(in: .whitespaces)
        return "\(cleanOrg).\(cleanName)"
    }

    var body: some View {
        VStack(spacing: 0) {
            headerBar
            Divider()

            ScrollView {
                VStack(spacing: 20) {
                    projectDetailsSection
                    platformsSection
                    descriptionSection
                }
                .padding(24)
            }

            Divider()
            footerBar
        }
        .frame(width: 680, height: 540)
        .background(Color(NSColor.windowBackgroundColor))
        .alert(isPresented: $showErrorAlert) {
            Alert(
                title: Text("Error"),
                message: Text(errorMessage ?? "Unable to create project."),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.blue.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: "apple.logo")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(.blue)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Configure Apple Project")
                    .font(.system(size: 16, weight: .bold))
                Text("Customize bundle ID, version, and platforms for \(template.name)")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
    }

    // MARK: - Form Sections

    private var projectDetailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("PROJECT DETAILS")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.secondary)

            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 10) {
                GridRow {
                    Text("App Name:")
                        .font(.system(size: 12, weight: .medium))
                        .gridColumnAlignment(.trailing)
                    TextField("App Name", text: $appName)
                        .textFieldStyle(.roundedBorder)
                }

                GridRow {
                    Text("Organization ID:")
                        .font(.system(size: 12, weight: .medium))
                    TextField("com.example", text: $orgIdentifier)
                        .textFieldStyle(.roundedBorder)
                }

                GridRow {
                    Text("Bundle ID:")
                        .font(.system(size: 12, weight: .medium))
                    Text(bundleIdentifier)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.accentColor)
                        .textSelection(.enabled)
                }

                GridRow {
                    Text("Version & Build:")
                        .font(.system(size: 12, weight: .medium))
                    HStack(spacing: 8) {
                        TextField("Version", text: $appVersion)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 100)
                        Text("Build")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        TextField("Build", text: $buildNumber)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 60)
                    }
                }
            }
        }
        .padding(16)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.4))
        .cornerRadius(8)
    }

    private var platformsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("SUPPORTED PLATFORMS")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.secondary)

            HStack(spacing: 12) {
                platformButton(name: "macOS", icon: "macwindow")
                platformButton(name: "iOS", icon: "iphone")
                platformButton(name: "watchOS", icon: "applewatch")
                platformButton(name: "visionOS", icon: "visionpro")
                platformButton(name: "tvOS", icon: "tv")
            }
        }
        .padding(16)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.4))
        .cornerRadius(8)
    }

    private func platformButton(name: String, icon: String) -> some View {
        let isSelected = selectedPlatforms.contains(name)
        return Button {
            if isSelected {
                if selectedPlatforms.count > 1 { selectedPlatforms.remove(name) }
            } else {
                selectedPlatforms.insert(name)
            }
        } label: {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                Text(name)
                    .font(.system(size: 11, weight: .medium))
            }
            .frame(width: 90, height: 60)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(isSelected ? Color.accentColor : Color.secondary.opacity(0.3), lineWidth: 1.5)
            )
            .foregroundColor(isSelected ? .accentColor : .secondary)
        }
        .buttonStyle(.plain)
    }

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("APP DESCRIPTION")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.secondary)

            TextField("Description", text: $appDescription)
                .textFieldStyle(.roundedBorder)
        }
        .padding(16)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.4))
        .cornerRadius(8)
    }

    // MARK: - Footer

    private var footerBar: some View {
        HStack {
            Button("Back") {
                onBack()
            }
            .keyboardShortcut(.cancelAction)

            Spacer()

            Button("Cancel") {
                isPresented = false
            }

            Button("Create Project...") {
                createProject()
            }
            .keyboardShortcut(.defaultAction)
            .buttonStyle(.borderedProminent)
            .disabled(appName.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
    }

    // MARK: - Creation

    private func createProject() {
        let panel = NSSavePanel()
        panel.title = "Create Apple Project"
        panel.prompt = "Create"
        panel.nameFieldStringValue = appName.trimmingCharacters(in: .whitespaces)
        panel.canCreateDirectories = true
        panel.showsTagField = false

        guard panel.runModal() == .OK, let targetURL = panel.url else {
            return
        }

        do {
            try TemplateManager.shared.instantiate(
                template: template,
                at: targetURL,
                projectName: appName,
                bundleID: bundleIdentifier,
                appVersion: appVersion,
                buildNumber: buildNumber,
                appDescription: appDescription
            )
            isPresented = false
            openDocument(targetURL, dismissWindow)
        } catch {
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
    }

    private static func defaultPlatforms(for template: ProjectTemplate) -> Set<String> {
        let tid = template.id
        if tid.contains("ios") { return ["iOS"] }
        if tid.contains("watchos") { return ["watchOS"] }
        if tid.contains("visionos") { return ["visionOS"] }
        if tid.contains("tvos") { return ["tvOS"] }
        if tid.contains("multiplatform") { return ["macOS", "iOS", "watchOS", "visionOS", "tvOS"] }
        return ["macOS"]
    }
}
