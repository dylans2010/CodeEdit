//
//  GitConflictResolverView.swift
//  CodeEdit
//
//

import SwiftUI

/// Visual 3-Way Merge Conflict Resolver view.
public struct GitConflictResolverView: View {
    public let fileURL: URL
    @State private var fileContent: String = ""
    @State private var conflictHunks: [ConflictHunk] = []
    @State private var selectedHunkID: UUID?

    public init(fileURL: URL) {
        self.fileURL = fileURL
    }

    public var body: some View {
        VStack(spacing: 0) {
            headerBar
            Divider()

            if conflictHunks.isEmpty {
                resolvedBanner
            } else {
                HSplitView {
                    hunksList
                    hunkComparisonView
                }
            }
        }
        .onAppear {
            loadFile()
        }
    }

    private var headerBar: some View {
        HStack {
            Image(systemName: "arrow.triangle.merge")
                .foregroundStyle(.orange)
            Text("Conflict Resolver: \(fileURL.lastPathComponent)")
                .font(.headline)
            Spacer()
            Text("\(conflictHunks.count) conflict(s) remaining")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(10)
    }

    private var resolvedBanner: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.green)
            Text("All Conflicts Resolved!")
                .font(.title3.weight(.semibold))
            Text("The file has been saved cleanly without conflict markers.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var hunksList: some View {
        List(conflictHunks, selection: $selectedHunkID) { hunk in
            VStack(alignment: .leading, spacing: 4) {
                Text("Conflict at offset \(hunk.startOffset)")
                    .font(.subheadline.weight(.medium))
                Text("Current: \(hunk.currentText.prefix(30))...")
                    .font(.caption)
                    .foregroundStyle(.blue)
                Text("Incoming: \(hunk.incomingText.prefix(30))...")
                    .font(.caption)
                    .foregroundStyle(.green)
            }
            .tag(hunk.id)
        }
        .frame(minWidth: 200, maxWidth: 300)
    }

    private var hunkComparisonView: some View {
        VStack(spacing: 12) {
            if let hunk = conflictHunks.first(where: { $0.id == selectedHunkID }) ?? conflictHunks.first {
                HStack(spacing: 12) {
                    VStack(alignment: .leading) {
                        Text("Current Change (HEAD)")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.blue)
                        ScrollView {
                            Text(hunk.currentText)
                                .font(.system(.body, design: .monospaced))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(8)
                        .background(Color.blue.opacity(0.08))
                        .cornerRadius(6)

                        Button("Accept Current") {
                            resolve(hunk: hunk, action: .acceptCurrent)
                        }
                    }

                    VStack(alignment: .leading) {
                        Text("Incoming Change")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.green)
                        ScrollView {
                            Text(hunk.incomingText)
                                .font(.system(.body, design: .monospaced))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(8)
                        .background(Color.green.opacity(0.08))
                        .cornerRadius(6)

                        Button("Accept Incoming") {
                            resolve(hunk: hunk, action: .acceptIncoming)
                        }
                    }
                }
                .padding()

                HStack {
                    Button("Accept Both") {
                        resolve(hunk: hunk, action: .acceptBoth)
                    }
                }
                .padding(.bottom, 12)
            } else {
                Text("Select a conflict to review.")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func loadFile() {
        guard let content = try? String(contentsOf: fileURL, encoding: .utf8) else { return }
        self.fileContent = content
        self.conflictHunks = Self.parseConflictHunks(from: content)
        self.selectedHunkID = conflictHunks.first?.id
    }

    public static func parseConflictHunks(from text: String) -> [ConflictHunk] {
        var hunks: [ConflictHunk] = []
        let lines = text.components(separatedBy: "\n")
        var inConflict = false
        var isCurrent = true
        var currentLines: [String] = []
        var incomingLines: [String] = []
        var startIndex = 0

        for (idx, line) in lines.enumerated() {
            if line.hasPrefix("<<<<<<<") {
                inConflict = true
                isCurrent = true
                currentLines = []
                incomingLines = []
                startIndex = idx
            } else if line.hasPrefix("=======") && inConflict {
                isCurrent = false
            } else if line.hasPrefix(">>>>>>>") && inConflict {
                inConflict = false
                let hunk = ConflictHunk(
                    currentText: currentLines.joined(separator: "\n"),
                    incomingText: incomingLines.joined(separator: "\n"),
                    startOffset: startIndex,
                    endOffset: idx
                )
                hunks.append(hunk)
            } else if inConflict {
                if isCurrent {
                    currentLines.append(line)
                } else {
                    incomingLines.append(line)
                }
            }
        }
        return hunks
    }

    private func resolve(hunk: ConflictHunk, action: ConflictResolutionAction) {
        let replacement: String
        switch action {
        case .acceptCurrent:
            replacement = hunk.currentText
        case .acceptIncoming:
            replacement = hunk.incomingText
        case .acceptBoth:
            replacement = hunk.currentText + "\n" + hunk.incomingText
        case .custom(let customText):
            replacement = customText
        }

        // Construct target marker block
        let marker = "<<<<<<<"
        if let startRange = fileContent.range(of: marker) {
            if let endRange = fileContent.range(of: ">>>>>>>", range: startRange.upperBound..<fileContent.endIndex) {
                // Find line break after end marker
                let lineBreak = fileContent[endRange.upperBound...].firstIndex(of: "\n") ?? endRange.upperBound
                fileContent.replaceSubrange(startRange.lowerBound...lineBreak, with: replacement + "\n")
                try? fileContent.write(to: fileURL, atomically: true, encoding: .utf8)
                loadFile()
            }
        }
    }
}
