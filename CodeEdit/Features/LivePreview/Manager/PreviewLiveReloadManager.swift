//
//  PreviewLiveReloadManager.swift
//  CodeEdit
//
//

import Foundation
import SwiftUI

/// Supported preview orientations.
public enum PreviewOrientation: String, CaseIterable, Sendable {
    case portrait = "Portrait"
    case landscape = "Landscape"
}

/// Dynamic Type scale level for live preview rendering.
public enum PreviewDynamicType: String, CaseIterable, Sendable {
    case xSmall = "Extra Small"
    case medium = "Medium"
    case large = "Large"
    case xxxLarge = "Accessibility XXXL"

    public var dynamicTypeSize: DynamicTypeSize {
        switch self {
        case .xSmall: return .xSmall
        case .medium: return .medium
        case .large: return .large
        case .xxxLarge: return .accessibility3
        }
    }
}

/// Manages live preview reloading, debounce state, and preview environment configurations.
@MainActor
public final class PreviewLiveReloadManager: ObservableObject {
    public static let shared = PreviewLiveReloadManager()

    @Published public var isColorSchemeDark: Bool = false
    @Published public var orientation: PreviewOrientation = .portrait
    @Published public var dynamicType: PreviewDynamicType = .medium
    @Published public var localeIdentifier: String = "en_US"
    @Published public var isCompiling: Bool = false
    @Published public var lastErrorMessage: String?
    @Published public var reloadCount: Int = 0

    private var pendingDebounceTask: Task<Void, Never>?
    private let debounceNanoseconds: UInt64 = 250_000_000 // 250ms debounce

    private init() {}

    /// Triggered whenever the active file is saved or mutated in the editor.
    public func onFileSaved(fileURL: URL) {
        guard fileURL.pathExtension == "swift" else { return }

        pendingDebounceTask?.cancel()
        pendingDebounceTask = Task { [weak self] in
            guard let self = self else { return }
            do {
                try await Task.sleep(nanoseconds: self.debounceNanoseconds)
                guard !Task.isCancelled else { return }
                await self.triggerRecompile(fileURL: fileURL)
            } catch {
                // Cancelled
            }
        }
    }

    /// Recompiles the modified SwiftUI view dynamically.
    public func triggerRecompile(fileURL: URL) async {
        self.isCompiling = true
        self.lastErrorMessage = nil

        do {
            let result = try await PreviewRuntimeCompiler.shared.compileSwiftUIView(sourceFileURL: fileURL)
            if result.isSuccess, let dylibURL = result.dylibURL {
                try await PreviewRuntimeCompiler.shared.loadDynamicLibrary(at: dylibURL)
                self.reloadCount += 1
            } else {
                self.lastErrorMessage = result.errorMessage ?? "Compilation failed."
            }
        } catch {
            self.lastErrorMessage = error.localizedDescription
        }

        self.isCompiling = false
    }

    /// Toggles color scheme between Light and Dark.
    public func toggleColorScheme() {
        isColorSchemeDark.toggle()
    }

    /// Toggles orientation between Portrait and Landscape.
    public func toggleOrientation() {
        orientation = (orientation == .portrait) ? .landscape : .portrait
    }
}
