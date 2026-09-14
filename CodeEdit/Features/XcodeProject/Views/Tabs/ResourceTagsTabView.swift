//
//  ResourceTagsTabView.swift
//  CodeEdit
//
//  Created by Austin Condiff on 14/09/26.
//

import SwiftUI

struct ResourceTagItem: Identifiable {
    var id: String
    var name: String
    var type: String
    var fileCount: Int
    var estimatedSize: String
}

struct ResourceTagsTabView: View {
    @ObservedObject var manager: XcodeProjectManager
    @State private var searchText = ""
    @State private var tags: [ResourceTagItem] = [
        ResourceTagItem(id: "1", name: "InitialResources", type: "Initial Install", fileCount: 4, estimatedSize: "1.2 MB"),
        ResourceTagItem(id: "2", name: "TutorialMedia", type: "Prefetched", fileCount: 8, estimatedSize: "5.4 MB"),
        ResourceTagItem(id: "3", name: "LevelData", type: "On Demand", fileCount: 12, estimatedSize: "14.8 MB")
    ]

    var filteredTags: [ResourceTagItem] {
        if searchText.isEmpty {
            return tags
        }
        return tags.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        VStack(spacing: 0) {
            toolbarView
            Divider()
            tagsTableView
        }
    }

    private var toolbarView: some View {
        HStack(spacing: 12) {
            Image(systemName: "tag.fill")
                .foregroundColor(.accentColor)
            Text("On-Demand Resources & Tags")
                .font(.headline)

            Spacer()

            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Filter tags...", text: $searchText)
                    .textFieldStyle(.plain)
                    .frame(width: 160)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(6)

            Button {
                let newTag = ResourceTagItem(
                    id: UUID().uuidString,
                    name: "NewTag",
                    type: "On Demand",
                    fileCount: 0,
                    estimatedSize: "0 KB"
                )
                tags.append(newTag)
            } label: {
                Image(systemName: "plus")
            }
            .buttonStyle(.bordered)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var tagsTableView: some View {
        VStack(spacing: 0) {
            tableHeader
            Divider()

            if filteredTags.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "tag.slash")
                        .font(.system(size: 28))
                        .foregroundColor(.secondary)
                    Text("No Resource Tags Found")
                        .font(.callout)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(40)
            } else {
                List(filteredTags) { tag in
                    HStack {
                        Image(systemName: "tag")
                            .foregroundColor(.accentColor)
                        Text(tag.name)
                            .font(.system(size: 13, weight: .medium))
                        Spacer()
                        Text(tag.type)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color(nsColor: .quaternaryLabelColor))
                            .cornerRadius(4)
                        Text("\(tag.fileCount) files")
                            .font(.system(size: 12))
                            .frame(width: 60, alignment: .trailing)
                        Text(tag.estimatedSize)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .frame(width: 70, alignment: .trailing)
                    }
                    .padding(.vertical, 4)
                }
                .listStyle(.plain)
            }
        }
    }

    private var tableHeader: some View {
        HStack {
            Text("Tag Name")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
            Spacer()
            Text("Download Type")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
                .frame(width: 120, alignment: .leading)
            Text("Files")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
                .frame(width: 60, alignment: .trailing)
            Text("Size")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
                .frame(width: 70, alignment: .trailing)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 6)
        .background(Color(nsColor: .controlBackgroundColor))
    }
}
