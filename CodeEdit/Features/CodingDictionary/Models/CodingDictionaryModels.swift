//
//  CodingDictionaryModels.swift
//  CodeEdit
//
//

import Foundation

/// Return value documentation for a dictionary API entry.
public struct DictionaryReturnValue: Codable, Sendable {
    public let type: String
    public let description: String

    public init(type: String, description: String) {
        self.type = type
        self.description = description
    }
}

/// Parameter documentation for a dictionary API entry.
public struct DictionaryParameter: Codable, Sendable {
    public let name: String
    public let type: String
    public let description: String

    public init(name: String, type: String, description: String) {
        self.name = name
        self.type = type
        self.description = description
    }
}

/// Code example demonstrating an API entry.
public struct DictionaryExample: Codable, Sendable {
    public let title: String
    public let code: String

    public init(title: String, code: String) {
        self.title = title
        self.code = code
    }
}

/// Common developer mistake and remediation.
public struct DictionaryMistake: Codable, Sendable {
    public let description: String
    public let explanation: String
    public let fix: String

    public init(description: String, explanation: String, fix: String) {
        self.description = description
        self.explanation = explanation
        self.fix = fix
    }
}

/// An offline coding dictionary and API reference entry.
public struct DictionaryEntry: Identifiable, Codable, Sendable {
    public let id: String
    public let name: String
    public let framework: String
    public let declaration: String
    public let summary: String
    public let parameters: [DictionaryParameter]
    public let returnValue: DictionaryReturnValue?
    public let examples: [DictionaryExample]
    public let commonMistakes: [DictionaryMistake]

    public init(
        id: String,
        name: String,
        framework: String,
        declaration: String,
        summary: String,
        parameters: [DictionaryParameter] = [],
        returnValue: DictionaryReturnValue? = nil,
        examples: [DictionaryExample] = [],
        commonMistakes: [DictionaryMistake] = []
    ) {
        self.id = id
        self.name = name
        self.framework = framework
        self.declaration = declaration
        self.summary = summary
        self.parameters = parameters
        self.returnValue = returnValue
        self.examples = examples
        self.commonMistakes = commonMistakes
    }
}
