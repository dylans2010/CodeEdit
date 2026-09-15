//
//  WindowManagementService.swift
//  CodeEdit
//
//

import AppKit
import SwiftUI

/// Unified window lifecycle manager for IDE auxiliary workspaces and studio views.
@MainActor
public final class WindowManagementService {
    /// Shared singleton instance of WindowManagementService.
    public static let shared = WindowManagementService()

    private var openWindows: [String: NSWindowController] = [:]

    private init() {}

    /// Shows or brings to front an NSWindow hosting SwiftUI content.
    public static func showWindow<Content: View>(
        identifier: String,
        title: String,
        width: CGFloat = 960,
        height: CGFloat = 640,
        minWidth: CGFloat = 600,
        minHeight: CGFloat = 400,
        view: Content
    ) {
        if let existing = shared.openWindows[identifier], let window = existing.window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let rect = NSRect(x: 0, y: 0, width: width, height: height)
        let window = NSWindow(
            contentRect: rect,
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = title
        window.minSize = NSSize(width: minWidth, height: minHeight)
        window.center()
        window.contentView = NSHostingView(rootView: view)

        let controller = NSWindowController(window: window)
        shared.openWindows[identifier] = controller
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

// MARK: - Specialized Window Managers

/// Window manager for presenting the Visual UI Builder.
@MainActor
public enum VisualUIBuilderWindowManager {
    /// Opens the Visual UI Builder and artboard window.
    public static func show() {
        WindowManagementService.showWindow(
            identifier: "VisualUIBuilder",
            title: "Visual UI Builder & Artboard",
            width: 1100,
            height: 720,
            view: VisualUIBuilderView()
        )
    }
}

/// Window manager for presenting the Database Explorer.
@MainActor
public enum DatabaseExplorerWindowManager {
    /// Opens the Database Explorer and SQL Studio window.
    public static func show(databaseURL: URL? = nil) {
        WindowManagementService.showWindow(
            identifier: "DatabaseExplorer",
            title: "Database Explorer & SQL Studio",
            width: 1050,
            height: 700,
            view: DatabaseStudioView(databaseURL: databaseURL)
        )
    }
}

/// Window manager for presenting the Personal Documentation Wiki.
@MainActor
public enum PersonalDocWindowManager {
    /// Opens the Architecture Wiki & Knowledge Base window.
    public static func show() {
        WindowManagementService.showWindow(
            identifier: "PersonalDocumentation",
            title: "Architecture Wiki & Knowledge Base",
            width: 1000,
            height: 700,
            view: PersonalDocumentationView()
        )
    }
}

/// Window manager for presenting Operations & Hardware Telemetry.
@MainActor
public enum OperationsWindowManager {
    /// Opens the DevOps & Hardware Telemetry window.
    public static func show() {
        WindowManagementService.showWindow(
            identifier: "OperationsTelemetry",
            title: "DevOps & Hardware Telemetry",
            width: 1050,
            height: 700,
            view: OperationsTelemetryView()
        )
    }
}

/// Window manager for presenting Source Control Repositories.
@MainActor
public enum SourceControlWindowManager {
    /// Opens the Source Control repository management window.
    public static func show() {
        WindowManagementService.showWindow(
            identifier: "SourceControlManager",
            title: "Source Control & Repositories",
            width: 950,
            height: 650,
            view: SourceControlWindowHostView()
        )
    }
}

/// Window manager for presenting Project Architecture Notes.
@MainActor
public enum ProjectNotesWindowManager {
    /// Opens the Project Architecture Notes window.
    public static func show() {
        WindowManagementService.showWindow(
            identifier: "ProjectNotes",
            title: "Project Architecture Notes",
            width: 950,
            height: 650,
            view: PersonalDocumentationView()
        )
    }
}

/// Window manager for presenting Offline Developer Tools.
@MainActor
public enum DevToolsWindowManager {
    /// Opens the Developer Tools suite with 156 offline utilities.
    public static func show(initialToolID: String? = nil) {
        WindowManagementService.showWindow(
            identifier: "DevToolsCatalog",
            title: "Developer Tools (156 Offline Utilities)",
            width: 1150,
            height: 750,
            view: DevToolsMainView(initialToolID: initialToolID)
        )
    }
}

/// Window manager for presenting the Offline Coding Dictionary.
@MainActor
public enum CodingDictionaryWindowManager {
    /// Opens the Offline Coding Dictionary window.
    public static func show() {
        WindowManagementService.showWindow(
            identifier: "CodingDictionary",
            title: "Offline Coding Dictionary",
            width: 980,
            height: 680,
            view: CodingDictionaryView()
        )
    }
}

/// Window manager for presenting the Assist Autonomous Coding Agent.
@MainActor
public enum AssistAgentWindowManager {
    /// Opens the Assist Autonomous Coding Agent window.
    public static func show() {
        WindowManagementService.showWindow(
            identifier: "AssistAgent",
            title: "Autonomous Coding Agent (Assist)",
            width: 1050,
            height: 720,
            view: AssistAgentView()
        )
    }
}

/// Window manager for presenting the StoreKit workspace window.
@MainActor
public enum StoreKitWindowManager {
    /// Opens the StoreKit testing and simulation window.
    public static func show(fileURL: URL? = nil) {
        WindowManagementService.showWindow(
            identifier: "StoreKitWorkspace",
            title: "StoreKit Transaction Testing & Simulation",
            width: 1050,
            height: 700,
            view: StoreKitWorkspaceView()
        )
    }
}

/// Window manager for presenting the Git conflict resolution window.
@MainActor
public enum GitConflictResolverWindowManager {
    /// Opens the interactive 3-way Git conflict resolution window for the specified file.
    public static func show(fileURL: URL) {
        WindowManagementService.showWindow(
            identifier: "GitConflictResolver-\(fileURL.path)",
            title: "Resolve Conflicts - \(fileURL.lastPathComponent)",
            width: 1100,
            height: 720,
            view: GitConflictResolverView(fileURL: fileURL)
        )
    }
}

// MARK: - Source Control Window Host

/// Standalone source control viewer host.
public struct SourceControlWindowHostView: View {
    @State private var workspaceDoc = CodeEditDocumentController.shared.documents
        .compactMap { $0 as? WorkspaceDocument }.first

    /// Initializes a new SourceControlWindowHostView.
    public init() {}

    public var body: some View {
        if let doc = workspaceDoc {
            SourceControlNavigatorView()
                .environmentObject(doc)
        } else {
            VStack(spacing: 12) {
                Image(systemName: "arrow.triangle.branch")
                    .font(.system(size: 40))
                    .foregroundStyle(.secondary)
                Text("No Workspace Open")
                    .font(.headline)
                Text("Open a Git repository or workspace to inspect commits and branch status.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
