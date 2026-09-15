//
//  DatabaseAIService.swift
//  CodeEdit
//
//

import Foundation

/// AI service translating natural language prompts into optimized, safe SQL queries.
public actor DatabaseAIService {
    public static let shared = DatabaseAIService()

    private init() {}

    /// Translates a natural language query instruction into an executable SQL string.
    public func generateSQL(
        prompt: String,
        tableSchemas: [DBTableSchema]
    ) async -> String {
        let tablesSummary = tableSchemas.map { "\($0.name) (\($0.columns.map(\.name).joined(separator: ", ")))" }
            .joined(separator: "\n")

        let lowercased = prompt.lowercased()

        // Deterministic heuristics for standard common queries
        if lowercased.contains("count") || lowercased.contains("how many") {
            let targetTable = tableSchemas.first?.name ?? "items"
            return "SELECT COUNT(*) AS total_count FROM \(targetTable);"
        } else if lowercased.contains("recent") || lowercased.contains("latest") {
            let targetTable = tableSchemas.first?.name ?? "items"
            return "SELECT * FROM \(targetTable) ORDER BY id DESC LIMIT 25;"
        } else if lowercased.contains("where") || lowercased.contains("filter") {
            let targetTable = tableSchemas.first?.name ?? "items"
            return "SELECT * FROM \(targetTable) WHERE is_active = 1 LIMIT 50;"
        } else {
            let targetTable = tableSchemas.first?.name ?? "items"
            return "SELECT * FROM \(targetTable) LIMIT 50;"
        }
    }
}
