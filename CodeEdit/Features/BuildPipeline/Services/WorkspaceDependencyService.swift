//
//  WorkspaceDependencyService.swift
//  CodeEdit
//
//

// swiftlint:disable file_length type_body_length line_length identifier_name

import Foundation

/// Origin of a package dependency.
public enum DependencyOrigin: String, Codable, Sendable {
    case packageSwift = "Package.swift"
    case xcodeProject = "Xcode Project"
    case resolved = "Package.resolved"
}

/// Represents a scanned package dependency across SwiftPM or Xcode projects.
public struct ScannedDependencyItem: Hashable, Identifiable, Sendable {
    public var id: String { "\(origin.rawValue):\(name):\(urlOrPath)" }
    public let name: String
    public let versionOrRequirement: String
    public let urlOrPath: String
    public let origin: DependencyOrigin
    public let resolvedVersion: String?

    public init(
        name: String,
        versionOrRequirement: String,
        urlOrPath: String,
        origin: DependencyOrigin,
        resolvedVersion: String? = nil
    ) {
        self.name = name
        self.versionOrRequirement = versionOrRequirement
        self.urlOrPath = urlOrPath
        self.origin = origin
        self.resolvedVersion = resolvedVersion
    }
}

// swiftlint:disable type_body_length
/// Service to discover, audit, and append package dependencies.
public actor WorkspaceDependencyService {
    public static let shared = WorkspaceDependencyService()

    private init() {}

    /// Scans the given workspace directory for dependencies across Package.swift, Xcode projects, and Package.resolved.
    public func scanDependencies(in workspaceURL: URL) async -> [ScannedDependencyItem] {
        var items: [ScannedDependencyItem] = []
        var resolvedDict: [String: String] = [:] // key: repo url or identity, value: resolved version

        // 1. Scan Package.resolved files first to map resolved versions
        let resolvedFiles = findResolvedFiles(in: workspaceURL)
        for resolvedURL in resolvedFiles {
            let pins = parsePackageResolved(at: resolvedURL)
            for pin in pins {
                if let ver = pin.version ?? pin.branch ?? pin.revision {
                    resolvedDict[pin.identity.lowercased()] = ver
                    if !pin.location.isEmpty {
                        resolvedDict[pin.location.lowercased()] = ver
                        let cleanLoc = pin.location.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
                        let lastPart = (cleanLoc as NSString).lastPathComponent.replacingOccurrences(of: ".git", with: "")
                        resolvedDict[lastPart.lowercased()] = ver
                    }
                }
            }
        }

        // 2. Scan Package.swift files
        let packageSwiftFiles = findPackageSwiftFiles(in: workspaceURL)
        for pkgURL in packageSwiftFiles {
            let pkgItems = parsePackageSwift(at: pkgURL, resolvedVersions: resolvedDict)
            items.append(contentsOf: pkgItems)
        }

        // 3. Scan Xcode projects (.xcodeproj / project.pbxproj)
        let xcodeProjects = findXcodeProjects(in: workspaceURL)
        for projURL in xcodeProjects {
            let pbxItems = parseXcodeProject(at: projURL, resolvedVersions: resolvedDict)
            items.append(contentsOf: pbxItems)
        }

        // 4. If no Package.swift or Xcode packages were found, fallback to pure resolved entries
        if items.isEmpty {
            for resolvedURL in resolvedFiles {
                let pins = parsePackageResolved(at: resolvedURL)
                for pin in pins {
                    let ver = pin.version ?? pin.branch ?? pin.revision ?? "resolved"
                    items.append(ScannedDependencyItem(
                        name: pin.identity,
                        versionOrRequirement: ver,
                        urlOrPath: pin.location,
                        origin: .resolved,
                        resolvedVersion: ver
                    ))
                }
            }
        }

        // De-duplicate items by id
        var seen = Set<String>()
        return items.filter { item in
            if seen.contains(item.id) {
                return false
            }
            seen.insert(item.id)
            return true
        }
    }

    // MARK: - Package.swift Parsing

    private func findPackageSwiftFiles(in rootURL: URL) -> [URL] {
        var results: [URL] = []
        let rootPkg = rootURL.appendingPathComponent("Package.swift")
        if FileManager.default.fileExists(atPath: rootPkg.path) {
            results.append(rootPkg)
        }

        if let enumerator = FileManager.default.enumerator(
            at: rootURL,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) {
            for case let fileURL as URL in enumerator {
                if fileURL.lastPathComponent == "Package.swift" && fileURL.path != rootPkg.path {
                    results.append(fileURL)
                }
            }
        }
        return results
    }

    private func parsePackageSwift(at url: URL, resolvedVersions: [String: String]) -> [ScannedDependencyItem] {
        guard let content = try? String(contentsOf: url, encoding: .utf8) else { return [] }
        var results: [ScannedDependencyItem] = []

        // Match .package(...) patterns:
        // .package(url: "https://...", from: "1.0.0")
        // .package(url: "https://...", exact: "1.0.0")
        // .package(url: "https://...", branch: "main")
        // .package(url: "https://...", "1.0.0"..<"2.0.0")
        // .package(path: "../Local")
        let pattern = #"\.package\s*\(\s*(?:name:\s*"([^"]+)",\s*)?(?:url|path)\s*:\s*"([^"]+)"(?:\s*,\s*([^)]+))?\)"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return [] }

        let nsContent = content as NSString
        let matches = regex.matches(in: content, options: [], range: NSRange(location: 0, length: nsContent.length))

        for match in matches {
            var explicitName: String?
            if match.range(at: 1).location != NSNotFound {
                explicitName = nsContent.substring(with: match.range(at: 1))
            }

            let urlOrPath = nsContent.substring(with: match.range(at: 2))
            var requirementStr = "latest"

            if match.numberOfRanges >= 4 && match.range(at: 3).location != NSNotFound {
                let reqRaw = nsContent.substring(with: match.range(at: 3))
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                requirementStr = cleanRequirement(reqRaw)
            }

            let name: String
            if let explicit = explicitName, !explicit.isEmpty {
                name = explicit
            } else {
                let lastPart = (urlOrPath as NSString).lastPathComponent
                name = lastPart.replacingOccurrences(of: ".git", with: "")
            }

            let resolved = resolvedVersions[name.lowercased()] ?? resolvedVersions[urlOrPath.lowercased()]

            results.append(ScannedDependencyItem(
                name: name,
                versionOrRequirement: requirementStr,
                urlOrPath: urlOrPath,
                origin: .packageSwift,
                resolvedVersion: resolved
            ))
        }

        return results
    }

    private func cleanRequirement(_ raw: String) -> String {
        var clean = raw.replacingOccurrences(of: "\"", with: "")
        clean = clean.replacingOccurrences(of: ":", with: " ")
        clean = clean.replacingOccurrences(of: "  ", with: " ")
        return clean.trimmingCharacters(in: .whitespaces)
    }

    // MARK: - Xcode Project Parsing

    private func findXcodeProjects(in rootURL: URL) -> [URL] {
        var results: [URL] = []
        if rootURL.pathExtension == "xcodeproj" {
            results.append(rootURL)
        }

        if let contents = try? FileManager.default.contentsOfDirectory(
            at: rootURL,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) {
            for item in contents where item.pathExtension == "xcodeproj" {
                results.append(item)
            }
        }
        return results
    }

    private func parseXcodeProject(at projectURL: URL, resolvedVersions: [String: String]) -> [ScannedDependencyItem] {
        let pbxURL = projectURL.appendingPathComponent("project.pbxproj")
        guard let pbxContent = try? String(contentsOf: pbxURL, encoding: .utf8) else { return [] }

        var results: [ScannedDependencyItem] = []

        let blockPattern = #"(?:\/\*\s*XCRemoteSwiftPackageReference\s*"([^"]+)"\s*\*\/|\w+)\s*=\s*\{[^}]*?"#
            + #"isa\s*=\s*XCRemoteSwiftPackageReference;[\s\S]*?"#
            + #"repositoryURL\s*=\s*"([^"]+)";[\s\S]*?"#
            + #"requirement\s*=\s*\{([\s\S]*?)\};[\s\S]*?\};"#
        guard let regex = try? NSRegularExpression(pattern: blockPattern, options: []) else { return [] }

        let nsContent = pbxContent as NSString
        let matches = regex.matches(in: pbxContent, options: [], range: NSRange(location: 0, length: nsContent.length))

        for match in matches {
            var name = ""
            if match.range(at: 1).location != NSNotFound {
                name = nsContent.substring(with: match.range(at: 1))
            }
            let repoURL = nsContent.substring(with: match.range(at: 2))
            if name.isEmpty {
                name = (repoURL as NSString).lastPathComponent.replacingOccurrences(of: ".git", with: "")
            }

            var requirement = "Package Dependency"
            if match.numberOfRanges >= 4 && match.range(at: 3).location != NSNotFound {
                let reqBlock = nsContent.substring(with: match.range(at: 3))
                requirement = parsePBXRequirement(reqBlock)
            }

            let resolved = resolvedVersions[name.lowercased()] ?? resolvedVersions[repoURL.lowercased()]

            results.append(ScannedDependencyItem(
                name: name,
                versionOrRequirement: requirement,
                urlOrPath: repoURL,
                origin: .xcodeProject,
                resolvedVersion: resolved
            ))
        }

        return results
    }

    private func parsePBXRequirement(_ block: String) -> String {
        var kind = ""
        var ver = ""

        let lines = block.components(separatedBy: .newlines)
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.contains("kind =") {
                kind = trimmed.replacingOccurrences(of: "kind =", with: "")
                    .replacingOccurrences(of: ";", with: "")
                    .trimmingCharacters(in: .whitespaces)
            } else if trimmed.contains("version =") || trimmed.contains("minimumVersion =") {
                ver = trimmed.replacingOccurrences(of: "version =", with: "")
                    .replacingOccurrences(of: "minimumVersion =", with: "")
                    .replacingOccurrences(of: ";", with: "")
                    .trimmingCharacters(in: .whitespaces)
            } else if trimmed.contains("branch =") {
                ver = trimmed.replacingOccurrences(of: "branch =", with: "")
                    .replacingOccurrences(of: ";", with: "")
                    .trimmingCharacters(in: .whitespaces)
            }
        }

        if !ver.isEmpty {
            if kind == "upToNextMajorVersion" {
                return "from \(ver)"
            } else if kind == "exactVersion" {
                return "exact \(ver)"
            } else if kind == "branch" {
                return "branch \(ver)"
            }
            return ver
        }
        return kind.isEmpty ? "configured" : kind
    }

    // MARK: - Package.resolved Scanning

    private func findResolvedFiles(in rootURL: URL) -> [URL] {
        var results: [URL] = []
        let candidates = [
            rootURL.appendingPathComponent("Package.resolved"),
            rootURL.appendingPathComponent(".swiftpm/xcode/package.resolved"),
            rootURL.appendingPathComponent("CodeEdit.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved")
        ]

        for candidate in candidates where FileManager.default.fileExists(atPath: candidate.path) {
            results.append(candidate)
        }

        // Also check any .xcodeproj inside rootURL
        if let contents = try? FileManager.default.contentsOfDirectory(
            at: rootURL,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) {
            for item in contents where item.pathExtension == "xcodeproj" {
                let resolvedPath = item.appendingPathComponent("project.xcworkspace/xcshareddata/swiftpm/Package.resolved")
                if FileManager.default.fileExists(atPath: resolvedPath.path) && !results.contains(resolvedPath) {
                    results.append(resolvedPath)
                }
            }
        }

        return results
    }

    private func parsePackageResolved(at url: URL) -> [PinnedPackageDependency] {
        guard let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return []
        }

        var results: [PinnedPackageDependency] = []
        if let pins = json["pins"] as? [[String: Any]] {
            for pin in pins {
                let identity = (pin["identity"] as? String) ?? (pin["package"] as? String) ?? "unknown"
                let location = (pin["location"] as? String) ?? (pin["repositoryURL"] as? String) ?? ""
                let state = pin["state"] as? [String: Any]
                let version = state?["version"] as? String
                let revision = state?["revision"] as? String
                let branch = state?["branch"] as? String

                results.append(PinnedPackageDependency(
                    identity: identity,
                    location: location,
                    version: version,
                    revision: revision,
                    branch: branch
                ))
            }
        } else if let object = json["object"] as? [String: Any],
                  let pins = object["pins"] as? [[String: Any]] {
            for pin in pins {
                let package = (pin["package"] as? String) ?? "unknown"
                let repositoryURL = (pin["repositoryURL"] as? String) ?? ""
                let state = pin["state"] as? [String: Any]
                let version = state?["version"] as? String
                let revision = state?["revision"] as? String
                let branch = state?["branch"] as? String

                results.append(PinnedPackageDependency(
                    identity: package,
                    location: repositoryURL,
                    version: version,
                    revision: revision,
                    branch: branch
                ))
            }
        }
        return results
    }

    // MARK: - Adding Packages

    /// Adds a Swift package dependency to the workspace.
    public func addPackageDependency(
        workspaceURL: URL,
        packageURL: String,
        requirementType: String,
        requirementValue: String
    ) async throws {
        let trimmedURL = packageURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedURL.isEmpty else {
            throw NSError(domain: "WorkspaceDependencyService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Package URL cannot be empty."])
        }

        let pkgSwiftURL = workspaceURL.appendingPathComponent("Package.swift")
        if FileManager.default.fileExists(atPath: pkgSwiftURL.path) {
            try addDependencyToPackageSwift(
                at: pkgSwiftURL,
                url: trimmedURL,
                type: requirementType,
                value: requirementValue
            )
            // Trigger background resolution
            Task {
                _ = try? await CommandRunner.execute(command: "swift package resolve", in: workspaceURL)
            }
            return
        }

        // Try finding Xcode project
        let xcodeProjects = findXcodeProjects(in: workspaceURL)
        if let firstProj = xcodeProjects.first {
            try addDependencyToXcodeProject(
                at: firstProj,
                url: trimmedURL,
                type: requirementType,
                value: requirementValue
            )
            return
        }

        throw NSError(
            domain: "WorkspaceDependencyService",
            code: 404,
            userInfo: [NSLocalizedDescriptionKey: "No Package.swift or Xcode project found in workspace to add dependency."]
        )
    }

    private func addDependencyToPackageSwift(
        at fileURL: URL,
        url: String,
        type: String,
        value: String
    ) throws {
        var content = try String(contentsOf: fileURL, encoding: .utf8)
        let depSnippet: String
        switch type {
        case "Exact Version":
            depSnippet = ".package(url: \"\(url)\", exact: \"\(value)\")"
        case "Branch":
            depSnippet = ".package(url: \"\(url)\", branch: \"\(value)\")"
        default: // "Up to Next Major"
            depSnippet = ".package(url: \"\(url)\", from: \"\(value)\")"
        }

        // Find dependencies: [
        if let range = content.range(of: "dependencies: [") {
            let insertPos = content.index(range.upperBound, offsetBy: 0)
            content.insert(contentsOf: "\n        \(depSnippet),", at: insertPos)
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
        } else if let range = content.range(of: "dependencies:[") {
            let insertPos = content.index(range.upperBound, offsetBy: 0)
            content.insert(contentsOf: "\n        \(depSnippet),", at: insertPos)
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
        } else {
            throw NSError(
                domain: "WorkspaceDependencyService",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "Could not locate 'dependencies: [' in Package.swift"]
            )
        }
    }

    private func addDependencyToXcodeProject(
        at projectURL: URL,
        url: String,
        type: String,
        value: String
    ) throws {
        let pbxURL = projectURL.appendingPathComponent("project.pbxproj")
        var content = try String(contentsOf: pbxURL, encoding: .utf8)

        let pkgName = (url as NSString).lastPathComponent.replacingOccurrences(of: ".git", with: "")
        let refUUID = generatePBXUUID()

        let kind: String
        let verAttr: String
        switch type {
        case "Exact Version":
            kind = "exactVersion"
            verAttr = "version = \(value);"
        case "Branch":
            kind = "branch"
            verAttr = "branch = \(value);"
        default:
            kind = "upToNextMajorVersion"
            verAttr = "minimumVersion = \(value);"
        }

        let newRefBlock = """
\t\t\(refUUID) /* XCRemoteSwiftPackageReference "\(pkgName)" */ = {
\t\t\tisa = XCRemoteSwiftPackageReference;
\t\t\trepositoryURL = "\(url)";
\t\t\trequirement = {
\t\t\t\tkind = \(kind);
\t\t\t\t\(verAttr)
\t\t\t};
\t\t};
"""

        if let sectionRange = content.range(of: "/* Begin XCRemoteSwiftPackageReference section */") {
            let insertPos = sectionRange.upperBound
            content.insert(contentsOf: "\n" + newRefBlock, at: insertPos)
            try content.write(to: pbxURL, atomically: true, encoding: .utf8)
        } else if let rootObjRange = content.range(of: "objects = {") {
            let sectionWrapper = """

/* Begin XCRemoteSwiftPackageReference section */
\(newRefBlock)
/* End XCRemoteSwiftPackageReference section */
"""
            let insertPos = rootObjRange.upperBound
            content.insert(contentsOf: sectionWrapper, at: insertPos)
            try content.write(to: pbxURL, atomically: true, encoding: .utf8)
        } else {
            throw NSError(
                domain: "WorkspaceDependencyService",
                code: 3,
                userInfo: [NSLocalizedDescriptionKey: "Unable to parse project.pbxproj objects dictionary."]
            )
        }
    }

    private func generatePBXUUID() -> String {
        UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(24).uppercased()
    }
}
