//
//  MinimapViewportEngine.swift
//  CodeEdit
//

import SwiftUI
import AppKit

public struct MinimapDiagnosticMarker: Identifiable, Sendable {
    public enum Severity: Sendable {
        case error
        case warning
        case info
        case searchMatch
        case gitAddition
        case gitModification
        case gitDeletion
    }

    public let id: UUID
    public let line: Int
    public let severity: Severity

    public init(id: UUID = UUID(), line: Int, severity: Severity) {
        self.id = id
        self.line = line
        self.severity = severity
    }
}

public struct MinimapConfiguration: Sendable {
    public var scaleFactor: CGFloat
    public var width: CGFloat
    public var showDiagnostics: Bool
    public var showGitGutters: Bool

    public init(
        scaleFactor: CGFloat = 1.0 / 6.0,
        width: CGFloat = 72,
        showDiagnostics: Bool = true,
        showGitGutters: Bool = true
    ) {
        self.scaleFactor = scaleFactor
        self.width = width
        self.showDiagnostics = showDiagnostics
        self.showGitGutters = showGitGutters
    }
}

public struct MinimapView: View {
    public let lines: [String]
    public let visibleLineRange: ClosedRange<Int>
    public let totalLines: Int
    public let markers: [MinimapDiagnosticMarker]
    public let config: MinimapConfiguration
    public let onScrollToLine: (Int) -> Void

    @State private var isDragging: Bool = false

    public init(
        lines: [String],
        visibleLineRange: ClosedRange<Int>,
        totalLines: Int,
        markers: [MinimapDiagnosticMarker] = [],
        config: MinimapConfiguration = MinimapConfiguration(),
        onScrollToLine: @escaping (Int) -> Void
    ) {
        self.lines = lines
        self.visibleLineRange = visibleLineRange
        self.totalLines = max(totalLines, 1)
        self.markers = markers
        self.config = config
        self.onScrollToLine = onScrollToLine
    }

    public var body: some View {
        GeometryReader { proxy in
            let viewHeight = proxy.size.height
            let lineHeight = max(viewHeight / CGFloat(totalLines), 1.5)
            let viewportStart = CGFloat(visibleLineRange.lowerBound - 1) * lineHeight
            let viewportHeight = max(CGFloat(visibleLineRange.count) * lineHeight, 20)

            ZStack(alignment: .topLeading) {
                // Background
                Color(nsColor: .controlBackgroundColor)
                    .opacity(0.4)

                // Miniature token / text projections
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(0..<min(lines.count, 500), id: \.self) { idx in
                        let line = lines[idx]
                        let indent = CGFloat(line.prefix(while: { $0 == " " || $0 == "\t" }).count) * 1.5
                        let contentWidth = min(CGFloat(line.trimmingCharacters(in: .whitespaces).count) * 1.2, config.width - 8)

                        if contentWidth > 0 {
                            RoundedRectangle(cornerRadius: 0.5)
                                .fill(Color.secondary.opacity(0.35))
                                .frame(width: max(contentWidth, 4), height: max(lineHeight * 0.8, 1))
                                .padding(.leading, min(indent, config.width - 12))
                        } else {
                            Spacer().frame(height: max(lineHeight, 1))
                        }
                    }
                }
                .frame(width: config.width, alignment: .topLeading)

                // Diagnostic and Git markers
                ForEach(markers) { marker in
                    let yOffset = CGFloat(marker.line - 1) * lineHeight
                    HStack {
                        Spacer()
                        Circle()
                            .fill(markerColor(for: marker.severity))
                            .frame(width: 3.5, height: 3.5)
                            .padding(.trailing, 2)
                    }
                    .offset(y: yOffset)
                }

                // Interactive Translucent Viewport Scrubber
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.accentColor.opacity(isDragging ? 0.25 : 0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(Color.accentColor.opacity(0.4), lineWidth: 1)
                    )
                    .frame(width: config.width, height: min(viewportHeight, viewHeight))
                    .offset(y: min(max(viewportStart, 0), max(viewHeight - viewportHeight, 0)))
            }
            .frame(width: config.width)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        isDragging = true
                        let fraction = min(max(value.location.y / viewHeight, 0), 1)
                        let targetLine = max(Int(fraction * CGFloat(totalLines)), 1)
                        onScrollToLine(targetLine)
                    }
                    .onEnded { _ in
                        isDragging = false
                    }
            )
        }
        .frame(width: config.width)
    }

    private func markerColor(for severity: MinimapDiagnosticMarker.Severity) -> Color {
        switch severity {
        case .error: return .red
        case .warning: return .yellow
        case .info: return .blue
        case .searchMatch: return .orange
        case .gitAddition: return .green
        case .gitModification: return .blue
        case .gitDeletion: return .red
        }
    }
}
