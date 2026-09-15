//
//  PersonalDocumentationView.swift
//  CodeEdit
//
//

import SwiftUI

/// Workspace view managing architecture documents, internal wiki, and developer journals.
public struct PersonalDocumentationView: View {
    @ObservedObject private var manager = DocumentationManager.shared
    @State private var selectedTab: Int = 0
    @State private var selectedDocID: UUID?
    @State private var selectedWikiTitle: String?

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            topTabBar
            Divider()

            switch selectedTab {
            case 0: architectureWorkspace
            case 1: wikiWorkspace
            case 2: journalWorkspace
            default: EmptyView()
            }
        }
    }

    private var topTabBar: some View {
        HStack(spacing: 16) {
            Image(systemName: "book.pages.fill")
                .foregroundStyle(.teal)
            Text("Architecture Knowledge Base & Journal")
                .font(.headline)

            Spacer()

            Picker("Section", selection: $selectedTab) {
                Text("Architecture & ADRs").tag(0)
                Text("Internal Wiki [[]]").tag(1)
                Text("Work Journal").tag(2)
            }
            .pickerStyle(.segmented)
            .frame(width: 380)
        }
        .padding(8)
    }

    // MARK: - Architecture & Planning Workspace

    private var architectureWorkspace: some View {
        HSplitView {
            List(manager.documents, selection: $selectedDocID) { doc in
                VStack(alignment: .leading, spacing: 2) {
                    Text(doc.title)
                        .font(.body)
                    Text(doc.docType.rawValue)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .tag(doc.id)
            }
            .frame(minWidth: 200, maxWidth: 280)

            if let docID = selectedDocID,
               let index = manager.documents.firstIndex(where: { $0.id == docID }) {
                VStack(alignment: .leading, spacing: 12) {
                    TextField("Document Title", text: $manager.documents[index].title)
                        .font(.title2.weight(.bold))
                        .textFieldStyle(.plain)

                    Text("Document Type: \(manager.documents[index].docType.rawValue)")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Divider()

                    TextEditor(text: $manager.documents[index].content)
                        .font(.system(.body, design: .monospaced))
                }
                .padding()
            } else {
                Text("Select an architecture document or create a new ADR.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    // MARK: - Internal Wiki Workspace

    private var wikiWorkspace: some View {
        HSplitView {
            List(manager.wikiPages, selection: $selectedWikiTitle) { page in
                HStack {
                    Image(systemName: "doc.text")
                        .foregroundStyle(.secondary)
                    Text(page.title)
                        .font(.body)
                }
                .tag(page.title)
            }
            .frame(minWidth: 180, maxWidth: 240)

            if let title = selectedWikiTitle,
               let index = manager.wikiPages.firstIndex(where: { $0.title == title }) {
                VStack(alignment: .leading, spacing: 12) {
                    Text(manager.wikiPages[index].title)
                        .font(.title2.weight(.bold))

                    TextEditor(text: $manager.wikiPages[index].body)
                        .font(.body)
                        .onChange(of: manager.wikiPages[index].body) { _ in
                            manager.rebuildWikiBacklinks()
                        }

                    Divider()

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Backlinks (\(manager.wikiPages[index].backlinks.count))")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.secondary)

                        ForEach(manager.wikiPages[index].backlinks, id: \.self) { backlink in
                            Button("[[\(backlink)]]") {
                                self.selectedWikiTitle = backlink
                            }
                            .buttonStyle(.plain)
                            .font(.caption)
                            .foregroundStyle(.blue)
                        }
                    }
                }
                .padding()
            } else {
                Text("Select a wiki page to view content and backlinks.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    // MARK: - Work Journal Workspace

    private var journalWorkspace: some View {
        List(manager.journalEntries) { entry in
            VStack(alignment: .leading, spacing: 8) {
                Text(entry.dateString)
                    .font(.headline)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Tasks Completed:")
                        .font(.caption.weight(.bold))
                    ForEach(entry.completedTasks, id: \.self) { task in
                        Text("• \(task)")
                            .font(.caption)
                    }
                }
                Text("Notes: \(entry.notes)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 6)
        }
    }
}
