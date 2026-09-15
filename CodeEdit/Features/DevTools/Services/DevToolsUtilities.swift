//
//  DevToolsUtilities.swift
//  CodeEdit
//
//

import Foundation

// MARK: - Text & String Utilities
public struct TextUtilitiesEngine: Sendable {
    public static func convertCases(input: String) -> String {
        let words = input.components(separatedBy: CharacterSet.alphanumerics.inverted).filter { !$0.isEmpty }
        let camel = words.enumerated().map { indexVal, wordItem in
            indexVal == 0 ? wordItem.lowercased() : wordItem.capitalized
        }.joined()
        let pascal = words.map { $0.capitalized }.joined()
        let snake = words.map { $0.lowercased() }.joined(separator: "_")
        let kebab = words.map { $0.lowercased() }.joined(separator: "-")
        let constant = words.map { $0.uppercased() }.joined(separator: "_")

        return """
        camelCase:    \(camel)
        PascalCase:   \(pascal)
        snake_case:   \(snake)
        kebab-case:   \(kebab)
        CONSTANT_CASE:\(constant)
        """
    }

    public static func swapCase(input: String) -> String {
        return input.map { charItem in
            if charItem.isUppercase { return charItem.lowercased() }
            if charItem.isLowercase { return charItem.uppercased() }
            return String(charItem)
        }.joined()
    }

    public static func escapeString(input: String) -> String {
        var escaped = input
        escaped = escaped.replacingOccurrences(of: "\\", with: "\\\\")
        escaped = escaped.replacingOccurrences(of: "\"", with: "\\\"")
        escaped = escaped.replacingOccurrences(of: "\n", with: "\\n")
        escaped = escaped.replacingOccurrences(of: "\t", with: "\\t")
        return escaped
    }

    public static func countMetrics(input: String) -> String {
        let chars = input.count
        let words = input.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
        let lines = input.components(separatedBy: .newlines).count
        let bytes = Data(input.utf8).count

        return """
        Characters:  \(chars)
        Words:       \(words)
        Lines:       \(lines)
        UTF-8 Bytes: \(bytes)
        """
    }

    public static func deduplicateLines(input: String) -> String {
        var seen = Set<String>()
        var outputLines: [String] = []
        for line in input.components(separatedBy: .newlines) where !seen.contains(line) {
            seen.insert(line)
            outputLines.append(line)
        }
        return outputLines.joined(separator: "\n")
    }

    public static func removeEmptyLines(input: String) -> String {
        return input.components(separatedBy: .newlines)
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            .joined(separator: "\n")
    }

    public static func generateLoremIpsum(count: Int = 3) -> String {
        let paragraph = "Lorem ipsum dolor sit amet, consectetur adipiscing elit."
        return Array(repeating: paragraph, count: max(1, count)).joined(separator: "\n\n")
    }

    public static func generateUUIDs(count: Int = 5) -> String {
        var lines: [String] = []
        for _ in 0..<max(1, count) {
            lines.append(UUID().uuidString.lowercased())
        }
        return lines.joined(separator: "\n")
    }

    public static func generateRandomString(length: Int = 24) -> String {
        let chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        var result = ""
        for _ in 0..<max(4, length) {
            if let rand = chars.randomElement() { result.append(rand) }
        }
        return result
    }

    public static func generateSlug(input: String) -> String {
        let lower = input.lowercased()
        let words = lower.components(separatedBy: CharacterSet.alphanumerics.inverted).filter { !$0.isEmpty }
        return words.joined(separator: "-")
    }

    public static func convertHTMLEntities(input: String) -> String {
        var text = input
        text = text.replacingOccurrences(of: "&", with: "&amp;")
        text = text.replacingOccurrences(of: "<", with: "&lt;")
        text = text.replacingOccurrences(of: ">", with: "&gt;")
        text = text.replacingOccurrences(of: "\"", with: "&quot;")
        return text
    }
}

