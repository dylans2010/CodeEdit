//
//  CodingDictionaryView.swift
//  CodeEdit
//
//

import SwiftUI

/// Searchable Offline Coding Dictionary & API Reference view.
public struct CodingDictionaryView: View {
    @State private var searchQuery: String = ""
    @State private var selectedFramework: String = "All"
    @State private var results: [DictionaryEntry] = []
    @State private var selectedEntryID: String?

    private let frameworks = ["All", "Swift", "SwiftUI", "Foundation", "Combine", "SwiftData"]

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            searchHeader
            Divider()

            HSplitView {
                entriesList
                entryDetailPane
            }
        }
        .task {
            await performSearch()
        }
    }

    private var searchHeader: some View {
        HStack(spacing: 12) {
            Image(systemName: "character.book.closed.fill")
                .foregroundStyle(.brown)
            Text("Offline Coding Dictionary")
                .font(.headline)

            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search Swift & Apple APIs...", text: $searchQuery)
                    .textFieldStyle(.plain)
                    .onChange(of: searchQuery) { _ in
                        Task { await performSearch() }
                    }
            }
            .padding(6)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(8)

            Picker("Framework", selection: $selectedFramework) {
                ForEach(frameworks, id: \.self) { fwName in
                    Text(fwName).tag(fwName)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 130)
            .onChange(of: selectedFramework) { _ in
                Task { await performSearch() }
            }
        }
        .padding(8)
    }

    private var entriesList: some View {
        List(results, selection: $selectedEntryID) { entry in
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(entry.name)
                        .font(.headline)
                    Spacer()
                    Text(entry.framework)
                        .font(.caption2.bold())
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.12))
                        .cornerRadius(4)
                }
                Text(entry.summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            .padding(.vertical, 2)
            .tag(entry.id)
        }
        .frame(minWidth: 240, maxWidth: 320)
    }

    private var entryDetailPane: some View {
        ScrollView {
            if let entryID = selectedEntryID,
               let entry = results.first(where: { $0.id == entryID }) {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(entry.name)
                            .font(.title.weight(.bold))
                        Text(entry.framework)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Declaration")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.secondary)
                        Text(entry.declaration)
                            .font(.system(.body, design: .monospaced))
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(nsColor: .controlBackgroundColor))
                            .cornerRadius(6)
                    }

                    Text(entry.summary)
                        .font(.body)

                    if !entry.examples.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Examples")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.secondary)
                            ForEach(entry.examples, id: \.title) { example in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(example.title)
                                        .font(.caption.weight(.medium))
                                    Text(example.code)
                                        .font(.system(.caption, design: .monospaced))
                                        .padding(8)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color(nsColor: .textBackgroundColor))
                                        .cornerRadius(6)
                                }
                            }
                        }
                    }

                    if !entry.commonMistakes.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Common Mistakes & Fixes")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.red)
                            ForEach(entry.commonMistakes, id: \.description) { mistake in
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("⚠️ \(mistake.description)")
                                        .font(.caption.bold())
                                    Text(mistake.explanation)
                                        .font(.caption)
                                    Text("Fix: \(mistake.fix)")
                                        .font(.caption)
                                        .foregroundStyle(.green)
                                }
                                .padding(8)
                                .background(Color.red.opacity(0.06))
                                .cornerRadius(6)
                            }
                        }
                    }
                }
                .padding()
            } else {
                Text("Select an API from the list to view references and examples.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private func performSearch() async {
        let filter = (selectedFramework == "All") ? nil : selectedFramework
        let searchResults = await CodingDictionaryService.shared.search(query: searchQuery, frameworkFilter: filter)
        self.results = searchResults
        if selectedEntryID == nil {
            self.selectedEntryID = searchResults.first?.id
        }
    }
}
