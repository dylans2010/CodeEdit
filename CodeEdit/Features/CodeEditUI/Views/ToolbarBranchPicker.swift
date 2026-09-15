//
//  ToolbarBranchPicker.swift
//  CodeEdit
//
//

// swiftlint:disable file_length type_body_length line_length

import SwiftUI
import CodeEditSymbols

/// A modern unified toolbar control combining Scheme selection, XcodeBuild trigger, and Git Branch switcher.
struct ToolbarBranchPicker: View {
    private var workspace: WorkspaceClient?
    private var gitClient: GitClient?

    @ObservedObject
    private var buildManager = WorkspaceBuildManager.shared

    @Environment(\.controlActiveState)
    private var controlActive

    @State private var isHoveringBuild: Bool = false
    @State private var isHoveringScheme: Bool = false
    @State private var isHoveringBranch: Bool = false
    @State private var displayBranchPopover: Bool = false
    @State private var displaySchemePopover: Bool = false
    @State private var currentBranch: String?

    /// Initializes the ``ToolbarBranchPicker`` with an instance of a `WorkspaceClient`
    /// - Parameter shellClient: An instance of the current `ShellClient`
    /// - Parameter workspace: An instance of the current `WorkspaceClient`
    init(
        shellClient: ShellClient,
        workspace: WorkspaceClient?
    ) {
        self.workspace = workspace
        if let folderURL = workspace?.folderURL() {
            self.gitClient = GitClient(directoryURL: folderURL, shellClient: shellClient)
        }
        self._currentBranch = State(initialValue: try? gitClient?.getCurrentBranchName())
    }

