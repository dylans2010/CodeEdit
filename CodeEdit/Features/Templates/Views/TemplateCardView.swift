//
//  TemplateCardView.swift
//  CodeEdit
//
//  Created by CodeEdit on 2024/09/14.
//

import SwiftUI

struct TemplateCardView: View {
    let template: ProjectTemplate
    let isSelected: Bool
    let onSelect: () -> Void
    let onChoose: () -> Void

    @State private var isHovering = false

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            // Template Icon
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(iconBackgroundColor)
                    .frame(width: 44, height: 44)

                Image(systemName: template.icon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(iconForegroundColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .center, spacing: 8) {
                    Text(template.name)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    Spacer(minLength: 4)

                    // Language / Framework Badge
                    Text(template.badge)
                        .font(.system(size: 10, weight: .medium))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(badgeBackgroundColor)
                        )
                        .foregroundColor(badgeForegroundColor)
                }

                Text(template.description)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(cardBackgroundColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(borderColor, lineWidth: isSelected ? 2 : 1)
        )
        .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .onHover { hovering in
            isHovering = hovering
        }
        .onTapGesture(count: 2) {
            onChoose()
        }
        .onTapGesture(count: 1) {
            onSelect()
        }
    }

    private var cardBackgroundColor: Color {
        if isSelected {
            return Color.accentColor.opacity(0.12)
        } else if isHovering {
            return Color(NSColor.controlBackgroundColor).opacity(0.7)
        } else {
            return Color(NSColor.controlBackgroundColor).opacity(0.35)
        }
    }

    private var borderColor: Color {
        if isSelected {
            return Color.accentColor
        } else if isHovering {
            return Color.secondary.opacity(0.4)
        } else {
            return Color(NSColor.separatorColor).opacity(0.4)
        }
    }

    private var iconBackgroundColor: Color {
        switch template.category {
        case .apple:
            return Color.blue.opacity(0.15)
        case .web:
            return Color.cyan.opacity(0.15)
        case .backend:
            return Color.green.opacity(0.15)
        case .systems:
            return Color.orange.opacity(0.15)
        case .python:
            return Color.yellow.opacity(0.15)
        case .desktop:
            return Color.purple.opacity(0.15)
        case .all:
            return Color.gray.opacity(0.15)
        }
    }

    private var iconForegroundColor: Color {
        switch template.category {
        case .apple: return .blue
        case .web: return .cyan
        case .backend: return .green
        case .systems: return .orange
        case .python: return .yellow
        case .desktop: return .purple
        case .all: return .primary
        }
    }

    private var badgeBackgroundColor: Color {
        Color.secondary.opacity(0.15)
    }

    private var badgeForegroundColor: Color {
        Color.secondary
    }
}
