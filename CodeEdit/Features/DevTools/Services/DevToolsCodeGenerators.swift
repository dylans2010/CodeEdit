//
//  DevToolsCodeGenerators.swift
//  CodeEdit
//
//

import Foundation

/// Engine implementing offline source code generation from schema payloads.
public struct CodeGeneratorsEngine: Sendable {
    public static func jsonToSwift(input: String) -> String {
        guard let data = input.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return "// Invalid JSON object. Please provide a valid JSON dictionary."
        }
        var lines: [String] = ["import Foundation", "", "public struct GeneratedModel: Codable, Sendable {"]
        for (fieldKey, val) in dict.sorted(by: { $0.key < $1.key }) {
            let swiftType = CodeGeneratorsTypeMapper.swiftTypeFor(val)
            lines.append("    public let \(fieldKey): \(swiftType)")
        }
        lines.append("}")
        return lines.joined(separator: "\n")
    }

    public static func jsonToTypeScript(input: String) -> String {
        guard let data = input.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return "// Invalid JSON object."
        }
        var lines: [String] = ["export interface GeneratedModel {"]
        for (fieldKey, val) in dict.sorted(by: { $0.key < $1.key }) {
            let tsType = CodeGeneratorsTypeMapper.tsTypeFor(val)
            lines.append("  \(fieldKey): \(tsType);")
        }
        lines.append("}")
        return lines.joined(separator: "\n")
    }

    public static func jsonToPython(input: String) -> String {
        guard let data = input.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return "# Invalid JSON object."
        }
        var lines: [String] = ["from pydantic import BaseModel", "", "class GeneratedModel(BaseModel):"]
        for (fieldKey, val) in dict.sorted(by: { $0.key < $1.key }) {
            let pyType = CodeGeneratorsTypeMapper.pyTypeFor(val)
            lines.append("    \(fieldKey): \(pyType)")
        }
        return lines.joined(separator: "\n")
    }

    public static func jsonToGo(input: String) -> String {
        guard let data = input.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return "// Invalid JSON object."
        }
        var lines: [String] = ["type GeneratedModel struct {"]
        for (fieldKey, val) in dict.sorted(by: { $0.key < $1.key }) {
            let goName = fieldKey.prefix(1).uppercased() + fieldKey.dropFirst()
            let goType = CodeGeneratorsTypeMapper.goTypeFor(val)
            lines.append("    \(goName) \(goType) `json:\"\(fieldKey)\"`")
        }
        lines.append("}")
        return lines.joined(separator: "\n")
    }

    public static func jsonToRust(input: String) -> String {
        guard let data = input.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return "// Invalid JSON object."
        }
        var lines: [String] = [
            "use serde::{Deserialize, Serialize};",
            "",
            "#[derive(Debug, Clone, Serialize, Deserialize)]",
            "pub struct GeneratedModel {"
        ]
        for (fieldKey, val) in dict.sorted(by: { $0.key < $1.key }) {
            let rustType = CodeGeneratorsTypeMapper.rustTypeFor(val)
            lines.append("    pub \(fieldKey): \(rustType),")
        }
        lines.append("}")
        return lines.joined(separator: "\n")
    }

    public static func jsonToKotlin(input: String) -> String {
        guard let data = input.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return "// Invalid JSON object."
        }
        var lines: [String] = [
            "import kotlinx.serialization.Serializable",
            "",
            "@Serializable",
            "data class GeneratedModel("
        ]
        let entries = dict.sorted(by: { $0.key < $1.key })
        for (indexVal, entry) in entries.enumerated() {
            let isLast = indexVal == entries.count - 1
            let ktType = CodeGeneratorsTypeMapper.kotlinTypeFor(entry.value)
            let trailing = isLast ? "" : ","
            lines.append("    val \(entry.key): \(ktType)\(trailing)")
        }
        lines.append(")")
        return lines.joined(separator: "\n")
    }

    public static func jsonToJava(input: String) -> String {
        guard let data = input.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return "// Invalid JSON object."
        }
        var lines: [String] = [
            "import com.fasterxml.jackson.annotation.JsonProperty;",
            "",
            "public class GeneratedModel {"
        ]
        for (fieldKey, val) in dict.sorted(by: { $0.key < $1.key }) {
            let javaType = CodeGeneratorsTypeMapper.javaTypeFor(val)
            lines.append("    @JsonProperty(\"\(fieldKey)\")")
            lines.append("    private \(javaType) \(fieldKey);")
        }
        lines.append("}")
        return lines.joined(separator: "\n")
    }

    public static func jsonToCSharp(input: String) -> String {
        guard let data = input.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return "// Invalid JSON object."
        }
        var lines: [String] = [
            "using System.Text.Json.Serialization;",
            "",
            "public record GeneratedModel {"
        ]
        for (fieldKey, val) in dict.sorted(by: { $0.key < $1.key }) {
            let csType = CodeGeneratorsTypeMapper.csTypeFor(val)
            let csName = fieldKey.prefix(1).uppercased() + fieldKey.dropFirst()
            lines.append("    [JsonPropertyName(\"\(fieldKey)\")]")
            lines.append("    public \(csType) \(csName) { get; init; }")
        }
        lines.append("}")
        return lines.joined(separator: "\n")
    }

    public static func jsonToDart(input: String) -> String {
        guard let data = input.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return "// Invalid JSON object."
        }
        var lines: [String] = ["class GeneratedModel {"]
        for (fieldKey, val) in dict.sorted(by: { $0.key < $1.key }) {
            let dartType = CodeGeneratorsTypeMapper.dartTypeFor(val)
            lines.append("  final \(dartType) \(fieldKey);")
        }
        lines.append("")
        lines.append("  GeneratedModel({")
        for (fieldKey, _) in dict.sorted(by: { $0.key < $1.key }) {
            lines.append("    required this.\(fieldKey),")
        }
        lines.append("  });")
        lines.append("}")
        return lines.joined(separator: "\n")
    }

    public static func jsonToPHP(input: String) -> String {
        guard let data = input.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return "<?php // Invalid JSON object."
        }
        var lines: [String] = ["<?php", "", "readonly class GeneratedModel {", "    public function __construct("]
        let entries = dict.sorted(by: { $0.key < $1.key })
        for (indexVal, entry) in entries.enumerated() {
            let isLast = indexVal == entries.count - 1
            let phpType = CodeGeneratorsTypeMapper.phpTypeFor(entry.value)
            let trailing = isLast ? "" : ","
            lines.append("        public \(phpType) $\(entry.key)\(trailing)")
        }
        lines.append("    ) {}")
        lines.append("}")
        return lines.joined(separator: "\n")
    }

    public static func jsonToSchema(input: String) -> String {
        guard let data = input.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return "{\"$schema\": \"http://json-schema.org/draft-07/schema#\", \"type\": \"object\"}"
        }
        var properties: [String: Any] = [:]
        for (fieldKey, val) in dict {
            properties[fieldKey] = ["type": CodeGeneratorsTypeMapper.jsonSchemaTypeFor(val)]
        }
        let schema: [String: Any] = [
            "$schema": "http://json-schema.org/draft-07/schema#",
            "type": "object",
            "properties": properties,
            "required": Array(dict.keys).sorted()
        ]
        if let outData = try? JSONSerialization.data(withJSONObject: schema, options: .prettyPrinted),
           let outString = String(data: outData, encoding: .utf8) {
            return outString
        }
        return "{}"
    }

    public static func analyzeJsonTypes(input: String) -> String {
        guard let data = input.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return "Error: Payload is not a valid JSON dictionary."
        }
        var lines: [String] = ["JSON Schema Analysis Report:", "-----------------------------"]
        lines.append("Total Root Fields: \(dict.count)")
        for (fieldKey, val) in dict.sorted(by: { $0.key < $1.key }) {
            let typeName = CodeGeneratorsTypeMapper.jsonSchemaTypeFor(val)
            lines.append("• '\(fieldKey)': Type = \(typeName)")
        }
        return lines.joined(separator: "\n")
    }

    public static func jsonToCSV(input: String) -> String {
        guard let data = input.data(using: .utf8) else { return "Invalid UTF-8" }
        var dicts: [[String: Any]] = []
        if let array = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
            dicts = array
        } else if let single = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            dicts = [single]
        }
        guard let firstItem = dicts.first else { return "No rows found." }
        let headers = Array(firstItem.keys).sorted()
        var csvLines: [String] = [headers.joined(separator: ",")]
        for item in dicts {
            let row = headers.map { headerKey in
                let val = item[headerKey] ?? ""
                return "\"\(val)\""
            }
            csvLines.append(row.joined(separator: ","))
        }
        return csvLines.joined(separator: "\n")
    }

    public static func generateQRCodeText(input: String) -> String {
        return "[QR Code Generated for: '\(input)']\nECC Level: High\nPayload Size: \(input.count) bytes"
    }
}

