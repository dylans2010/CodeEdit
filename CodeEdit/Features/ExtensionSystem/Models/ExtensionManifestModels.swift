//
//  ExtensionManifestModels.swift
//  CodeEdit
//
//

import Foundation

/// Configuration field definition in an extension.json manifest.
public struct EditorExtensionConfigField: Codable, Sendable, Hashable {
    public let key: String
    public let type: String // "string", "number", "boolean"
    public let defaultValue: String?
    public let description: String?

    public init(
        key: String,
        type: String,
        defaultValue: String? = nil,
        description: String? = nil
    ) {
        self.key = key
        self.type = type
        self.defaultValue = defaultValue
        self.description = description
    }
}

/// Official manifest specification for editor extensions (extension.json).
public struct EditorExtensionManifest: Identifiable, Codable, Sendable, Hashable {
    public var id: String { extensionID }
    public let extensionID: String
    public let name: String
    public let version: String
    public let description: String
    public let author: String
    public let category: String
    public let capabilities: [String]
    public let entryPoint: String
    public let swiftCodeAssistCapable: Bool
    public let configFields: [EditorExtensionConfigField]?

    enum CodingKeys: String, CodingKey {
        case extensionID = "id"
        case name
        case version
        case description
        case author
        case category
        case capabilities
        case entryPoint
        case swiftCodeAssistCapable
        case configFields
    }

    public init(
        extensionID: String,
        name: String,
        version: String,
        description: String,
        author: String,
        category: String,
        capabilities: [String] = [],
        entryPoint: String = "main.swift",
        swiftCodeAssistCapable: Bool = false,
        configFields: [EditorExtensionConfigField]? = nil
    ) {
        self.extensionID = extensionID
        self.name = name
        self.version = version
        self.description = description
        self.author = author
        self.category = category
        self.capabilities = capabilities
        self.entryPoint = entryPoint
        self.swiftCodeAssistCapable = swiftCodeAssistCapable
        self.configFields = configFields
    }
}
