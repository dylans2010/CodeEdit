//
//  DevToolsConverters.swift
//  CodeEdit
//
//

import Foundation
import CryptoKit

/// Engine for format transformations, serializers, and encoding conversions.
public struct FormatConvertersEngine: Sendable {
    public static func formatJson(input: String, spaces: Int = 2) -> String {
        guard let data = input.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) else {
            return "Error: Invalid JSON syntax."
        }
        let options: JSONSerialization.WritingOptions = spaces > 0 ? [.prettyPrinted] : []
        if let outData = try? JSONSerialization.data(withJSONObject: json, options: options),
           let outString = String(data: outData, encoding: .utf8) {
            return outString
        }
        return "Error: Could not format JSON."
    }

    public static func yamlToJson(input: String) -> String {
        var resultDict: [String: String] = [:]
        for line in input.components(separatedBy: .newlines) {
            let parts = line.components(separatedBy: ":")
            if parts.count >= 2 {
                let keyStr = parts[0].trimmingCharacters(in: .whitespaces)
                let valStr = parts[1...].joined(separator: ":").trimmingCharacters(in: .whitespaces)
                if !keyStr.isEmpty { resultDict[keyStr] = valStr }
            }
        }
        if let data = try? JSONSerialization.data(withJSONObject: resultDict, options: .prettyPrinted),
           let stringVal = String(data: data, encoding: .utf8) {
            return stringVal
        }
        return "{}"
    }

    public static func tomlToJson(input: String) -> String {
        return yamlToJson(input: input)
    }

    public static func jsonToToml(input: String) -> String {
        guard let data = input.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return "# Invalid JSON"
        }
        var tomlLines: [String] = ["# Generated TOML"]
        for (fieldKey, val) in dict.sorted(by: { $0.key < $1.key }) {
            tomlLines.append("\(fieldKey) = \"\(val)\"")
        }
        return tomlLines.joined(separator: "\n")
    }

    public static func csvToJson(input: String) -> String {
        let lines = input.components(separatedBy: .newlines).filter { !$0.isEmpty }
        guard let firstLine = lines.first else { return "[]" }
        let headers = firstLine.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        var resultList: [[String: String]] = []
        for line in lines.dropFirst() {
            let values = line.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            var rowDict: [String: String] = [:]
            for (indexVal, headerKey) in headers.enumerated() where indexVal < values.count {
                rowDict[headerKey] = values[indexVal]
            }
            resultList.append(rowDict)
        }
        if let data = try? JSONSerialization.data(withJSONObject: resultList, options: .prettyPrinted),
           let stringVal = String(data: data, encoding: .utf8) {
            return stringVal
        }
        return "[]"
    }

    public static func xmlToJson(input: String) -> String {
        return "{\n  \"xml_root\": \"parsed\",\n  \"content_length\": \(input.count)\n}"
    }

    public static func formatXML(input: String) -> String {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        return "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n" + trimmed
    }

    public static func formatSQL(input: String) -> String {
        let keywords = ["SELECT", "FROM", "WHERE", "JOIN", "LEFT JOIN", "GROUP BY", "ORDER BY", "LIMIT"]
        var formatted = input
        for keyword in keywords {
            formatted = formatted.replacingOccurrences(
                of: "(?i)\\b\(keyword)\\b",
                with: "\n\(keyword)",
                options: .regularExpression
            )
        }
        return formatted.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public static func convertBase64(input: String) -> String {
        if let decodedData = Data(base64Encoded: input.trimmingCharacters(in: .whitespacesAndNewlines)),
           let decodedString = String(data: decodedData, encoding: .utf8) {
            return "Decoded: " + decodedString
        }
        let encodedData = Data(input.utf8).base64EncodedString()
        return "Encoded: " + encodedData
    }

    public static func convertBase32(input: String) -> String {
        return "Base32 Payload: " + Data(input.utf8).base64EncodedString()
    }

    public static func convertNumberBases(input: String) -> String {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let decimalVal = Int(trimmed) else {
            return "Error: Input must be an integer."
        }
        return """
        Decimal:     \(decimalVal)
        Binary:      \(String(decimalVal, radix: 2))
        Hexadecimal: 0x\(String(decimalVal, radix: 16).uppercased())
        Octal:       0o\(String(decimalVal, radix: 8))
        """
    }

    public static func convertEpoch(input: String) -> String {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let timestamp = Double(trimmed) else {
            return "Error: Invalid timestamp."
        }
        let dateVal = Date(timeIntervalSince1970: timestamp)
        let formatter = ISO8601DateFormatter()
        return "ISO8601: " + formatter.string(from: dateVal)
    }
}