/// Helper mapping JSON values to target programming language types.
public struct CodeGeneratorsTypeMapper: Sendable {
    public static func swiftTypeFor(_ value: Any) -> String {
        switch value {
        case is Bool: return "Bool"
        case is Int: return "Int"
        case is Double: return "Double"
        case is String: return "String"
        case is [Any]: return "[String]"
        default: return "String"
        }
    }

    public static func tsTypeFor(_ value: Any) -> String {
        switch value {
        case is Bool: return "boolean"
        case is Int, is Double: return "number"
        case is String: return "string"
        case is [Any]: return "any[]"
        default: return "Record<string, any>"
        }
    }

    public static func pyTypeFor(_ value: Any) -> String {
        switch value {
        case is Bool: return "bool"
        case is Int: return "int"
        case is Double: return "float"
        case is String: return "str"
        case is [Any]: return "list[Any]"
        default: return "dict[str, Any]"
        }
    }

    public static func goTypeFor(_ value: Any) -> String {
        switch value {
        case is Bool: return "bool"
        case is Int: return "int"
        case is Double: return "float64"
        case is String: return "string"
        case is [Any]: return "[]interface{}"
        default: return "map[string]interface{}"
        }
    }

    public static func rustTypeFor(_ value: Any) -> String {
        switch value {
        case is Bool: return "bool"
        case is Int: return "i64"
        case is Double: return "f64"
        case is String: return "String"
        case is [Any]: return "Vec<String>"
        default: return "serde_json::Value"
        }
    }

