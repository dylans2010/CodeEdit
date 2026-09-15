//
//  PathTraversalSanitizer.swift
//  CodeEdit
//

import Foundation

public enum PathSecurityError: LocalizedError, Sendable {
    case invalidPath(String)
    case pathOutOfBounds(String)
    case nullByteDetected(String)
    case symlinkCycleDetected(String)

    public var errorDescription: String? {
        switch self {
        case .invalidPath(let path):
            return "Security violation: Invalid path resolution for '\(path)'."
        case .pathOutOfBounds(let path):
            return "Security violation: Path '\(path)' resolves outside the allowed project root."
        case .nullByteDetected(let path):
            return "Security violation: Null byte detected in path '\(path)'."
        case .symlinkCycleDetected(let path):
            return "Security violation: Potential symlink cycle detected for '\(path)'."
        }
    }
}

/// Sanitizes file and directory paths against directory traversal attacks,
/// symlink escaping, and null byte injection.
public enum PathTraversalSanitizer: Sendable {

    /// Sanitizes an input relative or absolute path against a base project root URL.
    /// - Parameters:
    ///   - rawPath: The path to sanitize (may contain relative components).
    ///   - rootURL: The project root directory URL that paths must remain bounded within.
    /// - Returns: A canonical, sanitized URL guaranteed to reside inside or equal to the root.
    public static func sanitize(path rawPath: String, relativeTo rootURL: URL) throws -> URL {
        // 1. Check for null byte injection
        if rawPath.contains("\0") {
            throw PathSecurityError.nullByteDetected(rawPath)
        }

        let standardRoot = rootURL.resolvingSymlinksInPath().standardizedFileURL
        let combinedURL: URL

        if rawPath.hasPrefix("/") {
            // Absolute path: check if it starts with the root path
            combinedURL = URL(fileURLWithPath: rawPath)
        } else {
            // Relative path: resolve against root URL
            combinedURL = standardRoot.appendingPathComponent(rawPath)
        }

        let canonicalURL = combinedURL.resolvingSymlinksInPath().standardizedFileURL

        // Verify that canonical path starts with standard project root path
        let rootPath = standardRoot.path
        let targetPath = canonicalURL.path

        if targetPath == rootPath {
            return canonicalURL
        }

        let prefix = rootPath.hasSuffix("/") ? rootPath : rootPath + "/"
        guard targetPath.hasPrefix(prefix) else {
            throw PathSecurityError.pathOutOfBounds(rawPath)
        }

        return canonicalURL
    }

    /// Verifies if a given path is safe without throwing.
    public static func isPathSafe(_ rawPath: String, relativeTo rootURL: URL) -> Bool {
        do {
            _ = try sanitize(path: rawPath, relativeTo: rootURL)
            return true
        } catch {
            return false
        }
    }
}