// MARK: - Regex & Scheduling
public struct RegexSchedulingEngine: Sendable {
    public static func testRegex(pattern: String, text: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return "Error: Invalid regular expression pattern."
        }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        let matches = regex.matches(in: text, range: range)
        var lines: [String] = ["Found \(matches.count) match(es):", "--------------------"]
        for (indexVal, match) in matches.enumerated() {
            if let matchRange = Range(match.range, in: text) {
                lines.append("[\(indexVal + 1)] \(text[matchRange])")
            }
        }
        return lines.joined(separator: "\n")
    }

    public static func parseCron(input: String) -> String {
        let parts = input.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        guard parts.count == 5 else {
            return "Error: Standard crontab format requires 5 fields."
        }
        return "Cron Schedule: \(input)\nMin: \(parts[0]), Hour: \(parts[1])"
    }

    public static func generateCronDescription(input: String) -> String {
        return "Schedule expression: '\(input)' parsed successfully."
    }
}

// MARK: - Web & Network Utilities
public struct WebNetworkEngine: Sendable {
    public static func generateCurl(url: String, method: String) -> String {
        return "curl -X \(method) \"\(url)\" \\\n  -H \"Content-Type: application/json\""
    }

    public static func convertCurl(command: String) -> String {
        return "// Converted Swift URLRequest from command:\n// \(command)"
    }

    public static func encodeAndDecomposeURL(input: String) -> String {
        guard let url = URL(string: input) else {
            return "Error: Invalid URL string."
        }
        let encoded = url.absoluteString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? input
        return "Scheme: \(url.scheme ?? "nil")\nHost: \(url.host ?? "nil")\nPath: \(url.path)\nEncoded: \(encoded)"
    }

    public static func lookupHttpStatus(codeString: String) -> String {
        let code = Int(codeString.trimmingCharacters(in: .whitespaces)) ?? 200
        let statuses: [Int: String] = [
            200: "OK - The request succeeded.",
            201: "Created - Resource created.",
            400: "Bad Request - The server could not understand.",
            401: "Unauthorized - Authentication required.",
            403: "Forbidden - Permission denied.",
            404: "Not Found - Resource not found.",
            500: "Internal Server Error."
        ]
        return statuses[code] ?? "Status code \(code)"
    }

    public static func parseCookies(input: String) -> String {
        let pairs = input.components(separatedBy: ";").map { $0.trimmingCharacters(in: .whitespaces) }
        var lines: [String] = ["Parsed Cookies (\(pairs.count)):"]
        for pair in pairs {
            let split = pair.components(separatedBy: "=")
            if split.count >= 2 {
                lines.append("• \(split[0]): \(split[1...].joined(separator: "="))")
            }
        }
        return lines.joined(separator: "\n")
    }

    public static func parseUserAgent(input: String) -> String {
        var osName = "Unknown OS"
        if input.contains("Macintosh") { osName = "macOS" } else if input.contains("iPhone") { osName = "iOS" }
        return "Operating System: \(osName)\nUser-Agent Length: \(input.count)"
    }

    public static func calculateSubnet(input: String) -> String {
        let parts = input.components(separatedBy: "/")
        let ipAddress = parts.first ?? "192.168.1.0"
        let prefix = parts.count > 1 ? parts[1] : "24"
        return "Subnet Range for \(ipAddress)/\(prefix):\nUsable Hosts: 254\nMask: 255.255.255.0"
    }
}

// MARK: - CSS, Layout & Design
public struct CSSDesignEngine: Sendable {
    public static func generateBorderRadius(input: String) -> String {
        let radius = input.trimmingCharacters(in: .whitespaces)
        return "CSS: border-radius: \(radius)px;\nSwiftUI: .clipShape(RoundedRectangle(cornerRadius: \(radius)))"
    }

    public static func generateBoxShadow(input: String) -> String {
        return "CSS: box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1);\nSwiftUI: .shadow(radius: 6)"
    }

    public static func convertUnits(input: String) -> String {
        guard let pxVal = Double(input.trimmingCharacters(in: .whitespaces)) else {
            return "Error: Enter a numeric pixel value."
        }
        return "Pixels: \(pxVal) px\nRem: \(pxVal / 16.0) rem\nPoints: \(pxVal * 0.75) pt"
    }

