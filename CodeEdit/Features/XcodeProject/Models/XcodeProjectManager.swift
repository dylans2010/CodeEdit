//
//  XcodeProjectManager.swift
//  CodeEdit
//
//  Created by Austin Condiff on 14/09/26.
//

import SwiftUI
import Combine

enum XcodeProjectTab: String, CaseIterable, Identifiable {
    case general = "General"
    case signing = "Signing"
    case capabilities = "Capabilities"
    case resourceTags = "Resource Tags"
    case info = "Info"
    case buildSettings = "Build Settings"
    case buildPhases = "Build Phases"
    case buildRules = "Build Rules"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .general: return "slider.horizontal.3"
        case .signing: return "signature"
        case .capabilities: return "switch.2"
        case .resourceTags: return "tag"
        case .info: return "info.circle"
        case .buildSettings: return "gearshape"
        case .buildPhases: return "hammer"
        case .buildRules: return "checklist"
        }
    }
}

enum BuildSettingsFilter: String, CaseIterable {
    case all = "All"
    case customized = "Customized"
}

final class XcodeProjectManager: ObservableObject {
    @Published var projectURL: URL
    @Published var project: PBXProjectModel?
    @Published var selectedTargetId: String?
    @Published var selectedTab: XcodeProjectTab = .general
    @Published var selectedConfigName: String = "Debug"
    @Published var buildSettingsSearchText: String = ""
    @Published var buildSettingsFilter: BuildSettingsFilter = .all
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    init(projectURL: URL) {
        self.projectURL = projectURL
        self.loadProject()
    }

    var effectivePbxURL: URL {
        if projectURL.hasDirectoryPath || projectURL.pathExtension == "xcodeproj" {
            let inner = projectURL.appendingPathComponent("project.pbxproj")
            if FileManager.default.fileExists(atPath: inner.path) {
                return inner
            }
        }
        return projectURL
    }

    func loadProject() {
        isLoading = true
        errorMessage = nil

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            do {
                let data = try Data(contentsOf: self.effectivePbxURL)
                let parsed = try PBXProjParser.shared.parse(data: data)
                DispatchQueue.main.async {
                    self.project = parsed
                    if self.selectedTargetId == nil {
                        self.selectedTargetId = parsed.targets.first?.id
                    }
                    if let firstTarget = parsed.targets.first,
                       let firstConfig = firstTarget.configurations.first {
                        self.selectedConfigName = firstConfig.name
                    }
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }

    var selectedTarget: PBXTargetModel? {
        guard let id = selectedTargetId else { return nil }
        return project?.targets.first(where: { $0.id == id })
    }

    var currentConfiguration: XCBuildConfigurationModel? {
        if let target = selectedTarget {
            return target.configurations.first(where: { $0.name == selectedConfigName })
                ?? target.configurations.first
        }
        return project?.configurations.first(where: { $0.name == selectedConfigName })
            ?? project?.configurations.first
    }

    func updateBuildSetting(key: String, value: String) {
        guard var prj = project else { return }
        if let targetId = selectedTargetId,
           let targetIndex = prj.targets.firstIndex(where: { $0.id == targetId }) {
            var target = prj.targets[targetIndex]
            if let configIndex = target.configurations.firstIndex(where: { $0.name == selectedConfigName }) {
                target.configurations[configIndex].buildSettings[key] = value
                prj.targets[targetIndex] = target
                self.project = prj
            }
        }
    }

    func getSetting(_ key: String, defaultValue: String = "") -> String {
        return currentConfiguration?.value(for: key) ?? defaultValue
    }
}
