//
//  AssistAgentView.swift
//  CodeEdit
//

import SwiftUI
import AppKit

public struct AssistAgentView: View {
    @ObservedObject public var session = AssistAgentSession.shared
    @State private var objectiveInput: String = ""
    @State private var selectedTab: Int = 0

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            // Header
            headerBar

            Divider()

            // Sub-tabs: Session, Checklist, Diagnostics
            Picker("", selection: $selectedTab) {
                Text("Session").tag(0)
                Text("Checklist (\(session.checklist.count))").tag(1)
                Text("Events (\(session.events.count))").tag(2)
            }
            .pickerStyle(.segmented)
            .padding(8)

            Divider()

            // Tab Content
            switch selectedTab {
            case 0:
                sessionTurnsView
            case 1:
                checklistView
            case 2:
                eventsLogView
            default:
                sessionTurnsView
            }

            Divider()

            // Input & Controls
            bottomControlBar
        }
        .frame(minWidth: 320, maxWidth: .infinity, minHeight: 400, maxHeight: .infinity)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
    }

    private var headerBar: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(statusColor(for: session.status))
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text("Assist Autonomous Agent")
                    .font(.system(size: 12, weight: .semibold))
                Text(session.status.rawValue)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }

            Spacer()

            if session.isRunning {
                ProgressView()
                    .controlSize(.small)
                Button("Cancel") {
                    session.cancelSession()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding(10)
    }

    private var sessionTurnsView: some View {
        ScrollViewReader { _ in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 10) {
                    if session.turns.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 28))
                                .foregroundColor(.accentColor)
                            Text("Ready to assist with your project")
                                .font(.system(size: 12, weight: .medium))
                            Text("Type an objective below to formulate a plan and execute tasks.")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(32)
                        .frame(maxWidth: .infinity)
                    } else {
                        ForEach(session.turns) { turn in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(turn.role.uppercased())
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundColor(turn.role == "user" ? .accentColor : .purple)
                                    Spacer()
                                    Text(turn.timestamp, style: .time)
                                        .font(.system(size: 9))
                                        .foregroundColor(.secondary)
                                }
                                Text(turn.content)
                                    .font(.system(size: 11))
                                    .textSelection(.enabled)
                            }
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(turn.role == "user" ? Color.accentColor.opacity(0.1) : Color(nsColor: .controlBackgroundColor))
                            )
                        }
                    }
                }
                .padding(10)
            }
        }
    }

    private var checklistView: some View {
        List {
            if session.checklist.isEmpty {
                Text("No checklist items generated yet.")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            } else {
                ForEach(session.checklist) { item in
                    HStack(spacing: 8) {
                        Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(item.isCompleted ? .green : .secondary)
                            .font(.system(size: 12))
                        Text(item.title)
                            .font(.system(size: 11))
                            .strikethrough(item.isCompleted)
                        Spacer()
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .listStyle(.plain)
    }

    private var eventsLogView: some View {
        List {
            ForEach(session.events) { event in
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(event.state.rawValue)
                            .font(.system(size: 10, weight: .semibold))
                        Spacer()
                        Text(event.timestamp, style: .time)
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }
                    Text(event.summary)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    if let result = event.toolResult {
                        Text(result)
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(.secondary.opacity(0.8))
                            .lineLimit(2)
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .listStyle(.plain)
    }

    private var bottomControlBar: some View {
        HStack(spacing: 8) {
            TextField("Enter objective (e.g. 'Audit project for data races')...", text: $objectiveInput)
                .textFieldStyle(.plain)
                .font(.system(size: 12))
                .padding(6)
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(6)
                .onSubmit {
                    submitObjective()
                }

            Button {
                submitObjective()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 16))
            }
            .buttonStyle(.plain)
            .disabled(objectiveInput.trimmingCharacters(in: .whitespaces).isEmpty || session.isRunning)
        }
        .padding(8)
    }

    private func submitObjective() {
        let trimmed = objectiveInput.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        objectiveInput = ""
        session.startSession(objective: trimmed)
    }

    private func statusColor(for status: AgentSessionStatus) -> Color {
        switch status {
        case .idle: return .secondary
        case .receivingRequest, .analyzingRepository, .collectingContext, .planning, .selectingTools: return .blue
        case .executingTool: return .orange
        case .validating, .reviewing: return .purple
        case .generatingSummary, .completing, .terminated: return .green
        case .failed: return .red
        }
    }
}
