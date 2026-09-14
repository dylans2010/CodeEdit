//
//  DatabaseExplorerStudio.swift
//  UniversalIDE
//

import SwiftUI
import Foundation

public struct DatabaseColumnSchema: Identifiable, Sendable {
    public var id: String { name }
    public let name: String
    public let dataType: String
    public let isPrimaryKey: Bool
    public let isNullable: Bool

    public init(name: String, dataType: String, isPrimaryKey: Bool, isNullable: Bool) {
        self.name = name
        self.dataType = dataType
        self.isPrimaryKey = isPrimaryKey
        self.isNullable = isNullable
    }
}

public struct DatabaseTableSchema: Identifiable, Sendable {
    public var id: String { tableName }
    public let tableName: String
    public let columns: [DatabaseColumnSchema]

    public init(tableName: String, columns: [DatabaseColumnSchema]) {
        self.tableName = tableName
        self.columns = columns
    }
}

public final class SQLiteDriver: @unchecked Sendable {
    public init() {}

    public func introspectSchema(dbPath: String) async throws -> [DatabaseTableSchema] {
        return [
            DatabaseTableSchema(tableName: "users", columns: [
                DatabaseColumnSchema(name: "id", dataType: "INTEGER", isPrimaryKey: true, isNullable: false),
                DatabaseColumnSchema(name: "email", dataType: "TEXT", isPrimaryKey: false, isNullable: false)
            ])
        ]
    }

    public func executeQuery(dbPath: String, sql: String) async throws -> [[String: String]] {
        return [
            ["id": "1", "email": "user@example.com"]
        ]
    }
}

public final class SupabasePostgresDriver: @unchecked Sendable {
    public init() {}

    public func introspectTables(connectionString: String) async throws -> [DatabaseTableSchema] {
        return [
            DatabaseTableSchema(tableName: "posts", columns: [
                DatabaseColumnSchema(name: "id", dataType: "uuid", isPrimaryKey: true, isNullable: false),
                DatabaseColumnSchema(name: "title", dataType: "text", isPrimaryKey: false, isNullable: false)
            ])
        ]
    }
}

public final class DatabaseAIService: @unchecked Sendable {
    public init() {}

    public func translateTextToSQL(prompt: String, schema: [DatabaseTableSchema]) async -> String {
        return "SELECT * FROM users WHERE email LIKE '%@example.com';"
    }
}

public struct DatabaseExplorerView: View {
    @State private var tables: [DatabaseTableSchema] = []
    @State private var selectedTable: String?
    @State private var sqlQuery: String = "SELECT * FROM users;"
    @State private var queryResults: [[String: String]] = []

    public init() {}

    public var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading) {
                Text("Database Studio").font(.headline).padding()
                List(tables) { table in
                    Text(table.tableName)
                        .onTapGesture { selectedTable = table.tableName }
                }
            }
            .frame(width: 200)

            Divider()

            VStack(alignment: .leading, spacing: 10) {
                TextEditor(text: $sqlQuery)
                    .frame(height: 100)
                    .font(.monospaced(.body)())
                HStack {
                    Button("Run Query") {
                        queryResults = [["id": "1", "email": "dev@universalide.com"]]
                    }
                    Button("Generate SQL with AI") {
                        sqlQuery = "SELECT * FROM users LIMIT 10;"
                    }
                }
                Divider()
                Text("Results").font(.subheadline).bold()
                ScrollView {
                    VStack(alignment: .leading) {
                        ForEach(queryResults.indices, id: \.self) { idx in
                            Text("\(queryResults[idx])").monospaced()
                        }
                    }
                }
            }
            .padding()
        }
        .onAppear {
            tables = [
                DatabaseTableSchema(tableName: "users", columns: [
                    DatabaseColumnSchema(name: "id", dataType: "INTEGER", isPrimaryKey: true, isNullable: false)
                ])
            ]
        }
    }
}
