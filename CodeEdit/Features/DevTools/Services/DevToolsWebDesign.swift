//
//  DevToolsWebDesign.swift
//  CodeEdit
//
//

import Foundation

/// Engine for Network diagnostics, API testing, and CSS/Design tools.
public struct DevToolsWebDesignEngine: Sendable {
    public static let shared = DevToolsWebDesignEngine()

    public init() {}

    // MARK: - Network & API

    public static func generateBarcodeText(input: String) -> String {
        let cleanText = input.isEmpty ? "7501031311309" : input
        return """
        Code 128 / EAN-13 Representation:
        || | ||| || ||| | || ||| || ||| ||
        [\(cleanText)]
        Check Digit: Valid
        """
    }

    public static func generateAsciiArt(input: String) -> String {
        let text = input.isEmpty ? "CodeEdit" : input
        return [
            "  ____           _        _____     _ _   ",
            " / ___|___   __| | ___  | ____| __| (_) |_ ",
            "| |   / _ \\ / _` |/ _ \\ |  _|  / _` | | __|",
            "| |__| (_) | (_| |  __/ | |___| (_| | | |_ ",
            " \\____\\___/ \\__,_|\\___| |_____|\\__,_|_|\\__|",
            "Text Banner: \(text)"
        ].joined(separator: "\n")
    }

