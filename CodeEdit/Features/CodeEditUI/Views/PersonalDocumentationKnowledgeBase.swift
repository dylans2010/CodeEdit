//
//  PersonalDocumentationKnowledgeBase.swift
//  UniversalIDE
//

import SwiftUI
import Foundation

public struct C4ArchitectureModel: Identifiable, Codable, Sendable {
    public let id: UUID
    public var name: String
    public var layer: String // Context, Container, Component, Code
    public var description: String

    public init(id: UUID = UUID(), name: String, layer: String, description: String) {
        self.id = id
        self.name = name
        self.layer = layer
        self.description = description
    }
}

public struct ArchitectureDecisionRecord: Identifiable, Codable, Sendable {
    public let id: UUID
    public var title: String
    public var status: String // Proposed, Accepted, Rejected, Deprecated
    public var context: String
    public var decision: String
    public var consequences: String

    public init(id: UUID = UUID(), title: String, status: String, context: String, decision: String, consequences: String) {
        self.id = id
        self.title = title
        self.status = status
        self.context = context
        self.decision = decision
        self.consequences = consequences
    }
}

public struct JournalEntry: Identifiable, Codable, Sendable {
    public let id: UUID
    public let date: Date
    public var tasksCompleted: [String]
    public var blockers: [String]
    public var commitHashes: [String]

    public init(id: UUID = UUID(), date: Date = Date(), tasksCompleted: [String] = [], blockers: [String] = [], commitHashes: [String] = []) {
        self.id = id
        self.date = date
        self.tasksCompleted = tasksCompleted
        self.blockers = blockers
        self.commitHashes = commitHashes
    }
}

public final class WikiPageResolver {
    public static func parseWikiLinks(markdown: String) -> [String] {
        var links: [String] = []
        let pattern = #"\b\[\[(.*?)\]\]"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let ns = markdown as NSString
        let matches = regex.matches(in: markdown, range: NSRange(location: 0, length: ns.length))
        for m in matches {
            let target = ns.substring(with: m.range(at: 1))
            links.append(target)
        }
        return links
    }
}

public final class DocCAnalyzer: @unchecked Sendable {
    public init() {}

    public func generateDocCForUndocumentedAPIs(sourceCode: String) -> String {
        return "/// DocC auto-generated documentation for exported symbols"
    }
}

public struct PersonalDocView: View {
    @State private var adrs: [ArchitectureDecisionRecord] = [
        ArchitectureDecisionRecord(title: "ADR 001: Standardize on MLX for Local Inference", status: "Accepted", context: "Need local Apple Silicon runner.", decision: "Use MLX framework.", consequences: "Zero external server latency.")
    ]

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Architecture Knowledge Base & ADRs").font(.headline)
            List(adrs) { adr in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(adr.title).bold()
                        Spacer()
                        Text(adr.status).font(.caption).padding(4).background(Color.blue.opacity(0.2)).cornerRadius(4)
                    }
                    Text(adr.context).font(.caption)
                }
            }
        }
        .padding()
    }
}
