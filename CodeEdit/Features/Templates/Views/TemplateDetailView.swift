//
//  TemplateDetailView.swift
//  CodeEdit
//
//  Created by CodeEdit on 2024/09/14.
//

import SwiftUI

struct TemplateDetailView: View {
    let template: ProjectTemplate
    @Binding var projectName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            descriptionView
            Divider()
            nameField
            filesList
            Spacer()
        }
        .padding(16)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.2))
    }

    private var header: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.accentColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: template.icon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(.accentColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(template.name)
                    .font(.system(size: 13, weight: .bold))
                    .lineLimit(2)
                Text(template.language)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
        }
    }

    private var descriptionView: some View {
        Text(template.description)
            .font(.system(size: 11))
            .foregroundColor(.secondary)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var nameField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Project Name")
                .font(.system(size: 11, weight: .semibold))

            TextField("Project Name", text: $projectName)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 12))
        }
    }

    private var filesList: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Included Files (\(template.fileList.count))")
                .font(.system(size: 11, weight: .semibold))

            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(template.fileList, id: \.self) { file in
                        fileRow(for: file)
                    }
                }
            }
            .frame(maxHeight: 180)
            .padding(6)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(6)
        }
    }

    private func fileRow(for file: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: iconForFile(file))
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .frame(width: 14)
            Text(file)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.primary)
                .lineLimit(1)
            Spacer()
        }
        .padding(.vertical, 2)
    }

    private func iconForFile(_ path: String) -> String {
        let ext = (path as NSString).pathExtension.lowercased()
        let iconMap: [String: String] = [
            "swift": "swift",
            "ts": "chevron.left.forwardslash.chevron.right",
            "tsx": "chevron.left.forwardslash.chevron.right",
            "js": "chevron.left.forwardslash.chevron.right",
            "jsx": "chevron.left.forwardslash.chevron.right",
            "py": "chevron.right",
            "c": "c.square",
            "cpp": "plusplus",
            "rs": "gearshape",
            "go": "network",
            "json": "doc.badge.gearshape",
            "html": "globe",
            "css": "paintpalette",
            "sh": "terminal",
            "md": "doc.plaintext"
        ]
        return iconMap[ext] ?? "doc"
    }
}
