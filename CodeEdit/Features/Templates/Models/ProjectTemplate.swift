import Foundation
import SwiftUI

/// Represents the high-level category of a project template.
enum TemplateCategory: String, CaseIterable, Identifiable, Codable {
    case all = "All Templates"
    case apple = "Apple Platforms"
    case web = "Web Development"
    case backend = "Backend & APIs"
    case systems = "Systems & C/C++"
    case python = "Python & Data Science"
    case desktop = "Desktop & Tooling"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .all: return "square.grid.2x2"
        case .apple: return "apple.logo"
        case .web: return "globe"
        case .backend: return "server.rack"
        case .systems: return "hammer"
        case .python: return "chart.bar"
        case .desktop: return "desktopcomputer"
        }
    }
}

/// Represents a project template preset in CodeEdit.
struct ProjectTemplate: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    let category: TemplateCategory
    let icon: String
    let language: String
    let badge: String
    let description: String
    let defaultProjectName: String
    var files: [String: String]

    var fileList: [String] {
        Array(files.keys).sorted()
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: ProjectTemplate, rhs: ProjectTemplate) -> Bool {
        lhs.id == rhs.id
    }
}
