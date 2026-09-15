//
//  SkillsParser.swift
//  CodeEdit
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
        author: String = "Author",
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

public enum SkillsParser {
    /// Parses YAML frontmatter from a SKILL.md file content string.
    public static func parseSkillFile(content: String) -> SkillScheme? {
        guard content.hasPrefix("---") else { return nil }
        let components = content.components(separatedBy: "---")
        guard components.count >= 3 else { return nil }
        let frontmatter = components[1]

        var name = "Unknown Skill"
        var summary = ""
        var version = "1.0.0"
        var author = "System"
        var tags: [String] = []
        var recommendedTools: [String] = []
        var guidance: [String] = []

        for line in frontmatter.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("name:") {
                name = trimmed.replacingOccurrences(of: "name:", with: "").trimmingCharacters(in: .whitespaces)
            } else if trimmed.hasPrefix("summary:") || trimmed.hasPrefix("description:") {
                summary = trimmed.components(separatedBy: ":").dropFirst().joined(separator: ":").trimmingCharacters(in: .whitespaces)
            } else if trimmed.hasPrefix("version:") {
                version = trimmed.replacingOccurrences(of: "version:", with: "").trimmingCharacters(in: .whitespaces)
            } else if trimmed.hasPrefix("author:") {
                author = trimmed.replacingOccurrences(of: "author:", with: "").trimmingCharacters(in: .whitespaces)
            } else if trimmed.hasPrefix("- ") {
                let item = trimmed.replacingOccurrences(of: "- ", with: "")
                guidance.append(item)
            }
        }

        return SkillScheme(
            name: name,
            summary: summary,
            version: version,
            author: author,
            tags: tags,
            recommendedTools: recommendedTools,
            guidance: guidance
        )
    }

    /// Discovers skills in global `~/.config/editor/skills/` and local `.skills/`.
    public static func discoverSkills(workspaceURL: URL) -> [SkillScheme] {
        var discovered: [SkillScheme] = []

        let localSkillsDir = workspaceURL.appendingPathComponent(".skills")
        if let items = try? FileManager.default.contentsOfDirectory(at: localSkillsDir, includingPropertiesForKeys: nil) {
            for item in items where item.hasDirectoryPath {
                let skillFile = item.appendingPathComponent("SKILL.md")
                if let content = try? String(contentsOf: skillFile, encoding: .utf8),
                   let scheme = parseSkillFile(content: content) {
                    discovered.append(scheme)
                }
            }
        }

        return discovered
    }

    /// Builds markdown block for prompt injection.
    public static func formatSkillsForPrompt(_ skills: [SkillScheme]) -> String {
        guard !skills.isEmpty else { return "" }
        var output = "# DISCOVERED SYSTEM SKILLS\n"
        for skill in skills {
            output += "- Name: \(skill.name)\n"
            output += "  Description: \(skill.summary)\n"
            if !skill.recommendedTools.isEmpty {
                output += "  Recommended Tools: \(skill.recommendedTools.joined(separator: ", "))\n"
            }
            if !skill.guidance.isEmpty {
                output += "  Guidance: \(skill.guidance.joined(separator: " "))\n"
            }
        }
        return output
    }
}
