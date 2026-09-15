//
//  DocumentCoordinator.swift
//  CodeEdit
//

import Foundation
import SwiftUI
import Combine

public enum LineEndingStyle: String, Codable, Sendable {
    case lf = "\n"
    case crlf = "\r\n"
}

public struct CursorPosition: Codable, Equatable, Sendable {
    public var line: Int
    public var column: Int

    public init(line: Int = 1, column: Int = 1) {
        self.line = line
        self.column = column
    }
}

public struct TextSelection: Codable, Equatable, Sendable {
    public var start: CursorPosition
    public var end: CursorPosition

    public init(start: CursorPosition, end: CursorPosition) {
        self.start = start
        self.end = end
    }
}

public struct SourceFileDocument: Identifiable, Sendable {
    public let id: UUID
    public let fileURL: URL
    public var content: String
    public var isDirty: Bool
    public var encoding: String.Encoding
    public var lineEndings: LineEndingStyle
    public var cursorPosition: CursorPosition
    public var selections: [TextSelection]
    public var isPinned: Bool

    public init(
        id: UUID = UUID(),
        fileURL: URL,
        content: String = "",
        isDirty: Bool = false,
        encoding: String.Encoding = .utf8,
        lineEndings: LineEndingStyle = .lf,
        cursorPosition: CursorPosition = CursorPosition(),
        selections: [TextSelection] = [],
        isPinned: Bool = false
    ) {
        self.id = id
        self.fileURL = fileURL
        self.content = content
        self.isDirty = isDirty
        self.encoding = encoding
        self.lineEndings = lineEndings
        self.cursorPosition = cursorPosition
        self.selections = selections
        self.isPinned = isPinned
    }
}

public enum SplitOrientation: String, Codable, Sendable {
    case horizontal
    case vertical
}

@MainActor
public final class DocumentCoordinator: ObservableObject {
    public static let shared = DocumentCoordinator()

    @Published public private(set) var openDocuments: [SourceFileDocument] = []
    @Published public var activeDocumentID: UUID?
    @Published public var splitOrientation: SplitOrientation = .horizontal
    @Published public var isSplitActive: Bool = false
    @Published public var secondaryActiveDocumentID: UUID?

    private var undoStacks: [UUID: [String]] = [:]
    private var redoStacks: [UUID: [String]] = [:]

    private init() {}

    public var activeDocument: SourceFileDocument? {
        guard let id = activeDocumentID else { return nil }
        return openDocuments.first(where: { $0.id == id })
    }

    // MARK: - Document Lifecycle

    public func openDocument(at url: URL) throws -> SourceFileDocument {
        // Check if already open
        if let existing = openDocuments.first(where: { $0.fileURL == url }) {
            activeDocumentID = existing.id
            return existing
        }

        let content = try String(contentsOf: url, encoding: .utf8)
        let doc = SourceFileDocument(
            fileURL: url,
            content: content,
            isDirty: false,
            lineEndings: content.contains("\r\n") ? .crlf : .lf
        )
        openDocuments.append(doc)
        activeDocumentID = doc.id
        undoStacks[doc.id] = [content]
        redoStacks[doc.id] = []
        return doc
    }

    public func closeDocument(id: UUID) {
        guard let index = openDocuments.firstIndex(where: { $0.id == id }) else { return }
        openDocuments.remove(at: index)
        undoStacks.removeValue(forKey: id)
        redoStacks.removeValue(forKey: id)

        if activeDocumentID == id {
            activeDocumentID = openDocuments.last?.id
        }
        if secondaryActiveDocumentID == id {
            secondaryActiveDocumentID = nil
        }
    }

    public func closeCurrentDocument() {
        if let id = activeDocumentID {
            closeDocument(id: id)
        }
    }

    public func saveCurrentFile() throws {
        guard let id = activeDocumentID,
              let index = openDocuments.firstIndex(where: { $0.id == id }) else { return }

        let doc = openDocuments[index]
        try doc.content.write(to: doc.fileURL, atomically: true, encoding: doc.encoding)
        openDocuments[index].isDirty = false
    }

    public func saveAll() throws {
        for index in openDocuments.indices where openDocuments[index].isDirty {
            let doc = openDocuments[index]
            try doc.content.write(to: doc.fileURL, atomically: true, encoding: doc.encoding)
            openDocuments[index].isDirty = false
        }
    }

    // MARK: - Content & Edit State

    public func updateContent(for id: UUID, newContent: String) {
        guard let index = openDocuments.firstIndex(where: { $0.id == id }) else { return }
        let currentContent = openDocuments[index].content
        guard currentContent != newContent else { return }

        // Push to undo stack
        undoStacks[id, default: []].append(currentContent)
        redoStacks[id] = []

        openDocuments[index].content = newContent
        openDocuments[index].isDirty = true
    }

    public func undo(for id: UUID) {
        guard var history = undoStacks[id], history.count > 1,
              let index = openDocuments.firstIndex(where: { $0.id == id }) else { return }

        let currentState = openDocuments[index].content
        let previousState = history.removeLast()
        undoStacks[id] = history
        redoStacks[id, default: []].append(currentState)

        openDocuments[index].content = previousState
        openDocuments[index].isDirty = true
    }

    public func redo(for id: UUID) {
        guard var future = redoStacks[id], !future.isEmpty,
              let index = openDocuments.firstIndex(where: { $0.id == id }) else { return }

        let nextState = future.removeLast()
        redoStacks[id] = future
        undoStacks[id, default: []].append(openDocuments[index].content)

        openDocuments[index].content = nextState
        openDocuments[index].isDirty = true
    }

    public func togglePin(id: UUID) {
        guard let index = openDocuments.firstIndex(where: { $0.id == id }) else { return }
        openDocuments[index].isPinned.toggle()
    }
}
