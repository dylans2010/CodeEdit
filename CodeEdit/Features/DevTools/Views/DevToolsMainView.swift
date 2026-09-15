//
//  DevToolsMainView.swift
//  CodeEdit
//
//

import SwiftUI

/// Searchable dashboard and launcher for all 156 built-in developer tools.
public struct DevToolsMainView: View {
    @State private var searchQuery: String = ""
    @State private var selectedCategory: DevToolCategory?
    @State private var selectedTool: DevToolItem?

    public init(initialToolID: String? = nil) {
        if let initialID = initialToolID,
           let match = DevToolsCatalog.allTools.first(where: { $0.id == initialID }) {
            _selectedTool = State(initialValue: match)
        }
    }

    public var body: some View {
        NavigationSplitView {
            sidebarContent
        } detail: {
            detailContent
        }
        .frame(minWidth: 850, minHeight: 550)
    }

    // MARK: - Sidebar
    private var sidebarContent: some View {
        List(selection: $selectedCategory) {
            Section("Categories") {
                NavigationLink(value: Optional<DevToolCategory>.none) {
                    Label("All Tools (\(DevToolsCatalog.allTools.count))", systemImage: "square.grid.2x2")
                }

                ForEach(DevToolCategory.allCases, id: \.self) { categoryItem in
                    NavigationLink(value: Optional(categoryItem)) {
                        let count = DevToolsCatalog.allTools.filter { $0.category == categoryItem }.count
                        HStack {
                            Text(categoryItem.rawValue)
                            Spacer()
                            Text("\(count)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Dev Tools")
    }

    // MARK: - Detail Content
    private var detailContent: some View {
        VStack(spacing: 0) {
            searchBarHeader
            Divider()

            if let activeTool = selectedTool {
                VStack(spacing: 0) {
                    backToolbar
                    Divider()
                    DevToolsHostView(toolItem: activeTool)
                }
            } else {
                toolsGridCatalog
            }
        }
    }

    private var searchBarHeader: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            TextField("Search 156 developer tools...", text: $searchQuery)
                .textFieldStyle(.plain)
            if !searchQuery.isEmpty {
                Button {
                    searchQuery = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
        .background(Color(NSColor.controlBackgroundColor))
    }

    private var backToolbar: some View {
        HStack {
            Button {
                selectedTool = nil
            } label: {
                Label("Back to Catalog", systemImage: "chevron.left")
            }
            .buttonStyle(.plain)
            .foregroundColor(.accentColor)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private var toolsGridCatalog: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 220, maximum: 300), spacing: 12)], spacing: 12) {
                ForEach(filteredTools) { toolItem in
                    toolCard(toolItem: toolItem)
                }
            }
            .padding(16)
        }
    }

    private func toolCard(toolItem: DevToolItem) -> some View {
        Button {
            selectedTool = toolItem
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: toolItem.iconName)
                        .font(.system(size: 18))
                        .foregroundColor(.accentColor)
                    Spacer()
                    Text(toolItem.category.rawValue)
                        .font(.system(size: 9))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.15))
                        .cornerRadius(4)
                }

                Text(toolItem.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Text(toolItem.summary)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Filtering
    private var filteredTools: [DevToolItem] {
        DevToolsCatalog.allTools.filter { toolItem in
            let matchesCategory = selectedCategory == nil || toolItem.category == selectedCategory
            let matchesSearch = searchQuery.isEmpty ||
                toolItem.title.localizedCaseInsensitiveContains(searchQuery) ||
                toolItem.summary.localizedCaseInsensitiveContains(searchQuery) ||
                toolItem.id.localizedCaseInsensitiveContains(searchQuery)
            return matchesCategory && matchesSearch
        }
    }
}