    var body: some View {
        HStack(alignment: .center, spacing: 5) {
            // Build Action Button
            buildButton

            // Scheme & Destination Capsule
            schemeSelectorPill

            // Git Branch / Connect Capsule
            branchPickerPill

            // Build Status Flash Indicator
            statusIndicatorView
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .frame(height: 28)
        .task {
            if let folderURL = workspace?.folderURL() {
                await buildManager.loadSchemes(workspaceURL: folderURL)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            currentBranch = try? gitClient?.getCurrentBranchName()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("gitStatusChanged"))) { _ in
            currentBranch = try? gitClient?.getCurrentBranchName()
        }
    }

    // MARK: - Subviews

    private var buildButton: some View {
        Button {
            guard let folderURL = workspace?.folderURL() else { return }
            Task { @MainActor in
                await buildManager.build(workspaceURL: folderURL)
            }
        } label: {
            HStack(spacing: 0) {
                if buildManager.isBuilding {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .controlSize(.small)
                        .frame(width: 14, height: 14)
                } else {
                    Image(systemName: "hammer.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(
                            controlActive == .inactive
                                ? inactiveColor
                                : (isHoveringBuild ? .accentColor : .primary)
                        )
                }
            }
            .frame(width: 26, height: 22)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isHoveringBuild ? Color.primary.opacity(0.12) : Color.primary.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
        .onHover { isHoveringBuild = $0 }
        .help(buildManager.isBuilding ? "Building..." : "Build \(activeSchemeName) (⌘B)")
    }

    private var schemeSelectorPill: some View {
        Button {
            displaySchemePopover.toggle()
        } label: {
            HStack(spacing: 5) {
                Image(systemName: "cube.box.fill")
                    .font(.system(size: 11))
                    .foregroundColor(controlActive == .inactive ? inactiveColor : .accentColor)

                Text(activeSchemeName)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(controlActive == .inactive ? inactiveColor : .primary)
                    .lineLimit(1)

                Image(systemName: "chevron.down")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(controlActive == .inactive ? inactiveColor : .secondary)
            }
            .padding(.horizontal, 8)
            .frame(height: 22)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isHoveringScheme ? Color.primary.opacity(0.10) : Color.primary.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
        .onHover { isHoveringScheme = $0 }
        .popover(isPresented: $displaySchemePopover, arrowEdge: .bottom) {
            SchemePopoverView(workspaceURL: workspace?.folderURL())
        }
        .help("Select Active Scheme")
    }

    private var branchPickerPill: some View {
        Button {
            if currentBranch != nil {
                displayBranchPopover.toggle()
            } else {
                SourceControlConnectView.openConnectWindow()
            }
        } label: {
            HStack(spacing: 4) {
                if let branch = currentBranch {
                    Image.checkout
                        .font(.system(size: 11))
                        .foregroundColor(controlActive == .inactive ? inactiveColor : .secondary)
                    Text(branch)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(controlActive == .inactive ? inactiveColor : .secondary)
                        .lineLimit(1)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 7, weight: .bold))
                        .foregroundColor(controlActive == .inactive ? inactiveColor : .secondary.opacity(0.7))
                } else {
                    Image(systemName: "point.3.connected.trianglepath.dotted")
                        .font(.system(size: 10))
                        .foregroundColor(.blue)
                    Text("Connect")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 7)
            .frame(height: 22)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isHoveringBranch ? Color.primary.opacity(0.10) : Color.primary.opacity(0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.primary.opacity(0.06), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
        .onHover { isHoveringBranch = $0 }
        .popover(isPresented: $displayBranchPopover, arrowEdge: .bottom) {
            PopoverView(gitClient: gitClient, currentBranch: $currentBranch)
        }
        .help(currentBranch != nil ? "Branch: \(currentBranch ?? "") (Click to switch)" : "Connect to GitHub")
    }

    @ViewBuilder
    private var statusIndicatorView: some View {
        if buildManager.isBuilding {
            HStack(spacing: 3) {
                Text("Building...")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.blue)
            }
            .padding(.horizontal, 6)
            .frame(height: 20)
            .background(Capsule().fill(Color.blue.opacity(0.12)))
        } else if buildManager.errorCount > 0 {
            Button {
                NotificationCenter.default.post(name: NSNotification.Name("FocusIssuesNavigator"), object: nil)
            } label: {
                HStack(spacing: 3) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.red)
                    Text("\(buildManager.errorCount)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.red)
                }
                .padding(.horizontal, 6)
                .frame(height: 20)
                .background(Capsule().fill(Color.red.opacity(0.12)))
            }
            .buttonStyle(.plain)
        } else if buildManager.lastResult?.isSuccess == true {
            HStack(spacing: 3) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.green)
                Text("Succeeded")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.green)
            }
            .padding(.horizontal, 6)
            .frame(height: 20)
            .background(Capsule().fill(Color.green.opacity(0.12)))
        }
    }

    private var inactiveColor: Color {
        Color(nsColor: .disabledControlTextColor)
    }

    private var activeSchemeName: String {
        if !buildManager.selectedScheme.isEmpty {
            return buildManager.selectedScheme
        }
        return workspace?.folderURL()?.lastPathComponent ?? "Scheme"
    }

    // MARK: - Scheme Popover View

    private struct SchemePopoverView: View {
        let workspaceURL: URL?
        @ObservedObject private var buildManager = WorkspaceBuildManager.shared
        @Environment(\.dismiss) private var dismiss

        var body: some View {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Image(systemName: "cube.box.fill")
                        .foregroundColor(.accentColor)
                    Text("Schemes")
                        .font(.system(size: 12, weight: .bold))
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)

                Divider()

                ScrollView {
                    VStack(alignment: .leading, spacing: 2) {
                        if buildManager.availableSchemes.isEmpty {
                            Button {
                                dismiss()
                            } label: {
                                HStack {
                                    Text(workspaceURL?.lastPathComponent ?? "Default")
                                        .font(.system(size: 11))
                                    Spacer()
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.accentColor)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        } else {
                            ForEach(buildManager.availableSchemes, id: \.self) { scheme in
                                Button {
                                    buildManager.selectedScheme = scheme
                                    dismiss()
                                } label: {
                                    HStack {
                                        Image(systemName: "cube.box")
                                            .font(.system(size: 10))
                                            .foregroundColor(.secondary)
                                        Text(scheme)
                                            .font(.system(size: 11, weight: scheme == buildManager.selectedScheme ? .semibold : .regular))
                                        Spacer()
                                        if scheme == buildManager.selectedScheme {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundColor(.accentColor)
                                        }
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 5)
                                    .background(scheme == buildManager.selectedScheme ? Color.accentColor.opacity(0.12) : Color.clear)
                                    .cornerRadius(4)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(6)
                }
                .frame(maxHeight: 180)

                Divider()

                HStack {
                    Button {
                        if let url = workspaceURL {
                            Task {
                                _ = try? await buildManager.clean(workspaceURL: url)
                            }
                        }
                        dismiss()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "trash")
                            Text("Clean Build Folder")
                        }
                        .font(.system(size: 11))
                    }
                    .buttonStyle(.borderless)

                    Spacer()

                    Text("My Mac")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
            }
            .frame(width: 250)
        }
    }

    // MARK: - Git Branch Popover View

    private struct PopoverView: View {
        var gitClient: GitClient?
        @Binding var currentBranch: String?

        var body: some View {
            VStack(alignment: .leading) {
                if let currentBranch = currentBranch {
                    VStack(alignment: .leading, spacing: 0) {
                        headerLabel("Current Branch")
                        BranchCell(name: currentBranch, active: true) {}
                    }
                }
                if !branchNames.isEmpty {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            headerLabel("Branches")
                            ForEach(branchNames, id: \.self) { branch in
                                BranchCell(name: branch) {
                                    try? gitClient?.checkoutBranch(branch)
                                    currentBranch = try? gitClient?.getCurrentBranchName()
                                }
                            }
                        }
                    }
                }
            }
            .padding(.top, 10)
            .padding(5)
            .frame(width: 340)
        }

        func headerLabel(_ title: String) -> some View {
            Text(title)
                .font(.subheadline.bold())
                .foregroundColor(.secondary)
                .padding(.horizontal)
                .padding(.vertical, 5)
        }

        struct BranchCell: View {
            var name: String
            var active: Bool = false
            var action: () -> Void

            @Environment(\.dismiss)
            private var dismiss

            @State
            private var isHovering: Bool = false

            var body: some View {
                Button {
                    action()
                    dismiss()
                } label: {
                    HStack {
                        Label {
                            Text(name)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } icon: {
                            Image.checkout
                                .imageScale(.large)
                        }
                        .foregroundColor(isHovering ? .white : .secondary)
                        if active {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(isHovering ? .white : .green)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(
                    EffectView.selectionBackground(isHovering)
                )
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .onHover { active in
                    isHovering = active
                }
            }
        }

        var branchNames: [String] {
            ((try? gitClient?.getBranches(false)) ?? []).filter { $0 != currentBranch }
        }
    }
}
