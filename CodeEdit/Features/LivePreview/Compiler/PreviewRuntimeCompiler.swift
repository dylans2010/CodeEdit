//
//  PreviewRuntimeCompiler.swift
//  CodeEdit
//
//

import Foundation
import SwiftUI

/// Result of a dynamic SwiftUI preview compilation.
public struct PreviewCompilationResult: Sendable {
    public let isSuccess: Bool
    public let dylibURL: URL?
    public let errorMessage: String?
    public let compilationDuration: TimeInterval

    public init(
        isSuccess: Bool,
        dylibURL: URL? = nil,
        errorMessage: String? = nil,
        compilationDuration: TimeInterval = 0.0
    ) {
        self.isSuccess = isSuccess
        self.dylibURL = dylibURL
        self.errorMessage = errorMessage
        self.compilationDuration = compilationDuration
    }
}

/// Dynamic compiler compiling SwiftUI source files into JIT-loadable dylibs.
public actor PreviewRuntimeCompiler {
    public static let shared = PreviewRuntimeCompiler()

    private var loadedHandles: [URL: UnsafeMutableRawPointer] = [:]

    private init() {}

    /// Compiles a standalone SwiftUI file into a dynamic library.
    public func compileSwiftUIView(
        sourceFileURL: URL,
        buildProductsURL: URL? = nil
    ) async throws -> PreviewCompilationResult {
        let startTime = Date()
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("LivePreview-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        let dylibURL = tempDir.appendingPathComponent("libPreview_\(UUID().uuidString).dylib")

        var command = "swiftc -emit-library -dynamiclib -o \"\(dylibURL.path)\" \"\(sourceFileURL.path)\""
        if let productsURL = buildProductsURL {
            command += " -I \"\(productsURL.path)\" -L \"\(productsURL.path)\""
        }

        let result = try await CommandRunner.execute(command: command, in: tempDir)
        let duration = Date().timeIntervalSince(startTime)

        if result.exitCode == 0 && FileManager.default.fileExists(atPath: dylibURL.path) {
            DiagnosticEventBus.shared.logEvent(
                component: "PreviewRuntimeCompiler",
                severity: "INFO",
                category: "live_preview_compile",
                message: "Compiled preview dylib in \(String(format: "%.2f", duration))s"
            )
            return PreviewCompilationResult(
                isSuccess: true,
                dylibURL: dylibURL,
                compilationDuration: duration
            )
        } else {
            return PreviewCompilationResult(
                isSuccess: false,
                errorMessage: result.output,
                compilationDuration: duration
            )
        }
    }

    /// Loads the compiled dynamic library using `dlopen`.
    public func loadDynamicLibrary(at dylibURL: URL) throws {
        if let existing = loadedHandles[dylibURL] {
            dlclose(existing)
        }

        guard let handle = dlopen(dylibURL.path, RTLD_NOW | RTLD_GLOBAL) else {
            let errorString = String(cString: dlerror())
            throw NSError(
                domain: "PreviewRuntimeCompiler",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "dlopen failed: \(errorString)"]
            )
        }

        loadedHandles[dylibURL] = handle
    }
}
