//
//  CodePatchEngine.swift
//  CodeEdit
//

import Foundation

public struct FileSnapshot: Sendable {
    public let url: URL
    public let content: String
    public let timestamp: Date
}

public struct Checkpoint: Identifiable, Sendable {
    public let id: UUID
    public let name: String
    public let timestamp: Date
    public let snapshots: [FileSnapshot]

    public init(id: UUID = UUID(), name: String, snapshots: [FileSnapshot], timestamp: Date = Date()) {
        self.id = id
        self.name = name
        self.snapshots = snapshots
        self.timestamp = timestamp
    }
}

public actor CodePatchEngine {
    public static let shared = CodePatchEngine()

    private var checkpoints: [String: Checkpoint] = [:]
    private var inMemorySnapshots: [URL: String] = [:]

    private init() {}

    // MARK: - Snapshot & Checkpoints

    public func createCheckpoint(name: String, files: [URL]) {
        var snapshots: [FileSnapshot] = []
        for file in files {
            if let content = try? String(contentsOf: file, encoding: .utf8) {
                snapshots.append(FileSnapshot(url: file, content: content, timestamp: Date()))
                inMemorySnapshots[file] = content
            }
        }
        checkpoints[name] = Checkpoint(name: name, snapshots: snapshots)
        DiagnosticEventBus.shared.logEvent(
            component: "CodePatchEngine",
            severity: "INFO",
            category: "checkpoint",
            message: "Created checkpoint '\(name)' covering \(snapshots.count) file(s)"
        )
    }

    public func rollbackCheckpoint(name: String) throws {
        guard let checkpoint = checkpoints[name] else {
            throw NSError(
                domain: "CodePatchEngine",
                code: 404,
                userInfo: [NSLocalizedDescriptionKey: "Checkpoint not found"]
            )
        }

        for snapshot in checkpoint.snapshots {
            try snapshot.content.write(to: snapshot.url, atomically: true, encoding: .utf8)
        }

        DiagnosticEventBus.shared.logEvent(
            component: "CodePatchEngine",
            severity: "WARNING",
            category: "rollback",
            message: "Rolled back to checkpoint '\(name)'"
        )
    }

    // MARK: - Synchronized PBXProj Mutations

    /// Inserts 4 synchronized entries into project.pbxproj when creating a new source file.
    public func registerNewFileInPbxproj(
        pbxprojURL: URL,
        fileName: String,
        relativeFilePath: String,
        targetGroupComment: String = "Features"
    ) throws {
        guard var content = try? String(contentsOf: pbxprojURL, encoding: .utf8) else {
            return
        }

        // Generate deterministic 24-character hexadecimal IDs
        let hash = String(format: "%08X", abs(fileName.hashValue))
        let fileRefID = "CE900001\(hash)00000001"
        let buildFileID = "CE900002\(hash)00000001"

        // 1. PBXBuildFile entry
        let buildEntry = "\t\t\(buildFileID) /* \(fileName) in Sources */ = "
            + "{isa = PBXBuildFile; fileRef = \(fileRefID) /* \(fileName) */; };\n"
        if let range = content.range(of: "/* Begin PBXBuildFile section */\n") {
            content.insert(contentsOf: buildEntry, at: range.upperBound)
        }

        // 2. PBXFileReference entry
        let fileRefEntry = "\t\t\(fileRefID) /* \(fileName) */ = "
            + "{isa = PBXFileReference; fileEncoding = 4; lastKnownFileType = sourcecode.swift; "
            + "path = \(relativeFilePath); sourceTree = \"<group>\"; };\n"
        if let range = content.range(of: "/* Begin PBXFileReference section */\n") {
            content.insert(contentsOf: fileRefEntry, at: range.upperBound)
        }

        // 3. PBXSourcesBuildPhase entry
        let sourceEntry = "\t\t\t\t\(buildFileID) /* \(fileName) in Sources */,\n"
        if let range = content.range(of: "/* Begin PBXSourcesBuildPhase section */") {
            // Find main sources phase
            if let filesRange = content.range(of: "files = (\n", range: range.upperBound..<content.endIndex) {
                content.insert(contentsOf: sourceEntry, at: filesRange.upperBound)
            }
        }

        // 4. PBXGroup entry
        let groupEntry = "\t\t\t\t\(fileRefID) /* \(fileName) */,\n"
        if let groupRange = content.range(of: "/* \(targetGroupComment) */ = {\n") {
            if let childrenRange = content.range(of: "children = (\n", range: groupRange.upperBound..<content.endIndex) {
                content.insert(contentsOf: groupEntry, at: childrenRange.upperBound)
            }
        }

        try content.write(to: pbxprojURL, atomically: true, encoding: .utf8)
        DiagnosticEventBus.shared.logEvent(
            component: "CodePatchEngine",
            severity: "INFO",
            category: "pbxproj_sync",
            message: "Synchronized 4-entry project manifest for \(fileName)"
        )
    }
}
