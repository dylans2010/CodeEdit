//
//  DocumentCoordinator.swift
//  UniversalIDE
//
//  Created for Next-Generation Code Editor
//

import Foundation
import Combine

public enum LineEndingStyle: String, Codable, Sendable {
    case lf = "\n"
    case crlf = "\r\n"
}

public struct CursorPosition: Codable, Sendable, Equatable {
    public var line: Int
    public var column: Int

    public init(line: Int = 1, column: Int = 1) {
        self.line = line
        self.column = column
    }
}

public struct TextSelection: Codable, Sendable, Equatable {
    public var start: CursorPosition
    public var end: CursorPosition

    public init(start: CursorPosition, end: CursorPosition) {
        self.start = start
        self.end = end
    }
}

public struct SourceFileDocument: Identifiable, Sendable, Equatable {
    public let id: UUID
    public let fileURL: URL
    public var content: String
    public var isDirty: Bool
    public var encodingName: String
    public var lineEndings: LineEndingStyle
    public var cursorPosition: CursorPosition
    public var selections: [TextSelection]

    public init(
        id: UUID = UUID(),
        fileURL: URL,
        content: String = "",
        isDirty: Bool = false,
        encodingName: String = "utf-8",
        lineEndings: LineEndingStyle = .lf,
        cursorPosition: CursorPosition = CursorPosition(),
        selections: [TextSelection] = []
    ) {
        self.id = id
        self.fileURL = fileURL
        self.content = content
        self.isDirty = isDirty
        self.encodingName = encodingName
        self.lineEndings = lineEndings
        self.cursorPosition = cursorPosition
        self.selections = selections
    }
}

public enum SplitPaneAxis: String, Codable, Sendable {
    case horizontal
    case vertical
}

public struct EditorSplitPane: Identifiable, Sendable {
    public let id: UUID
    public var activeDocumentID: UUID?
    public var documentIDs: [UUID]
    public var pinnedDocumentIDs: [UUID]

    public init(
        id: UUID = UUID(),
        activeDocumentID: UUID? = nil,
        documentIDs: [UUID] = [],
        pinnedDocumentIDs: [UUID] = []
    ) {
        self.id = id
        self.activeDocumentID = activeDocumentID
        self.documentIDs = documentIDs
        self.pinnedDocumentIDs = pinnedDocumentIDs
    }
}

@MainActor
public final class DocumentCoordinator: ObservableObject {
    public static let shared = DocumentCoordinator()

    @Published public private(set) var openDocuments: [UUID: SourceFileDocument] = [:]
    @Published public var activePaneID: UUID
    @Published public var splitPanes: [EditorSplitPane] = []
    @Published public var undoStacks: [UUID: [String]] = [:]
    @Published public var redoStacks: [UUID: [String]] = [:]

    public init() {
        let defaultPane = EditorSplitPane()
        self.activePaneID = defaultPane.id
        self.splitPanes = [defaultPane]
    }

    public func openDocument(at url: URL) throws -> SourceFileDocument {
        if let existing = openDocuments.values.first(where: { $0.fileURL == url }) {
            activateDocument(existing.id)
            return existing
        }

        let content = (try? String(contentsOf: url, encoding: .utf8)) ?? ""
        let doc = SourceFileDocument(fileURL: url, content: content)
        openDocuments[doc.id] = doc
        undoStacks[doc.id] = [content]
        redoStacks[doc.id] = []

        if let index = splitPanes.firstIndex(where: { $0.id == activePaneID }) {
            splitPanes[index].documentIDs.append(doc.id)
            splitPanes[index].activeDocumentID = doc.id
        }

        return doc
    }

    public func activateDocument(_ id: UUID) {
        guard openDocuments[id] != nil else { return }
        if let index = splitPanes.firstIndex(where: { $0.id == activePaneID }) {
            splitPanes[index].activeDocumentID = id
        }
    }

    public func closeDocument(_ id: UUID) {
        openDocuments.removeValue(forKey: id)
        undoStacks.removeValue(forKey: id)
        redoStacks.removeValue(forKey: id)

        for idx in splitPanes.indices {
            splitPanes[idx].documentIDs.removeAll(where: { $0 == id })
            splitPanes[idx].pinnedDocumentIDs.removeAll(where: { $0 == id })
            if splitPanes[idx].activeDocumentID == id {
                splitPanes[idx].activeDocumentID = splitPanes[idx].documentIDs.last
            }
        }
    }

    public func updateContent(_ id: UUID, newContent: String) {
        guard var doc = openDocuments[id] else { return }
        if doc.content != newContent {
            if var stack = undoStacks[id] {
                stack.append(doc.content)
                undoStacks[id] = stack
            }
            redoStacks[id] = []
            doc.content = newContent
            doc.isDirty = true
            openDocuments[id] = doc
        }
    }

    public func togglePin(_ id: UUID) {
        for idx in splitPanes.indices {
            if splitPanes[idx].pinnedDocumentIDs.contains(id) {
                splitPanes[idx].pinnedDocumentIDs.removeAll(where: { $0 == id })
            } else if splitPanes[idx].documentIDs.contains(id) {
                splitPanes[idx].pinnedDocumentIDs.append(id)
            }
        }
    }

    public func saveDocument(_ id: UUID) throws {
        guard var doc = openDocuments[id] else { return }
        try doc.content.write(to: doc.fileURL, atomically: true, encoding: .utf8)
        doc.isDirty = false
        openDocuments[id] = doc
    }
}
