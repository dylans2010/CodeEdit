//
//  DocumentationManager.swift
//  CodeEdit
//
//

import Foundation

/// Manager coordinating architecture knowledge base, wiki pages, and daily work journal.
@MainActor
public final class DocumentationManager: ObservableObject {
    public static let shared = DocumentationManager()

    @Published public var documents: [ArchitectureDocument] = []
    @Published public var wikiPages: [WikiPage] = []
    @Published public var journalEntries: [JournalEntry] = []

    public init() {
        seedInitialDocuments()
    }

    private func seedInitialDocuments() {
        self.documents = [
            ArchitectureDocument(
                title: "Core Unidirectional Architecture",
                docType: .c4Component,
                content: "Presentation Layer -> Service/Actor Layer -> Core Domain Models"
            ),
            ArchitectureDocument(
                title: "ADR-001: Swift Structured Concurrency",
                docType: .adr,
                content: "Context: Actor isolation for file I/O and process pipelines. Decision: Use async/await and actor isolation."
            ),
            ArchitectureDocument(
                title: "Production App Store Launch Checklist",
                docType: .releaseChecklist,
                content: "- [x] Privacy Manifests\n- [x] App Icon Sets\n- [x] Codesigning & Entitlements\n- [ ] Release Notes"
            )
        ]

        var pageA = WikiPage(title: "Architecture", body: "The architecture is detailed in [[StatePipeline]] and [[StorageEngine]].")
        var pageB = WikiPage(title: "StatePipeline", body: "State flows downwards. Referenced from [[Architecture]].")
        var pageC = WikiPage(title: "StorageEngine", body: "Keychain and persistent storage models. Referenced from [[Architecture]].")

        self.wikiPages = [pageA, pageB, pageC]
        rebuildWikiBacklinks()

        let today = formatDate(Date())
        self.journalEntries = [
            JournalEntry(
                dateString: today,
                completedTasks: ["Verified build systems", "Audited SwiftLint compliance"],
                blockers: [],
                notes: "Autonomous next-generation IDE progress."
            )
        ]
    }

    /// Parses `[[Page Name]]` links in text and extracts referenced page titles.
    public static func parseOutboundWikiLinks(from text: String) -> [String] {
        var links: [String] = []
        let pattern = #"(?<=\[\[)([^\]]+)(?=\]\])"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return []
        }

        let nsString = text as NSString
        let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))

        for match in matches {
            let target = nsString.substring(with: match.range).trimmingCharacters(in: .whitespaces)
            if !target.isEmpty && !links.contains(target) {
                links.append(target)
            }
        }
        return links
    }

    /// Rebuilds the backlinks graph for all wiki pages.
    public func rebuildWikiBacklinks() {
        // Clear existing backlinks
        for index in 0..<wikiPages.count {
            wikiPages[index].outboundLinks = Self.parseOutboundWikiLinks(from: wikiPages[index].body)
            wikiPages[index].backlinks = []
        }

        // Map outbound links to backlinks
        for page in wikiPages {
            for outbound in page.outboundLinks {
                if let targetIdx = wikiPages.firstIndex(where: { $0.title.lowercased() == outbound.lowercased() }) {
                    if !wikiPages[targetIdx].backlinks.contains(page.title) {
                        wikiPages[targetIdx].backlinks.append(page.title)
                    }
                }
            }
        }
    }

    /// Scans source files and generates DocC documentation for undocumented symbols.
    public func analyzeUndocumentedSymbols(fileURL: URL) -> [String] {
        guard let content = try? String(contentsOf: fileURL, encoding: .utf8) else { return [] }
        var generatedDocCs: [String] = []

        let lines = content.components(separatedBy: "\n")
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if (trimmed.hasPrefix("public func") || trimmed.hasPrefix("public struct") || trimmed.hasPrefix("public class"))
                && !trimmed.hasPrefix("///") {
                generatedDocCs.append("/// Documentation synthesized for: \(trimmed)")
            }
        }
        return generatedDocCs
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
