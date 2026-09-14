//
//  BuildPhasesTabView.swift
//  CodeEdit
//
//  Created by Austin Condiff on 14/09/26.
//

import SwiftUI

struct BuildPhasesTabView: View {
    @ObservedObject var manager: XcodeProjectManager

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                if let target = manager.selectedTarget {
                    dependenciesDisclosure(target: target)

                    ForEach(target.buildPhases) { phase in
                        phaseDisclosure(phase: phase)
                    }
                } else {
                    Text("Select a target from the sidebar to inspect build phases.")
                        .foregroundColor(.secondary)
                        .padding(24)
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func dependenciesDisclosure(target: PBXTargetModel) -> some View {
        DisclosureGroup {
            VStack(alignment: .leading, spacing: 0) {
                if target.dependencies.isEmpty {
                    Text("No target dependencies")
                        .font(.callout)
                        .foregroundColor(.secondary)
                        .padding(12)
                } else {
                    ForEach(target.dependencies, id: \.self) { dep in
                        HStack(spacing: 8) {
                            Image(systemName: "cube.fill")
                                .foregroundColor(.accentColor)
                            Text(dep)
                                .font(.system(size: 13))
                            Spacer()
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        Divider()
                    }
                }
            }
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(6)
        } label: {
            phaseHeader(title: "Dependencies", count: target.dependencies.count, icon: "arrow.triangle.merge")
        }
        .padding(12)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
    }

    private func phaseDisclosure(phase: PBXBuildPhaseModel) -> some View {
        DisclosureGroup {
            VStack(alignment: .leading, spacing: 0) {
                if phase.type == .runScript {
                    runScriptDetail(phase: phase)
                } else {
                    filesList(files: phase.files)
                }
            }
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(6)
        } label: {
            phaseHeader(
                title: phase.name,
                count: phase.type == .runScript ? nil : phase.files.count,
                icon: phase.type.icon
            )
        }
        .padding(12)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
    }

    private func filesList(files: [PBXBuildFileModel]) -> some View {
        VStack(spacing: 0) {
            if files.isEmpty {
                Text("No files in this build phase")
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .padding(12)
            } else {
                ForEach(files) { file in
                    HStack(spacing: 8) {
                        Image(systemName: "doc.text")
                            .foregroundColor(.secondary)
                        Text(file.name)
                            .font(.system(size: 13))
                        Spacer()
                        if !file.compilerFlags.isEmpty {
                            Text(file.compilerFlags)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color(nsColor: .quaternaryLabelColor))
                                .cornerRadius(4)
                        }
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                    Divider()
                }
            }
        }
    }

    private func runScriptDetail(phase: PBXBuildPhaseModel) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Shell:")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
                Text(phase.shellPath)
                    .font(.system(size: 12, design: .monospaced))
            }
            .padding(.top, 8)

            Text("Script:")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)

            ScrollView(.horizontal) {
                Text(phase.shellScript.isEmpty ? "# No script content" : phase.shellScript)
                    .font(.system(size: 11, design: .monospaced))
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: 120)
            .background(Color(nsColor: .textBackgroundColor))
            .cornerRadius(6)
        }
        .padding(12)
    }

    private func phaseHeader(title: String, count: Int?, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
            Text(title)
                .font(.headline)
            if let fileCount = count {
                Text("(\(fileCount) items)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
    }
}