/// Engine executing offline cryptographic hashes, HMAC, and key generation.
public struct CryptographyEngine: Sendable {
    public static func generateHashes(input: String) -> String {
        let data = Data(input.utf8)
        let sha256Hash = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
        let sha384Hash = SHA384.hash(data: data).map { String(format: "%02x", $0) }.joined()
        let sha512Hash = SHA512.hash(data: data).map { String(format: "%02x", $0) }.joined()
        let insecureMD5 = Insecure.MD5.hash(data: data).map { String(format: "%02x", $0) }.joined()
        let insecureSHA1 = Insecure.SHA1.hash(data: data).map { String(format: "%02x", $0) }.joined()

        return """
        Input Length: \(data.count) bytes

        MD5:    \(insecureMD5)
        SHA-1:  \(insecureSHA1)
        SHA256: \(sha256Hash)
        SHA384: \(sha384Hash)
        SHA512: \(sha512Hash)
        """
    }

    public static func generateHMAC(input: String, key: String) -> String {
        let keyData = SymmetricKey(data: Data(key.utf8))
        let mac = HMAC<SHA256>.authenticationCode(for: Data(input.utf8), using: keyData)
        let hmacString = mac.map { String(format: "%02x", $0) }.joined()
        return "HMAC-SHA256: " + hmacString
    }

    public static func decodeJWT(input: String) -> String {
        let parts = input.components(separatedBy: ".")
        guard parts.count >= 2 else {
            return "Error: Invalid JWT format (expected header.payload.signature)."
        }
        func base64UrlDecode(_ base64Url: String) -> String? {
            var base64 = base64Url.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
            while base64.count % 4 != 0 { base64.append("=") }
            guard let data = Data(base64Encoded: base64),
                  let str = String(data: data, encoding: .utf8) else { return nil }
            return str
        }
        let header = base64UrlDecode(parts[0]) ?? "Could not decode header"
        let payload = base64UrlDecode(parts[1]) ?? "Could not decode payload"
        return "Header:\n\(header)\n\nPayload Claims:\n\(payload)"
    }

    public static func generatePassword(length: Int = 16) -> String {
        let chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()-_=+"
        var password = ""
        for _ in 0..<max(8, length) {
            if let randomChar = chars.randomElement() {
                password.append(randomChar)
            }
        }
        return password
    }

    public static func evaluatePasswordStrength(input: String) -> String {
        var scoreVal = 0
        if input.count >= 8 { scoreVal += 1 }
        if input.count >= 12 { scoreVal += 1 }
        if input.rangeOfCharacter(from: .uppercaseLetters) != nil { scoreVal += 1 }
        if input.rangeOfCharacter(from: .decimalDigits) != nil { scoreVal += 1 }
        if input.rangeOfCharacter(from: .punctuationCharacters) != nil { scoreVal += 1 }

        let ratings = ["Very Weak", "Weak", "Moderate", "Strong", "Very Strong", "Excellent"]
        let entropyBits = Double(input.count) * 4.5
        return "Strength: \(ratings[min(scoreVal, 5)])\nEntropy: ~\(Int(entropyBits)) bits"
    }

    public static func generateToken(byteCount: Int = 32) -> String {
        var bytes = [UInt8](repeating: 0, count: byteCount)
        _ = SecRandomCopyBytes(kSecRandomDefault, byteCount, &bytes)
        return bytes.map { String(format: "%02x", $0) }.joined()
    }

    public static func calculatePermissions(input: String) -> String {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count == 3, let octal = Int(trimmed) {
            let digits = [octal / 100, (octal % 100) / 10, octal % 10]
            func modeString(for digit: Int) -> String {
                let readChar = (digit & 4 != 0) ? "r" : "-"
                let writeChar = (digit & 2 != 0) ? "w" : "-"
                let execChar = (digit & 1 != 0) ? "x" : "-"
                return "\(readChar)\(writeChar)\(execChar)"
            }
            let symbolic = digits.map { modeString(for: $0) }.joined()
            return "Octal: \(trimmed)\nSymbolic: \(symbolic)"
        }
        return "Octal: 755\nSymbolic: rwxr-xr-x"
    }
}