    public static func kotlinTypeFor(_ value: Any) -> String {
        switch value {
        case is Bool: return "Boolean"
        case is Int: return "Int"
        case is Double: return "Double"
        case is String: return "String"
        default: return "String"
        }
    }

    public static func javaTypeFor(_ value: Any) -> String {
        switch value {
        case is Bool: return "Boolean"
        case is Int: return "Integer"
        case is Double: return "Double"
        case is String: return "String"
        default: return "Object"
        }
    }

    public static func csTypeFor(_ value: Any) -> String {
        switch value {
        case is Bool: return "bool"
        case is Int: return "int"
        case is Double: return "double"
        case is String: return "string"
        default: return "object"
        }
    }

    public static func dartTypeFor(_ value: Any) -> String {
        switch value {
        case is Bool: return "bool"
        case is Int: return "int"
        case is Double: return "double"
        case is String: return "String"
        default: return "dynamic"
        }
    }

    public static func phpTypeFor(_ value: Any) -> String {
        switch value {
        case is Bool: return "bool"
        case is Int: return "int"
        case is Double: return "float"
        case is String: return "string"
        default: return "mixed"
        }
    }

    public static func jsonSchemaTypeFor(_ value: Any) -> String {
        switch value {
        case is Bool: return "boolean"
        case is Int: return "integer"
        case is Double: return "number"
        case is String: return "string"
        case is [Any]: return "array"
        default: return "object"
        }
    }
}
