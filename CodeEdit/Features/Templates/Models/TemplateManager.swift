//
//  TemplateManager.swift
//  CodeEdit
//
//  Created by CodeEdit on 2024/09/14.
//

import Foundation
import Combine

/// Manages template discovery, caching, and project instantiation.
final class TemplateManager: ObservableObject {
    static let shared = TemplateManager()

    @Published private(set) var templates: [ProjectTemplate] = []

    init() {
        loadTemplates()
    }

    /// Loads preset templates from bundle resources or local filesystem.
    func loadTemplates() {
        // Attempt 1: Load from bundled templates_manifest.json
        if let manifest = loadManifest() {
            self.templates = manifest
            return
        }

        // Attempt 2: Load directly from Templates folder if accessible
        if let folderURL = findTemplatesFolder(),
           let folderTemplates = loadFromFolder(folderURL),
           !folderTemplates.isEmpty {
            self.templates = folderTemplates
            return
        }

        self.templates = []
    }

    /// Finds candidate paths for the templates directory.
    private func findTemplatesFolder() -> URL? {
        if let bundleDir = Bundle.main.url(forResource: "Templates", withExtension: nil),
           FileManager.default.fileExists(atPath: bundleDir.path) {
            return bundleDir
        }

        let candidates = [
            Bundle.main.bundleURL.appendingPathComponent("Contents/Resources/Templates"),
            URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("Templates"),
            URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
                .appendingPathComponent("CodeEdit/Templates"),
            URL(fileURLWithPath: #file)
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .appendingPathComponent("Templates")
        ]

        for candidate in candidates where FileManager.default.fileExists(atPath: candidate.path) {
            return candidate
        }
        return nil
    }

    /// Loads templates manifest from bundle or known source paths.
    private func loadManifest() -> [ProjectTemplate]? {
        let manifestPaths: [URL?] = [
            Bundle.main.url(forResource: "templates_manifest", withExtension: "json"),
            Bundle.main.url(forResource: "Templates/templates_manifest", withExtension: "json"),
            findTemplatesFolder()?.appendingPathComponent("templates_manifest.json"),
            URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
                .appendingPathComponent("Templates/templates_manifest.json"),
            URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
                .appendingPathComponent("CodeEdit/Templates/templates_manifest.json")
        ]

        for potentialURL in manifestPaths {
            guard let url = potentialURL,
                  let data = try? Data(contentsOf: url),
                  let decoded = try? JSONDecoder().decode([ProjectTemplate].self, from: data),
                  !decoded.isEmpty else {
                continue
            }
            return decoded
        }
        return nil
    }

    /// Load templates from directory of template folders.
    private func loadFromFolder(_ directory: URL) -> [ProjectTemplate]? {
        guard let items = try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            return nil
        }

        var results: [ProjectTemplate] = []
        for folderURL in items {
            let metaURL = folderURL.appendingPathComponent("template.json")
            guard FileManager.default.fileExists(atPath: metaURL.path),
                  let data = try? Data(contentsOf: metaURL),
                  let template = try? JSONDecoder().decode(ProjectTemplate.self, from: data) else {
                continue
            }
            results.append(template)
        }

        return results.isEmpty ? nil : results.sorted { $0.name < $1.name }
    }

    /// Filters templates based on the category and search term.
    func filteredTemplates(category: TemplateCategory, searchQuery: String) -> [ProjectTemplate] {
        templates.filter { template in
            let matchesCategory = (category == .all) ? true : (template.category == category)

            let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if query.isEmpty {
                return matchesCategory
            }

            let matchesSearch = template.name.lowercased().contains(query) ||
                template.description.lowercased().contains(query) ||
                template.language.lowercased().contains(query) ||
                template.badge.lowercased().contains(query) ||
                template.category.rawValue.lowercased().contains(query)

            return matchesCategory && matchesSearch
        }
    }

    /// Instantiates a template into the destination directory.
    func instantiate(
        template: ProjectTemplate,
        at destinationURL: URL,
        projectName: String,
        bundleID: String = "com.example.app",
        appVersion: String = "1.0.0",
        buildNumber: String = "1",
        appDescription: String = "A project generated with CodeEdit."
    ) throws {
        let fileManager = FileManager.default

        if !fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.createDirectory(at: destinationURL, withIntermediateDirectories: true)
        }

        let year = String(Calendar.current.component(.year, from: Date()))
        let author = NSFullUserName().isEmpty ? NSUserName() : NSFullUserName()

        for (relativePath, rawContent) in template.files {
            let resolvedRelPath = relativePath
                .replacingOccurrences(of: "{{PROJECT_NAME}}", with: projectName)

            let targetFileURL = destinationURL.appendingPathComponent(resolvedRelPath)
            let parentDirURL = targetFileURL.deletingLastPathComponent()

            if !fileManager.fileExists(atPath: parentDirURL.path) {
                try fileManager.createDirectory(at: parentDirURL, withIntermediateDirectories: true)
            }

            let processedContent = rawContent
                .replacingOccurrences(of: "{{PROJECT_NAME}}", with: projectName)
                .replacingOccurrences(of: "{{BUNDLE_ID}}", with: bundleID)
                .replacingOccurrences(of: "{{APP_VERSION}}", with: appVersion)
                .replacingOccurrences(of: "{{BUILD_NUMBER}}", with: buildNumber)
                .replacingOccurrences(of: "{{APP_DESCRIPTION}}", with: appDescription)
                .replacingOccurrences(of: "{{YEAR}}", with: year)
                .replacingOccurrences(of: "{{AUTHOR}}", with: author)

            try processedContent.write(to: targetFileURL, atomically: true, encoding: .utf8)

            if targetFileURL.pathExtension == "sh" {
                try? fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: targetFileURL.path)
            }
        }
    }
}
