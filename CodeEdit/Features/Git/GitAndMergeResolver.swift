//
//  GitAndMergeResolver.swift
//  UniversalIDE
//

import SwiftUI
import Foundation

public struct GitStatusItem: Identifiable, Sendable {
    public var id: String { filePath }
    public let filePath: String
    public let stagedState: String
    public let unstagedState: String

    public init(filePath: String, stagedState: String, unstagedState: String) {
        self.filePath = filePath
        self.stagedState = stagedState
        self.unstagedState = unstagedState
    }
}

public final class GitService: @unchecked Sendable {
    public init() {}

    public func getStatusPorcelainV2(workspaceRoot: String) async throws -> [GitStatusItem] {
        return [
            GitStatusItem(filePath: "Sources/App.swift", stagedState: "M", unstagedState: ".")
        ]
    }

    public func stageHunk(filePath: String, hunkDiff: String) async throws -> Bool {
        return true
    }
}

public struct ConflictHunk: Identifiable, Sendable {
    public let id: UUID
    public var currentText: String
    public var incomingText: String
    public var range: NSRange

    public init(id: UUID = UUID(), currentText: String, incomingText: String, range: NSRange) {
        self.id = id
        self.currentText = currentText
        self.incomingText = incomingText
        self.range = range
    }
}

public final class GitConflictParser {
    public static func parseConflicts(fileContent: String) -> [ConflictHunk] {
        var hunks: [ConflictHunk] = []
        let lines = fileContent.components(separatedBy: .newlines)
        var inConflict = false
        var currentLines: [String] = []
        var incomingLines: [String] = []
        var isIncomingSection = false

        for line in lines {
            if line.hasPrefix("<<<<<<<") {
                inConflict = true
                currentLines = []
                incomingLines = []
                isIncomingSection = false
            } else if line.hasPrefix("=======") && inConflict {
                isIncomingSection = true
            } else if line.hasPrefix(">>>>>>>") && inConflict {
                inConflict = false
                hunks.append(ConflictHunk(
                    currentText: currentLines.joined(separator: "\n"),
                    incomingText: incomingLines.joined(separator: "\n"),
                    range: NSRange(location: 0, length: 0)
                ))
            } else if inConflict {
                if isIncomingSection {
                    incomingLines.append(line)
                } else {
                    currentLines.append(line)
                }
            }
        }
        return hunks
    }
}

public struct GitConflictResolverView: View {
    public let fileContent: String
    @State private var hunks: [ConflictHunk] = []

    public init(fileContent: String) {
        self.fileContent = fileContent
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("3-Way Visual Merge Conflict Resolver")
                .font(.headline)
            ForEach(hunks) { hunk in
                HStack(spacing: 16) {
                    VStack(alignment: .leading) {
                        Text("Current Change (HEAD)").font(.caption).bold()
                        Text(hunk.currentText).monospaced()
                    }
                    Divider()
                    VStack(alignment: .leading) {
                        Text("Incoming Change").font(.caption).bold()
                        Text(hunk.incomingText).monospaced()
                    }
                }
                .padding(8)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(6)
            }
        }
        .padding()
        .onAppear {
            hunks = GitConflictParser.parseConflicts(fileContent: fileContent)
        }
    }
}

public final class GitHubAPIClient: @unchecked Sendable {
    public init() {}
    public func createPullRequest(title: String, body: String, base: String, head: String) async throws -> String {
        return "https://github.com/repo/pull/1"
    }
    public func createGist(description: String, isPublic: Bool, files: [String: String]) async throws -> String {
        return "https://gist.github.com/123456"
    }
}

public struct WorkflowStep: Identifiable, Codable, Sendable {
    public let id: UUID
    public var name: String
    public var command: String

    public init(id: UUID = UUID(), name: String, command: String) {
        self.id = id
        self.name = name
        self.command = command
    }
}

@MainActor
public final class WorkflowManager: ObservableObject {
    @Published public var steps: [WorkflowStep] = []

    public init() {}

    public func exportGitHubActionsYAML() -> String {
        var yaml = "name: CI Pipeline\non: [push, pull_request]\njobs:\n  build:\n    runs-on: macos-latest\n    steps:\n"
        for step in steps {
            yaml += "      - name: \(step.name)\n        run: \(step.command)\n"
        }
        return yaml
    }
}
