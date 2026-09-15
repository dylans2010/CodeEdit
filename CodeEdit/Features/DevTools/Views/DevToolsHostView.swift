//
//  DevToolsHostView.swift
//  CodeEdit
//
//

import SwiftUI

/// Dynamic runner workspace for executing any selected offline developer utility.
public struct DevToolsHostView: View {
    public let toolItem: DevToolItem

    @State private var inputText: String = ""
    @State private var outputText: String = ""
    @State private var secondaryOption: String = ""
    @State private var isProcessing: Bool = false
    @State private var copiedConfirmation: Bool = false

    public init(toolItem: DevToolItem) {
        self.toolItem = toolItem
    }

    public var body: some View {
        VStack(spacing: 0) {
            headerBar
            Divider()
            contentWorkspace
        }
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            loadDefaultInput()
        }
    }

    // MARK: - Header Bar
    private var headerBar: some View {
        HStack {
            Image(systemName: toolItem.iconName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.accentColor)
            VStack(alignment: .leading, spacing: 2) {
                Text(toolItem.title)
                    .font(.headline)
                Text(toolItem.summary)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            executeToolbar
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private var executeToolbar: some View {
        HStack(spacing: 8) {
            Button {
                executeAction()
            } label: {
                Label("Execute", systemImage: "play.fill")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)

            Button {
                copyOutput()
            } label: {
                Label(copiedConfirmation ? "Copied!" : "Copy", systemImage: "doc.on.doc")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .disabled(outputText.isEmpty)

            Button {
                inputText = ""
                outputText = ""
            } label: {
                Label("Clear", systemImage: "trash")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
    }

    // MARK: - Content Workspace
    private var contentWorkspace: some View {
        HSplitView {
            inputSection
                .frame(minWidth: 250, maxWidth: .infinity, maxHeight: .infinity)
            outputSection
                .frame(minWidth: 250, maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Input")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Text("\(inputText.count) chars")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)

            TextEditor(text: $inputText)
                .font(.system(.body, design: .monospaced))
                .padding(4)
                .background(Color(NSColor.textBackgroundColor))
                .cornerRadius(6)
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
        }
    }

    private var outputSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Output")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Text("\(outputText.count) chars")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)

            TextEditor(text: $outputText)
                .font(.system(.body, design: .monospaced))
                .padding(4)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(6)
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
        }
    }

    // MARK: - Actions
    private func executeAction() {
        var options: [String: String] = [:]
        if !secondaryOption.isEmpty {
            options["secret"] = secondaryOption
            options["pattern"] = secondaryOption
            options["method"] = secondaryOption
        }
        outputText = DevToolsEngine.shared.executeTool(
            toolID: toolItem.id,
            input: inputText,
            options: options
        )
    }

    private func copyOutput() {
        guard !outputText.isEmpty else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(outputText, forType: .string)
        copiedConfirmation = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            copiedConfirmation = false
        }
    }

    private func loadDefaultInput() {
        if toolItem.id.starts(with: "json") {
            inputText = "{\n  \"id\": 101,\n  \"name\": \"Antigravity\",\n  \"isActive\": true\n}"
        } else if toolItem.id == "hash_generator" || toolItem.id == "case_converter" {
            inputText = "Hello Universal IDE World!"
        } else if toolItem.id == "unix_permissions_calculator" {
            inputText = "755"
        } else if toolItem.id == "epoch_converter" {
            inputText = "\(Int(Date().timeIntervalSince1970))"
        }
    }
}
