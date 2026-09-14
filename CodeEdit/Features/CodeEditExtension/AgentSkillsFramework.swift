//
//  AgentSkillsFramework.swift
//  UniversalIDE
//

import Foundation

public struct SkillScheme: Codable, Sendable, Hashable {
    public let name: String
    public let summary: String
    public let version: String
    public let author: String
    public let tags: [String]
    public let recommendedTools: [String]
    public let guidance: [String]

    public init(
        name: String,
        summary: String,
        version: String = "1.0.0",
        author: String = "User",
        tags: [String] = [],
        recommendedTools: [String] = [],
        guidance: [String] = []
    ) {
        self.name = name
        self.summary = summary
        self.version = version
        self.author = author
        self.tags = tags
        self.recommendedTools = recommendedTools
        self.guidance = guidance
    }
}

public final class SkillsParser {
    public static func parseSkillMarkdown(_ content: String) -> SkillScheme? {
        guard content.contains("---") else { return nil }
        let components = content.components(separatedBy: "---")
        guard components.count >= 3 else { return nil }

        let frontmatter = components[1]
        var name = "Unnamed Skill"
        var summary = ""
        var recommendedTools: [String] = []
        var guidance: [String] = []

        let lines = frontmatter.components(separatedBy: .newlines)
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("name:") {
                name = trimmed.replacingOccurrences(of: "name:", with: "").trimmingCharacters(in: .whitespaces)
            } else if trimmed.hasPrefix("summary:") || trimmed.hasPrefix("description:") {
                summary = trimmed.replacingOccurrences(of: "summary:", with: "").replacingOccurrences(of: "description:", with: "").trimmingCharacters(in: .whitespaces)
            }
        }

        let body = components[2...] .joined(separator: "---")
        guidance = body.components(separatedBy: .newlines).filter { !$0.isEmpty }

        return SkillScheme(
            name: name,
            summary: summary,
            recommendedTools: recommendedTools,
            guidance: guidance
        )
    }
}

public final class AssistSkillsCheck: @unchecked Sendable {
    public static let shared = AssistSkillsCheck()

    private init() {}

    public func discoverSkills(workspacePath: String) -> [SkillScheme] {
        var discovered: [SkillScheme] = []

        let fm = FileManager.default
        let globalSkillsURL = fm.homeDirectoryForCurrentUser.appendingPathComponent(".config/editor/skills/")
        let localSkillsURL = URL(fileURLWithPath: workspacePath).appendingPathComponent(".skills/")

        for folder in [globalSkillsURL, localSkillsURL] {
            if let files = try? fm.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil) {
                for file in files where file.lastPathComponent == "SKILL.md" {
                    if let text = try? String(contentsOf: file, encoding: .utf8),
                       let skill = SkillsParser.parseSkillMarkdown(text) {
                        discovered.append(skill)
                    }
                }
            }
        }

        return discovered
    }
}