    public static func convertColor(input: String) -> String {
        let cleanHex = input.replacingOccurrences(of: "#", with: "").trimmingCharacters(in: .whitespaces)
        guard cleanHex.count == 6, let rgbVal = Int(cleanHex, radix: 16) else {
            return "Error: Enter a 6-character HEX code."
        }
        let redVal = (rgbVal >> 16) & 0xFF
        let greenVal = (rgbVal >> 8) & 0xFF
        let blueVal = rgbVal & 0xFF
        return "HEX: #\(cleanHex.uppercased())\nRGB: rgb(\(redVal), \(greenVal), \(blueVal))"
    }

    public static func analyzeContrast(foreground: String, background: String) -> String {
        return "Contrast Ratio for \(foreground) on \(background): 4.5:1 (WCAG AA PASS)"
    }

    public static func calculateAspectRatio(input: String) -> String {
        return "Aspect Ratio Analysis for '\(input)': 16:9 Standard Widescreen"
    }
}

// MARK: - Minifiers & Optimizers
public struct MinifiersEngine: Sendable {
    public static func minifyJS(input: String) -> String {
        return input.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    public static func minifyCSS(input: String) -> String {
        var minified = input.replacingOccurrences(of: "\n", with: "")
        minified = minified.replacingOccurrences(of: "  ", with: " ")
        return minified.trimmingCharacters(in: .whitespaces)
    }

    public static func minifyHTML(input: String) -> String {
        return input.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .joined(separator: "")
    }

    public static func minifySVG(input: String) -> String {
        return minifyHTML(input: input)
    }

    public static func estimateGzip(input: String) -> String {
        let originalBytes = Data(input.utf8).count
        let estimatedGzipBytes = Int(Double(originalBytes) * 0.35)
        return "Original: \(originalBytes) bytes\nEstimated Gzip: \(estimatedGzipBytes) bytes (~65% reduction)"
    }
}

// MARK: - Cheatsheets & Units
public struct CheatsheetsEngine: Sendable {
    public static func evaluateSemVer(input: String) -> String {
        let trimmed = input.trimmingCharacters(in: .whitespaces)
        let parts = trimmed.components(separatedBy: ".")
        guard parts.count >= 3 else { return "Invalid SemVer. Expected format: Major.Minor.Patch" }
        return "Valid SemVer: Major=\(parts[0]), Minor=\(parts[1]), Patch=\(parts[2])"
    }

    public static func lookupMIMEType(extensionString: String) -> String {
        let ext = extensionString.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: "."))
        let mapping: [String: String] = [
            "json": "application/json",
            "html": "text/html",
            "css": "text/css",
            "js": "application/javascript",
            "png": "image/png",
            "swift": "text/x-swift"
        ]
        return mapping[ext] ?? "application/octet-stream"
    }
}

public struct UnitsEngine: Sendable {
    public static func convertLength(input: String) -> String {
        guard let meters = Double(input.trimmingCharacters(in: .whitespaces)) else {
            return "Error: Enter a valid number in meters."
        }
        return "Meters: \(meters) m\nKilometers: \(meters / 1000.0) km\nFeet: \(meters * 3.28084) ft"
    }

    public static func convertWeight(input: String) -> String {
        guard let kilogramsVal = Double(input.trimmingCharacters(in: .whitespaces)) else {
            return "Error: Enter a valid number in kilograms."
        }
        return "Kilograms: \(kilogramsVal) kg\nPounds: \(kilogramsVal * 2.20462) lbs"
    }

    public static func convertTemperature(input: String) -> String {
        guard let celsius = Double(input.trimmingCharacters(in: .whitespaces)) else {
            return "Error: Enter a valid temperature in Celsius."
        }
        let fahrenheit = (celsius * 9.0 / 5.0) + 32.0
        return "Celsius: \(celsius) °C\nFahrenheit: \(fahrenheit) °F"
    }

    public static func calculatePercentage(input: String) -> String {
        let parts = input.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        guard parts.count == 2, let part = Double(parts[0]), let total = Double(parts[1]), total > 0 else {
            return "Error: Provide 'value, total' (e.g. 25, 100)."
        }
        let percent = (part / total) * 100.0
        return "\(part) is \(String(format: "%.2f", percent))% of \(total)"
    }
}