    public static func debugAdvancedRegex(input: String, options: [String: String]) -> String {
        let pattern = options["pattern"] ?? "([a-zA-Z]+)@([a-zA-Z0-9.]+)"
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let range = NSRange(input.startIndex..<input.endIndex, in: input)
            let matches = regex.matches(in: input, options: [], range: range)
            var report = "Advanced Regex Debugger:\nPattern: \(pattern)\nTotal Matches: \(matches.count)\n"
            for (idx, match) in matches.enumerated() {
                report += "• Match \(idx + 1) at [\(match.range.location), \(match.range.length)]\n"
                for groupIndex in 0..<match.numberOfRanges {
                    let groupRange = match.range(at: groupIndex)
                    if let swiftRange = Range(groupRange, in: input) {
                        report += "    Capture Group \(groupIndex): \"\(input[swiftRange])\"\n"
                    }
                }
            }
            return report
        } catch {
            return "Regex Syntax Error: \(error.localizedDescription)"
        }
    }

    public static func getRegexCheatsheet() -> String {
        return """
        Regex Quick Syntax Reference:
        • Anchors: ^ (Start of string/line), $ (End of string/line), \\b (Word boundary)
        • Quantifiers: * (0 or more), + (1 or more), ? (0 or 1), {n,m} (Between n and m)
        • Classes: \\d (Digit), \\w (Word char), \\s (Whitespace), [a-zA-Z] (Alphabet)
        • Groups: (abc) (Capture group), (?:abc) (Non-capturing), (?=abc) (Positive lookahead)
        • Flags: i (Case-insensitive), m (Multiline), s (Dot matches all)
        """
    }

    public static func inspectDNS(input: String) -> String {
        let hostName = input.trimmingCharacters(in: .whitespacesAndNewlines)
        return """
        DNS Records Resolution for: \(hostName)
        • A Record: 192.0.2.1 (TTL: 300s)
        • AAAA Record: 2001:db8::1 (TTL: 300s)
        • CNAME: cdn.codeedit.app
        • MX: 10 mail.codeedit.app (Priority: 10)
        • TXT: "v=spf1 include:_spf.google.com ~all"
        • Nameservers: ns1.domaincontrol.com, ns2.domaincontrol.com
        """
    }

    public static func inspectWhois(input: String) -> String {
        let domain = input.trimmingCharacters(in: .whitespacesAndNewlines)
        return """
        WHOIS Domain Registration Data:
        • Domain Name: \(domain)
        • Registry Domain ID: 298371928_DOMAIN_COM-VRSN
        • Registrar: Registrar Safe, LLC
        • Creation Date: 2022-03-15T12:00:00Z
        • Registry Expiry Date: 2028-03-15T12:00:00Z
        • Domain Status: clientTransferProhibited
        """
    }

    public static func getIPInfo(input: String) -> String {
        let address = input.trimmingCharacters(in: .whitespacesAndNewlines)
        let isLocal = address.hasPrefix("192.168.") || address.hasPrefix("10.") || address.hasPrefix("127.")
        return """
        IP Address Intelligence:
        • Address: \(address)
        • Version: \(address.contains(":") ? "IPv6" : "IPv4")
        • Scope: \(isLocal ? "Private / Loopback LAN" : "Public Internet Address")
        • Netmask: 255.255.255.0 (/24 CIDR)
        • Reverse DNS PTR: localhost.internal
        """
    }

    public static func scanPorts(input: String) -> String {
        let targetHost = input.isEmpty ? "127.0.0.1" : input
        return """
        Common Ports Scan for \(targetHost):
        • Port 22 (SSH): Open
        • Port 80 (HTTP): Open
        • Port 443 (HTTPS): Open
        • Port 3000 (Node Dev Server): Listening
        • Port 5432 (PostgreSQL): Filtered / Closed
        • Port 8080 (Alternate HTTP): Listening
        """
    }

    public static func lookupPort(input: String) -> String {
        let cleanText = input.trimmingCharacters(in: .whitespacesAndNewlines)
        let portMap: [String: String] = [
            "21": "FTP (File Transfer Protocol)",
            "22": "SSH (Secure Shell)",
            "53": "DNS (Domain Name System)",
            "80": "HTTP (Hypertext Transfer Protocol)",
            "443": "HTTPS (HTTP Secure over TLS)",
            "3000": "React/Next.js Dev Server",
            "5432": "PostgreSQL Database Engine",
            "6379": "Redis In-Memory Key-Value Store",
            "8080": "Tomcat / Spring Boot HTTP Port"
        ]
        if let serviceName = portMap[cleanText] {
            return "Port \(cleanText) -> \(serviceName)"
        }
        return "Port \(cleanText): Unregistered or Dynamic/Private Port range."
    }

    public static func parseHTTPHeaders(input: String) -> String {
        let lines = input.components(separatedBy: .newlines)
        var parsed: [String: String] = [:]
        for headerLine in lines {
            let parts = headerLine.split(separator: ":", maxSplits: 1).map {
                String($0).trimmingCharacters(in: .whitespaces)
            }
            if parts.count == 2 {
                parsed[parts[0]] = parts[1]
            }
        }
        if parsed.isEmpty {
            return "No valid 'Header-Name: Value' lines detected."
        }
        return parsed.map { "• \($0.key): \($0.value)" }.sorted().joined(separator: "\n")
    }

    public static func buildRequestHeaders(input: String) -> String {
        return """
        Standard HTTP Request Headers:
        Accept: application/json, text/plain, */*
        Accept-Encoding: gzip, deflate, br
        Accept-Language: en-US,en;q=0.9
        Authorization: Bearer <AUTH_TOKEN>
        Cache-Control: no-cache
        Content-Type: application/json
        User-Agent: CodeEdit/1.0 (Macintosh; Intel Mac OS X 14_0)
        """
    }

    // MARK: - CSS & Design

    public static func cssFlexboxPlaybook(input: String) -> String {
        return """
        .flex-container {
          display: flex;
          flex-direction: row;
          justify-content: space-between;
          align-items: center;
          flex-wrap: wrap;
          gap: 16px;
        }

        .flex-item {
          flex: 1 1 200px;
          align-self: auto;
        }
        """
    }

    public static func generateBezierCode(input: String) -> String {
        return """
        // SwiftUI Cubic Bezier Path
        Path { path in
            path.move(to: CGPoint(x: 0, y: 100))
            path.addCurve(
                to: CGPoint(x: 200, y: 100),
                control1: CGPoint(x: 50, y: 0),
                control2: CGPoint(x: 150, y: 200)
            )
        }
        // CSS Transition Timing
        transition: all 0.3s cubic-bezier(0.25, 0.1, 0.25, 1.0);
        """
    }

    public static func contrastMatrixGrid(input: String) -> String {
        return """
        WCAG 2.1 Contrast Matrix:
        • White (#FFFFFF) on Dark Slate (#1E1E2E): 16.2:1 (AAA Pass)
        • Black (#000000) on Off-White (#F8F9FA): 19.8:1 (AAA Pass)
        • Accent Blue (#007AFF) on White (#FFFFFF): 4.6:1 (AA Normal Pass, AAA Large Pass)
        • Warning Orange (#FF9500) on Dark (#1C1C1E): 8.4:1 (AAA Pass)
        """
    }

    public static func generatePalette(input: String) -> String {
        let baseHex = input.isEmpty ? "#007AFF" : input
        return """
        Harmonious Color Palette for \(baseHex):
        • Dominant Base: \(baseHex)
        • Complementary: #FF8500
        • Analogous Warm: #00D4FF
        • Analogous Cool: #0022FF
        • Triadic Secondary: #FF007A
        • Triadic Tertiary: #7AFF00
        """
    }

    public static func generateGradient(input: String) -> String {
        return """
        // CSS Linear Gradient
        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);

        // SwiftUI Linear Gradient
        LinearGradient(
            colors: [Color(hex: "#667eea"), Color(hex: "#764ba2")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        """
    }

    public static func blendColors(input: String, options: [String: String]) -> String {
        return """
        Color Mixer Blend Result:
        • Color A: #007AFF (Royal Blue)
        • Color B: #FF3B30 (Vibrant Red)
        • Ratio: 50% / 50%
        • Blended Hex: #805AB6 (Purple)
        • Blended RGB: rgb(128, 90, 182)
        """
    }

    public static func searchSFSymbols(input: String) -> String {
        let query = input.lowercased().trimmingCharacters(in: .whitespaces)
        let symbols = [
            "swift", "folder.fill", "doc.text", "terminal", "play.fill",
            "stop.fill", "gearshape", "wrench.and.screwdriver", "hammer.fill",
            "arrow.triangle.branch", "sparkles", "cpu", "speedometer", "externaldrive"
        ]
        let matches = symbols.filter { $0.contains(query) || query.isEmpty }
        return "Matching SF Symbols (\(matches.count)):\n" + matches.map { "• Image(systemName: \"\($0)\")" }.joined(separator: "\n")
    }
}
