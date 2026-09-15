//
//  XcodeGenService.swift
//  CodeEdit
//
//

// swiftlint:disable file_length type_body_length line_length

import Foundation

/// Service for detecting, installing via Homebrew, and generating .xcodeproj files using XcodeGen.
public actor XcodeGenService {
    public static let shared = XcodeGenService()

    private init() {}

    /// Checks whether `xcodegen` CLI is installed on the host system.
    public func isXcodeGenInstalled() -> Bool {
        if FileManager.default.fileExists(atPath: "/opt/homebrew/bin/xcodegen") ||
            FileManager.default.fileExists(atPath: "/usr/local/bin/xcodegen") ||
            FileManager.default.fileExists(atPath: "/usr/bin/xcodegen") {
            return true
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = ["xcodegen"]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()

        guard (try? process.run()) != nil else { return false }
        process.waitUntilExit()
        return process.terminationStatus == 0
    }

    /// Finds the absolute path to the Homebrew binary if installed.
    public func getHomebrewPath() -> String? {
        let candidates = [
            "/opt/homebrew/bin/brew",
            "/usr/local/bin/brew"
        ]
        for candidate in candidates where FileManager.default.fileExists(atPath: candidate) {
            return candidate
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = ["brew"]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()

        if (try? process.run()) != nil {
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()
            if process.terminationStatus == 0, let str = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines), !str.isEmpty {
                return str
            }
        }

        return nil
    }

    /// Finds the absolute path to the XcodeGen binary.
    public func getXcodeGenPath() -> String {
        let candidates = [
            "/opt/homebrew/bin/xcodegen",
            "/usr/local/bin/xcodegen",
            "/usr/bin/xcodegen"
        ]
        for candidate in candidates where FileManager.default.fileExists(atPath: candidate) {
            return candidate
        }
        return "xcodegen"
    }

    /// Installs XcodeGen via Homebrew asynchronously.
    public func installXcodeGenViaHomebrew(onProgress: @escaping @Sendable (String) -> Void) async throws {
        guard let brewPath = getHomebrewPath() else {
            throw NSError(
                domain: "XcodeGenService",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Homebrew was not found on your system. Please install Homebrew from https://brew.sh first."]
            )
        }

        onProgress("Running brew install xcodegen...")

        let process = Process()
        process.executableURL = URL(fileURLWithPath: brewPath)
        process.arguments = ["install", "xcodegen"]

        var env = ProcessInfo.processInfo.environment
        env["HOMEBREW_NO_AUTO_UPDATE"] = "1"
        process.environment = env

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        try process.run()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()

        let output = String(data: data, encoding: .utf8) ?? ""
        if process.terminationStatus != 0 {
            throw NSError(
                domain: "XcodeGenService",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "Failed to install xcodegen via Homebrew:\n\(output)"]
            )
        }

        onProgress("XcodeGen installation completed successfully.")
    }

    /// Generates .xcodeproj using XcodeGen with a temporary project.yml that is deleted immediately after generation.
    public func generateXcodeProject(
        destinationURL: URL,
        projectName: String,
        bundleID: String,
        appVersion: String,
        buildNumber: String,
        platform: String
    ) async throws {
        let tempProjectYmlURL = destinationURL.appendingPathComponent("project.yml")

        // Ensure temp project.yml is deleted when leaving scope
        defer {
            try? FileManager.default.removeItem(at: tempProjectYmlURL)
        }

        let prefix = bundleID.contains(".") ? bundleID.components(separatedBy: ".").dropLast().joined(separator: ".") : "com.example"

        let targetPlatform: String
        let deploymentTarget: String
        switch platform.lowercased() {
        case "ios":
            targetPlatform = "iOS"
            deploymentTarget = "16.0"
        case "watchos":
            targetPlatform = "watchOS"
            deploymentTarget = "9.0"
        case "visionos":
            targetPlatform = "visionOS"
            deploymentTarget = "1.0"
        case "tvos":
            targetPlatform = "tvOS"
            deploymentTarget = "16.0"
        default:
            targetPlatform = "macOS"
            deploymentTarget = "13.0"
        }

        let yamlContent = """
name: \(projectName)
options:
  bundleIdPrefix: \(prefix)
  deploymentTarget:
    \(targetPlatform): "\(deploymentTarget)"
targets:
  \(projectName):
    type: application
    platform: \(targetPlatform)
    deploymentTarget: "\(deploymentTarget)"
    sources:
      - path: .
        excludes:
          - "project.yml"
          - "*.xcodeproj"
          - "*.xcworkspace"
          - "Package.swift"
          - "Package.resolved"
          - "README.md"
          - ".git"
    settings:
      PRODUCT_BUNDLE_IDENTIFIER: \(bundleID)
      MARKETING_VERSION: \(appVersion)
      CURRENT_PROJECT_VERSION: \(buildNumber)
      GENERATE_INFOPLIST_FILE: YES
"""

        try yamlContent.write(to: tempProjectYmlURL, atomically: true, encoding: .utf8)

        let xcodegenExecutable = getXcodeGenPath()
        let process = Process()
        if xcodegenExecutable.hasPrefix("/") {
            process.executableURL = URL(fileURLWithPath: xcodegenExecutable)
            process.arguments = ["generate"]
        } else {
            process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            process.arguments = ["xcodegen", "generate"]
        }
        process.currentDirectoryURL = destinationURL

        var env = ProcessInfo.processInfo.environment
        env["PATH"] = "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:" + (env["PATH"] ?? "")
        process.environment = env

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        try process.run()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()

        let output = String(data: data, encoding: .utf8) ?? ""
        guard process.terminationStatus == 0 else {
            throw NSError(
                domain: "XcodeGenService",
                code: 3,
                userInfo: [NSLocalizedDescriptionKey: "XcodeGen failed to generate .xcodeproj:\n\(output)"]
            )
        }
    }
}
