//
//  IPABuildService.swift
//  CodeEdit
//
//

import Foundation

/// Service for generating signed iOS App Store and Enterprise IPA packages.
public actor IPABuildService {
    public static let shared = IPABuildService()

    private init() {}

    /// Executes the 4-step IPA compilation and packaging pipeline.
    public func exportIPA(
        projectURL: URL,
        configuration: IPAExportConfiguration
    ) async throws -> URL {
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory.appendingPathComponent("IPAExport-\(UUID().uuidString)")
        try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? fileManager.removeItem(at: tempDir) }

        let archiveURL = tempDir.appendingPathComponent("\(configuration.scheme).xcarchive")
        let exportOptionsPlistURL = tempDir.appendingPathComponent("ExportOptions.plist")

        // Step 1: Create archive
        let archiveCommand = "xcodebuild archive -scheme \(configuration.scheme) "
            + "-archivePath \"\(archiveURL.path)\" -destination 'generic/platform=iOS'"
        let archiveResult = try await CommandRunner.execute(command: archiveCommand, in: projectURL)
        guard archiveResult.exitCode == 0 else {
            throw NSError(
                domain: "IPABuildService",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Archive failed:\n\(archiveResult.output)"]
            )
        }

        // Step 2: Generate ExportOptions.plist
        let plistDict: [String: Any] = [
            "method": configuration.signingMethod.rawValue,
            "signingStyle": "automatic",
            "compileBitcode": false
        ]
        let plistData = try PropertyListSerialization.data(fromPropertyList: plistDict, format: .xml, options: 0)
        try plistData.write(to: exportOptionsPlistURL)

        // Step 3: Export archive to IPA
        try fileManager.createDirectory(at: configuration.outputDirectoryURL, withIntermediateDirectories: true)
        let exportCommand = "xcodebuild -exportArchive -archivePath \"\(archiveURL.path)\" "
            + "-exportPath \"\(configuration.outputDirectoryURL.path)\" "
            + "-exportOptionsPlist \"\(exportOptionsPlistURL.path)\""
        let exportResult = try await CommandRunner.execute(command: exportCommand, in: projectURL)
        guard exportResult.exitCode == 0 else {
            throw NSError(
                domain: "IPABuildService",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "Export archive failed:\n\(exportResult.output)"]
            )
        }

        // Step 4: Validate exported IPA & codesign
        let outputItems = try fileManager.contentsOfDirectory(atPath: configuration.outputDirectoryURL.path)
        guard let ipaName = outputItems.first(where: { $0.hasSuffix(".ipa") }) else {
            throw NSError(
                domain: "IPABuildService",
                code: 3,
                userInfo: [NSLocalizedDescriptionKey: "No .ipa file was found in output directory."]
            )
        }
        let finalIPAURL = configuration.outputDirectoryURL.appendingPathComponent(ipaName)

        // Verify codesign
        let verifyCommand = "codesign --verify --deep --strict \"\(finalIPAURL.path)\""
        _ = try await CommandRunner.execute(command: verifyCommand, in: configuration.outputDirectoryURL)

        return finalIPAURL
    }
}
