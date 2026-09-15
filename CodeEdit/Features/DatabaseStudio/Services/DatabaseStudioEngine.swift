//
//  DatabaseStudioEngine.swift
//  CodeEdit
//
//

import Foundation

/// Engine executing queries, introspecting schemas, and managing database migrations.
public actor DatabaseStudioEngine {
    public static let shared = DatabaseStudioEngine()

    private init() {}

    /// Introspects tables and columns from a local SQLite database file.
    public func introspectSQLiteSchema(databaseURL: URL) async throws -> [DBTableSchema] {
        let listTablesCmd = "sqlite3 \"\(databaseURL.path)\" \".tables\""
        let tablesRes = try await CommandRunner.execute(command: listTablesCmd, in: databaseURL.deletingLastPathComponent())

        let tableNames = tablesRes.output
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }

        var tables: [DBTableSchema] = []
        for name in tableNames {
            let pragmaCmd = "sqlite3 \"\(databaseURL.path)\" \"PRAGMA table_info(\(name));\""
            let pragmaRes = try await CommandRunner.execute(command: pragmaCmd, in: databaseURL.deletingLastPathComponent())

            var columns: [DBColumnSchema] = []
            for colLine in pragmaRes.output.components(separatedBy: .newlines) where !colLine.isEmpty {
                let parts = colLine.components(separatedBy: "|")
                if parts.count >= 6 {
                    let colName = parts[1]
                    let colType = parts[2]
                    let notNull = parts[3] == "1"
                    let dflt = parts[4].isEmpty ? nil : parts[4]
                    let pk = parts[5] == "1"
                    columns.append(DBColumnSchema(
                        name: colName,
                        dataType: colType,
                        isNullable: !notNull,
                        isPrimaryKey: pk,
                        defaultValue: dflt
                    ))
                }
            }

            tables.append(DBTableSchema(name: name, columns: columns, foreignKeys: [], estimatedRowCount: 0))
        }

        return tables
    }

    /// Executes arbitrary SQL query against a local SQLite file with timing.
    public func executeSQLiteQuery(databaseURL: URL, sql: String) async throws -> DBQueryResult {
        let startTime = Date()
        let command = "sqlite3 -header -separator '|' \"\(databaseURL.path)\" \"\(sql)\""
        let res = try await CommandRunner.execute(command: command, in: databaseURL.deletingLastPathComponent())
        let duration = Date().timeIntervalSince(startTime)

        let lines = res.output.components(separatedBy: .newlines).filter { !$0.isEmpty }
        guard let headerLine = lines.first else {
            return DBQueryResult(columns: [], rows: [], executionTime: duration, affectedRows: 0)
        }

        let columns = headerLine.components(separatedBy: "|")
        var rows: [[String: String]] = []

        for rowLine in lines.dropFirst() {
            let values = rowLine.components(separatedBy: "|")
            var rowDict: [String: String] = [:]
            for (index, col) in columns.enumerated() {
                rowDict[col] = (index < values.count) ? values[index] : ""
            }
            rows.append(rowDict)
        }

        return DBQueryResult(columns: columns, rows: rows, executionTime: duration, affectedRows: rows.count)
    }

    /// Creates a timestamped migration file with UP and DOWN sections.
    public func createMigration(
        projectURL: URL,
        description: String,
        upSQL: String,
        downSQL: String
    ) throws -> URL {
        let migrationsDir = projectURL.appendingPathComponent("Migrations")
        try FileManager.default.createDirectory(at: migrationsDir, withIntermediateDirectories: true)

        let timestamp = Int(Date().timeIntervalSince1970)
        let sanitizedDesc = description.replacingOccurrences(of: " ", with: "_").lowercased()
        let fileName = "V\(timestamp)__\(sanitizedDesc).sql"
        let fileURL = migrationsDir.appendingPathComponent(fileName)

        let content = """
        -- UP Migration
        \(upSQL)

        -- DOWN Migration
        \(downSQL)
        """

        try content.write(to: fileURL, atomically: true, encoding: .utf8)
        return fileURL
    }

    /// Exports query rows to a formatted CSV string.
    public func exportToCSV(result: DBQueryResult) -> String {
        var lines: [String] = []
        lines.append(result.columns.joined(separator: ","))

        for row in result.rows {
            let rowVals = result.columns.map { col in
                let val = row[col] ?? ""
                return val.contains(",") ? "\"\(val)\"" : val
            }
            lines.append(rowVals.joined(separator: ","))
        }

        return lines.joined(separator: "\n")
    }
}
