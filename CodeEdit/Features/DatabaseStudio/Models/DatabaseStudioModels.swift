//
//  DatabaseStudioModels.swift
//  CodeEdit
//
//

import Foundation

/// Supported database engine types.
public enum DatabaseEngineType: String, Codable, CaseIterable, Sendable {
    case sqlite = "SQLite / Core Data"
    case postgres = "PostgreSQL"
    case supabase = "Supabase"
}

/// Column schema description.
public struct DBColumnSchema: Identifiable, Codable, Sendable {
    public var id: String { name }
    public let name: String
    public let dataType: String
    public let isNullable: Bool
    public let isPrimaryKey: Bool
    public let defaultValue: String?

    public init(
        name: String,
        dataType: String,
        isNullable: Bool = true,
        isPrimaryKey: Bool = false,
        defaultValue: String? = nil
    ) {
        self.name = name
        self.dataType = dataType
        self.isNullable = isNullable
        self.isPrimaryKey = isPrimaryKey
        self.defaultValue = defaultValue
    }
}

/// Foreign key relationship between tables.
public struct DBForeignKey: Identifiable, Codable, Sendable {
    public var id: String { "\(fromColumn)->\(toTable).\(toColumn)" }
    public let fromColumn: String
    public let toTable: String
    public let toColumn: String

    public init(fromColumn: String, toTable: String, toColumn: String) {
        self.fromColumn = fromColumn
        self.toTable = toTable
        self.toColumn = toColumn
    }
}

/// Table schema introspected from database.
public struct DBTableSchema: Identifiable, Codable, Sendable {
    public var id: String { name }
    public let name: String
    public let columns: [DBColumnSchema]
    public let foreignKeys: [DBForeignKey]
    public let estimatedRowCount: Int

    public init(
        name: String,
        columns: [DBColumnSchema],
        foreignKeys: [DBForeignKey] = [],
        estimatedRowCount: Int = 0
    ) {
        self.name = name
        self.columns = columns
        self.foreignKeys = foreignKeys
        self.estimatedRowCount = estimatedRowCount
    }
}

/// Query result containing column headers, rows, and execution latency.
public struct DBQueryResult: Sendable {
    public let columns: [String]
    public let rows: [[String: String]]
    public let executionTime: TimeInterval
    public let affectedRows: Int

    public init(
        columns: [String],
        rows: [[String: String]],
        executionTime: TimeInterval = 0.0,
        affectedRows: Int = 0
    ) {
        self.columns = columns
        self.rows = rows
        self.executionTime = executionTime
        self.affectedRows = affectedRows
    }
}
