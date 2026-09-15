// swiftlint:disable type_body_length

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
    @State private var generateXcodeProj = true
    @State private var showComponentInstallSheet = false
    @State private var isInstallingComponent = false
    @State private var installProgressMessage = ""
    @State private var pendingTargetURL: URL?
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
                    xcodeSection
                    descriptionSection
                }
                .padding(24)
            }

            Divider()
            footerBar
        }
        .frame(width: 680, height: 570)
        .background(Color(NSColor.windowBackgroundColor))
        .alert(isPresented: $showErrorAlert) {
            Alert(
                title: Text("Error"),
                message: Text(errorMessage ?? "Unable to create project."),
                dismissButton: .default(Text("OK"))
            )
        }
        .sheet(isPresented: $showComponentInstallSheet) {
            componentInstallSheet
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

    private var xcodeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("XCODE INTEGRATION")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.secondary)

            Toggle(isOn: $generateXcodeProj) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Generate Xcode Project (.xcodeproj)")
                        .font(.system(size: 12, weight: .medium))
                    Text("Produces a native .xcodeproj via XcodeGen for full Xcode compatibility.")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
            .toggleStyle(.checkbox)
        }
        .padding(16)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.4))
        .cornerRadius(8)
    }

    private var componentInstallSheet: some View {
        VStack(spacing: 16) {
            Image(systemName: "shippingbox.and.arrow.backward")
                .font(.system(size: 38))
                .foregroundColor(.blue)

            Text("A system component is required to finalize this project, install it?")
                .font(.headline)
                .multilineTextAlignment(.center)

            Text("XcodeGen is required to generate the .xcodeproj file for Apple Platforms. CodeEdit will use Homebrew to install it onto your Mac.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)

            if isInstallingComponent {
                VStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.9)
                    Text(installProgressMessage)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }

            HStack(spacing: 12) {
                Button("Cancel") {
                    showComponentInstallSheet = false
                    isInstallingComponent = false
                }
                .disabled(isInstallingComponent)

                Button("Install via Homebrew") {
                    installComponentAndFinalize()
                }
                .buttonStyle(.borderedProminent)
                .disabled(isInstallingComponent)
            }
            .padding(.top, 6)
        }
        .padding(24)
        .frame(width: 440, height: 260)
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
}

// MARK: - Creation & Installation Extension

extension AppleProjectSetupView {
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

        if generateXcodeProj {
            Task {
                let installed = await XcodeGenService.shared.isXcodeGenInstalled()
                if !installed {
                    await MainActor.run {
                        self.pendingTargetURL = targetURL
                        self.showComponentInstallSheet = true
                    }
                } else {
                    await finalizeProjectCreation(at: targetURL)
                }
            }
        } else {
            Task {
                await finalizeProjectCreation(at: targetURL)
            }
        }
    }

    private func installComponentAndFinalize() {
        isInstallingComponent = true
        installProgressMessage = "Installing xcodegen via Homebrew..."

        Task {
            do {
                try await XcodeGenService.shared.installXcodeGenViaHomebrew { status in
                    Task { @MainActor in
                        self.installProgressMessage = status
                    }
                }
                await MainActor.run {
                    self.isInstallingComponent = false
                    self.showComponentInstallSheet = false
                    if let targetURL = self.pendingTargetURL {
                        Task {
                            await self.finalizeProjectCreation(at: targetURL)
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    self.isInstallingComponent = false
                    self.errorMessage = error.localizedDescription
                    self.showErrorAlert = true
                }
            }
        }
    }

    private func finalizeProjectCreation(at targetURL: URL) async {
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

            if generateXcodeProj {
                let primaryPlatform = selectedPlatforms.first ?? "macOS"
                try await XcodeGenService.shared.generateXcodeProject(
                    destinationURL: targetURL,
                    projectName: appName,
                    bundleID: bundleIdentifier,
                    appVersion: appVersion,
                    buildNumber: buildNumber,
                    platform: primaryPlatform
                )
            }

            await MainActor.run {
                self.isPresented = false
                self.openDocument(targetURL, self.dismissWindow)
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.showErrorAlert = true
            }
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
