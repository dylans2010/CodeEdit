//
//  DocumentationModels.swift
//  CodeEdit
//
//

import Foundation

/// Type of personal architecture and planning document.
public enum ArchitectureDocType: String, Codable, CaseIterable, Sendable {
    case c4Context = "C4 Context"
    case c4Container = "C4 Container"
    case c4Component = "C4 Component"
    case adr = "Architecture Decision Record (ADR)"
    case featurePlan = "Feature Planning & User Story"
    case releaseChecklist = "Release & Compliance Checklist"
    case apiDoc = "OpenAPI Documentation"
}

/// An architecture or planning document.
public struct ArchitectureDocument: Identifiable, Codable, Sendable {
    public let id: UUID
    public var title: String
    public var docType: ArchitectureDocType
    public var content: String
    public var lastModified: Date

    public init(
        title: String,
        docType: ArchitectureDocType,
        content: String = ""
    ) {
        self.id = UUID()
        self.title = title
        self.docType = docType
        self.content = content
        self.lastModified = Date()
    }
}

/// A wiki page with bidirectional link metadata.
public struct WikiPage: Identifiable, Codable, Sendable {
    public var id: String { title }
    public var title: String
    public var body: String
    public var outboundLinks: [String]
    public var backlinks: [String]
    public var lastModified: Date

    public init(
        title: String,
        body: String = "",
        outboundLinks: [String] = [],
        backlinks: [String] = []
    ) {
        self.title = title
        self.body = body
        self.outboundLinks = outboundLinks
        self.backlinks = backlinks
        self.lastModified = Date()
    }
}

/// A daily developer journal entry.
public struct JournalEntry: Identifiable, Codable, Sendable {
    public var id: String { dateString }
    public let dateString: String // "yyyy-MM-dd"
    public var completedTasks: [String]
    public var blockers: [String]
    public var notes: String

    public init(
        dateString: String,
        completedTasks: [String] = [],
        blockers: [String] = [],
        notes: String = ""
    ) {
        self.dateString = dateString
        self.completedTasks = completedTasks
        self.blockers = blockers
        self.notes = notes
    }
}
