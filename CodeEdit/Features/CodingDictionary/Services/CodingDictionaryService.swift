//
//  CodingDictionaryService.swift
//  CodeEdit
//
//

import Foundation

/// Service querying the offline Apple & Swift framework API dictionary index.
public actor CodingDictionaryService {
    public static let shared = CodingDictionaryService()

    private var entries: [DictionaryEntry] = []

    private init() {
        seedDictionary()
    }

    /// Queries dictionary entries by token prefix, symbol name, or framework.
    public func search(query: String, frameworkFilter: String? = nil) -> [DictionaryEntry] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if trimmed.isEmpty {
            if let filter = frameworkFilter, !filter.isEmpty {
                return entries.filter { $0.framework.lowercased() == filter.lowercased() }
            }
            return entries
        }

        return entries.filter { entry in
            let matchesFramework = (frameworkFilter == nil) || (entry.framework.lowercased() == frameworkFilter?.lowercased())
            let matchesQuery = entry.name.lowercased().contains(trimmed)
                || entry.summary.lowercased().contains(trimmed)
                || entry.declaration.lowercased().contains(trimmed)
            return matchesFramework && matchesQuery
        }
    }

    private func seedDictionary() {
        self.entries = [
            DictionaryEntry(
                id: "swiftui.view",
                name: "View",
                framework: "SwiftUI",
                declaration: "public protocol View",
                summary: "A type that represents part of the user interface of an app and provides modifiers that you use to configure views.",
                parameters: [],
                returnValue: nil,
                examples: [
                    DictionaryExample(
                        title: "Basic Custom View",
                        code: "struct CustomView: View {\n    var body: some View {\n        Text(\"Hello\")\n    }\n}"
                    )
                ],
                commonMistakes: [
                    DictionaryMistake(
                        description: "Heavy computation inside body",
                        explanation: "The body property is re-evaluated frequently by the SwiftUI layout engine.",
                        fix: "Offload expensive operations to a background task or ViewModel."
                    )
                ]
            ),
            DictionaryEntry(
                id: "swift.actor",
                name: "actor",
                framework: "Swift",
                declaration: "public actor <Name>",
                summary: "An actor is a reference type that protects its mutable state from data races by isolating concurrent access.",
                parameters: [],
                returnValue: nil,
                examples: [
                    DictionaryExample(
                        title: "Actor Definition",
                        code: "actor DataStore {\n    private var cache: [String: String] = [:]\n    func get(_ key: String) -> String? {\n        cache[key]\n    }\n}"
                    )
                ],
                commonMistakes: [
                    DictionaryMistake(
                        description: "Accessing actor property synchronously",
                        explanation: "Cross-actor calls require an asynchronous context.",
                        fix: "Prefix actor method calls with 'await'."
                    )
                ]
            ),
            DictionaryEntry(
                id: "foundation.urlsession",
                name: "URLSession",
                framework: "Foundation",
                declaration: "public class URLSession: NSObject",
                summary: "An object that coordinates a group of related, network data-transfer tasks.",
                parameters: [],
                returnValue: nil,
                examples: [
                    DictionaryExample(
                        title: "Async Data Fetch",
                        code: "let (data, response) = try await URLSession.shared.data(from: url)"
                    )
                ]
            )
        ]
    }
}
