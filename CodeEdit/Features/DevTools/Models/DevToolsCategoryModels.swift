//
//  DevToolsCategoryModels.swift
//  CodeEdit
//
//

import Foundation

/// 11 categories grouping the 156 offline developer utilities.
public enum DevToolCategory: String, CaseIterable, Codable, Sendable {
    case codeGenerators = "Code & Schema Generators"
    case formatConverters = "Format Converters & Parsers"
    case cryptography = "Cryptography & Security"
    case textUtilities = "Text & String Utilities"
    case regexScheduling = "Regex & Scheduling"
    case webNetwork = "Web & Network Utilities"
    case cssDesign = "CSS, Layout & Design Utilities"
    case minifiersOptimizers = "Minifiers & Asset Optimizers"
    case systemHardware = "System, Hardware & OS Utilities"
    case cheatsheets = "Developer Cheatsheets & Guides"
    case unitsMeasurement = "Units, Measurements & Misc"
}

/// Metadata describing a developer tool in the catalog.
public struct DevToolItem: Identifiable, Codable, Sendable, Hashable {
    public let id: String
    public let title: String
    public let category: DevToolCategory
    public let summary: String
    public let iconName: String
    public let keywords: [String]

    public init(
        id: String,
        title: String,
        category: DevToolCategory,
        summary: String,
        iconName: String = "wrench.and.screwdriver",
        keywords: [String] = []
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.summary = summary
        self.iconName = iconName
        self.keywords = keywords
    }
}

/// Catalog indexing all 156 built-in offline developer tools.
public struct DevToolsCatalog: Sendable {
    public static let allTools: [DevToolItem] = {
        DevToolsCatalogPart1.tools +
        DevToolsCatalogPart2.tools +
        DevToolsCatalogPart3.tools
    }()
}
