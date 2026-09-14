//
//  PromptAndJSONProtocol.swift
//  UniversalIDE
//

import Foundation

public struct AssistPromptBuilder {
    public static func buildSystemPrompt(
        objective: String,
        systemPromptContent: String = "Autonomous AI Agent System Prompt",
        attachedFiles: [String: String] = [:],
        skillsBlock: String = "",
        repoManifest: String = "",
        activeFiles: [String: String] = [:],
        toolSchemas: String = ""
    ) -> String {
        let filesBlock = attachedFiles.map { "File: \($0.key)\n\($0.value)" }.joined(separator: "\n\n")
        let activeBlock = activeFiles.map { "Active File: \($0.key)\n\($0.value)" }.joined(separator: "\n\n")

        return """
# SYSTEM PROMPT (OPERATING POLICY)
\(systemPromptContent)

# HIDDEN RUNTIME INSTRUCTIONS & ROLE
Execution Key: com.SwiftCode.Assist-Agent
Execution Mode: com.SwiftCode.Assist-Agent

You are an autonomous Swift/macOS coding agent working in the Universal Code Editor.
Your goal is: "\(objective)"

You can execute local actions by outputting a JSON object.
Choose one of the available tools, or output a final response when the task is complete.

You MUST respond in exactly this JSON format (no markdown backticks, no text outside the JSON):
{
  "toolId": "the_tool_id",
  "input": { "key": "value" },
  "explanation": "Why you are using this tool"
}
OR, if the goal is fully achieved and no more tools are needed:
{
  "finalResponse": "A clear, detailed description of your achievements and the files modified"
}

# ATTACHED FILES FOR THIS TASK (READ-ONLY REFERENCE)
\(filesBlock)

# DISCOVERED SYSTEM SKILLS
\(skillsBlock)

# CONVERSATION CONTEXT & WORKSPACE
\(repoManifest)

# ACTIVE FILE CONTENTS
\(activeBlock)

# AVAILABLE TOOLS
\(toolSchemas)

# SECURITY CONSTRAINTS
- Never use relative traversal (e.g. "..") or root paths (e.g. "/").
- Always double check file paths before reading/writing.
"""
    }
}

public struct JSONExtractor {
    public static func extractJSON(from response: String) -> [String: Any]? {
        let trimmed = response.trimmingCharacters(in: .whitespacesAndNewlines)

        // 1. Direct JSON attempt
        if let data = trimmed.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            return json
        }

        // 2. Fenced Markdown block extraction (```json ... ```)
        if let startRange = trimmed.range(of: "```json"),
           let endRange = trimmed.range(of: "```", range: startRange.upperBound..<trimmed.endIndex) {
            let block = trimmed[startRange.upperBound..<endRange.lowerBound].trimmingCharacters(in: .whitespacesAndNewlines)
            if let data = block.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                return json
            }
        }

        // 3. Regex boundary scanner ({ ... })
        if let firstBrace = trimmed.firstIndex(of: "{"),
           let lastBrace = trimmed.lastIndex(of: "}") {
            let block = trimmed[firstBrace...lastBrace]
            if let data = block.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                return json
            }
        }

        return nil
    }
}
