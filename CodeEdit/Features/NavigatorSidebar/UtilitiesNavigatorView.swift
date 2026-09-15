//
//  UtilitiesNavigatorView.swift
//  CodeEdit
//
//

import SwiftUI

public struct SubsystemToolItem: Identifiable {
    public let id: String
    public let title: String
    public let icon: String
    public let subtitle: String
    public let action: @MainActor () -> Void

    public init(
        id: String,
        title: String,
        icon: String,
        subtitle: String,
        action: @escaping @MainActor () -> Void
    ) {
        self.id = id
        self.title = title
        self.icon = icon
        self.subtitle = subtitle
        self.action = action
    }
}

// MARK: - Utilities Navigator View (Interactive Subsystem Launchpad)
struct UtilitiesNavigatorView: View {
    @EnvironmentObject var workspace: WorkspaceDocument

    private let subsystems: [SubsystemToolItem] = [
        SubsystemToolItem(
            id: "visual_ui",
            title: "Visual UI Builder",
            icon: "square.grid.2x2",
            subtitle: "Multi-device artboard & canvas"
        ) {
            VisualUIBuilderWindowManager.show()
        },
        SubsystemToolItem(
            id: "database",
            title: "Database Explorer",
            icon: "cylinder.split.1x2.fill",
            subtitle: "SQL studio & table inspector"
        ) {
            DatabaseExplorerWindowManager.show()
        },
        SubsystemToolItem(
            id: "devtools",
            title: "156 Offline DevTools",
            icon: "wrench.and.screwdriver.fill",
            subtitle: "Parsers, converters & utilities"
        ) {
            DevToolsWindowManager.show()
        },
        SubsystemToolItem(
            id: "dictionary",
            title: "Coding Dictionary",
            icon: "character.book.closed.fill",
            subtitle: "Offline Apple & Swift API reference"
        ) {
            CodingDictionaryWindowManager.show()
        },
        SubsystemToolItem(
            id: "wiki",
            title: "Architecture Wiki",
            icon: "book.pages.fill",
            subtitle: "Project documentation & journal"
        ) {
            PersonalDocWindowManager.show()
        },
        SubsystemToolItem(
            id: "telemetry",
            title: "Hardware Telemetry",
            icon: "chart.xyaxis.line",
            subtitle: "CPU, RAM, FPS & Mach-O inspector"
        ) {
            OperationsWindowManager.show()
        },
        SubsystemToolItem(
            id: "storekit",
            title: "StoreKit Testing",
            icon: "cart.fill",
            subtitle: "In-app purchases & renewal simulation"
        ) {
            StoreKitWindowManager.show()
        },
        SubsystemToolItem(
            id: "assist",
            title: "Assist AI Agent",
            icon: "sparkles",
            subtitle: "Autonomous multi-step coding assistant"
        ) {
            AssistAgentWindowManager.show()
        },
        SubsystemToolItem(
            id: "source_control",
            title: "Source Control Repositories",
            icon: "arrow.triangle.branch",
            subtitle: "Git history, branches & commits"
        ) {
            SourceControlWindowManager.show()
        }
    ]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("IDE Subsystems & Tools")
                    .font(.system(size: 12, weight: .semibold))
                Spacer()
            }
            .padding(10)

            Divider()

            List {
                ForEach(subsystems) { item in
                    Button {
                        item.action()
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: item.icon)
                                .font(.system(size: 14))
                                .foregroundColor(.accentColor)
                                .frame(width: 22)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.title)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.primary)
                                Text(item.subtitle)
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "arrow.up.forward.square")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        .contentShape(Rectangle())
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                }
            }
            .listStyle(.sidebar)
        }
    }
}
