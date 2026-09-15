//
//  DatabaseStudioView.swift
//  CodeEdit
//
//

import SwiftUI

/// Comprehensive Database Explorer, Data Studio, and SQL console workspace.
public struct DatabaseStudioView: View {
    public let databaseURL: URL?
    @State private var tables: [DBTableSchema] = []
    @State private var selectedTableName: String?
    @State private var sqlQueryText: String = "SELECT * FROM users LIMIT 25;"
    @State private var naturalLanguagePrompt: String = ""
    @State private var queryResult: DBQueryResult?
    @State private var isExecuting: Bool = false
    @State private var errorMessage: String?

    public init(databaseURL: URL? = nil) {
        self.databaseURL = databaseURL
    }

    public var body: some View {
        VStack(spacing: 0) {
            topToolbar
            Divider()

            HSplitView {
                tablesSidebar
                mainWorkspace
            }
        }
        .task {
            await loadSchema()
        }
    }

    private var topToolbar: some View {
        HStack(spacing: 12) {
            Image(systemName: "cylinder.split.1x2")
                .foregroundStyle(.blue)
            Text("Database Studio: \(databaseURL?.lastPathComponent ?? "In-Memory Store")")
                .font(.headline)

            Spacer()

            if let result = queryResult {
                Text("\(result.rows.count) row(s) in \(String(format: "%.3f", result.executionTime))s")
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
            }

            Button {
                Task { await executeCurrentQuery() }
            } label: {
                Label("Run SQL", systemImage: "play.fill")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(8)
    }

    private var tablesSidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Tables")
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
                .padding(8)

            List(tables, selection: $selectedTableName) { table in
                HStack {
                    Image(systemName: "tablecells")
                        .foregroundStyle(.secondary)
                    Text(table.name)
                        .font(.body)
                }
                .tag(table.name)
            }
        }
        .frame(minWidth: 160, maxWidth: 220)
    }

    private var mainWorkspace: some View {
        VSplitView {
            sqlConsolePane
            resultsDataGrid
        }
    }

    private var sqlConsolePane: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(.purple)
                TextField("Ask AI to generate SQL...", text: $naturalLanguagePrompt)
                    .textFieldStyle(.roundedBorder)

                Button("Generate") {
                    Task {
                        let sql = await DatabaseAIService.shared.generateSQL(
                            prompt: naturalLanguagePrompt,
                            tableSchemas: tables
                        )
                        self.sqlQueryText = sql
                    }
                }
            }
            .padding([.horizontal, .top], 8)

            TextEditor(text: $sqlQueryText)
                .font(.system(.body, design: .monospaced))
                .padding(4)
                .background(Color(nsColor: .textBackgroundColor))
                .cornerRadius(6)
                .padding([.horizontal, .bottom], 8)
        }
        .frame(minHeight: 120, maxHeight: 220)
    }

    private var resultsDataGrid: some View {
        VStack(spacing: 0) {
            if let result = queryResult, !result.columns.isEmpty {
                ScrollView([.horizontal, .vertical]) {
                    VStack(alignment: .leading, spacing: 0) {
                        // Header Row
                        HStack(spacing: 1) {
                            ForEach(result.columns, id: \.self) { col in
                                Text(col)
                                    .font(.caption.weight(.bold))
                                    .frame(width: 120, alignment: .leading)
                                    .padding(6)
                                    .background(Color(nsColor: .controlBackgroundColor))
                            }
                        }

                        // Data Rows
                        ForEach(0..<result.rows.count, id: \.self) { idx in
                            let row = result.rows[idx]
                            HStack(spacing: 1) {
                                ForEach(result.columns, id: \.self) { col in
                                    Text(row[col] ?? "")
                                        .font(.caption)
                                        .frame(width: 120, alignment: .leading)
                                        .padding(6)
                                        .background(idx % 2 == 0 ? Color.clear : Color.gray.opacity(0.05))
                                }
                            }
                        }
                    }
                }
            } else {
                Text("Execute a query to view results.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private func loadSchema() async {
        guard let url = databaseURL else {
            self.tables = [
                DBTableSchema(name: "users", columns: [
                    DBColumnSchema(name: "id", dataType: "INTEGER", isPrimaryKey: true),
                    DBColumnSchema(name: "email", dataType: "TEXT"),
                    DBColumnSchema(name: "created_at", dataType: "TIMESTAMP")
                ]),
                DBTableSchema(name: "orders", columns: [
                    DBColumnSchema(name: "id", dataType: "INTEGER", isPrimaryKey: true),
                    DBColumnSchema(name: "user_id", dataType: "INTEGER"),
                    DBColumnSchema(name: "total_amount", dataType: "REAL")
                ])
            ]
            return
        }

        if let schema = try? await DatabaseStudioEngine.shared.introspectSQLiteSchema(databaseURL: url) {
            self.tables = schema
        }
    }

    private func executeCurrentQuery() async {
        self.isExecuting = true
        self.errorMessage = nil

        guard let url = databaseURL else {
            // Simulated in-memory query result
            self.queryResult = DBQueryResult(
                columns: ["id", "email", "created_at"],
                rows: [
                    ["id": "1", "email": "developer@apple.com", "created_at": "2026-09-14 12:00:00"],
                    ["id": "2", "email": "engineer@codeedit.app", "created_at": "2026-09-14 14:30:00"]
                ],
                executionTime: 0.002,
                affectedRows: 2
            )
            self.isExecuting = false
            return
        }

        do {
            let res = try await DatabaseStudioEngine.shared.executeSQLiteQuery(databaseURL: url, sql: sqlQueryText)
            self.queryResult = res
        } catch {
            self.errorMessage = error.localizedDescription
        }

        self.isExecuting = false
    }
}
