//
//  PBXModels.swift
//  CodeEdit
//
//  Created by Austin Condiff on 14/09/26.
//

import SwiftUI

// MARK: - Project Model

struct PBXProjectModel: Identifiable {
    var id: String
    var name: String
    var targets: [PBXTargetModel]
    var configurations: [XCBuildConfigurationModel]
    var compatibilityVersion: String
    var developmentRegion: String
    var knownRegions: [String]
    var attributes: [String: Any]

    init(
        id: String = UUID().uuidString,
        name: String = "Project",
        targets: [PBXTargetModel] = [],
        configurations: [XCBuildConfigurationModel] = [],
        compatibilityVersion: String = "Xcode 14.0",
        developmentRegion: String = "en",
        knownRegions: [String] = ["en", "Base"],
        attributes: [String: Any] = [:]
    ) {
        self.id = id
        self.name = name
        self.targets = targets
        self.configurations = configurations
        self.compatibilityVersion = compatibilityVersion
        self.developmentRegion = developmentRegion
        self.knownRegions = knownRegions
        self.attributes = attributes
    }
}

// MARK: - Target Model

struct PBXTargetModel: Identifiable, Hashable {
    var id: String
    var name: String
    var productName: String
    var productType: String
    var configurations: [XCBuildConfigurationModel]
    var buildPhases: [PBXBuildPhaseModel]
    var buildRules: [PBXBuildRuleModel]
    var dependencies: [String]

    init(
        id: String,
        name: String,
        productName: String = "",
        productType: String = "com.apple.product-type.application",
        configurations: [XCBuildConfigurationModel] = [],
        buildPhases: [PBXBuildPhaseModel] = [],
        buildRules: [PBXBuildRuleModel] = [],
        dependencies: [String] = []
    ) {
        self.id = id
        self.name = name
        self.productName = productName.isEmpty ? name : productName
        self.productType = productType
        self.configurations = configurations
        self.buildPhases = buildPhases
        self.buildRules = buildRules
        self.dependencies = dependencies
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: PBXTargetModel, rhs: PBXTargetModel) -> Bool {
        lhs.id == rhs.id
    }

    var targetIcon: String {
        if productType.contains("application") {
            return "app.badge"
        } else if productType.contains("framework") {
            return "shippingbox"
        } else if productType.contains("unit-test") || productType.contains("ui-testing") {
            return "testtube.2"
        } else if productType.contains("tool") {
            return "terminal"
        } else if productType.contains("extension") {
            return "puzzlepiece.extension"
        } else {
            return "cube"
        }
    }

    var targetTypeDescription: String {
        if productType.contains("application") {
            return "Application"
        } else if productType.contains("framework") {
            return "Framework"
        } else if productType.contains("unit-test") {
            return "Unit Test Bundle"
        } else if productType.contains("ui-testing") {
            return "UI Test Bundle"
        } else if productType.contains("tool") {
            return "Command Line Tool"
        } else if productType.contains("extension") {
            return "App Extension"
        } else {
            return "Target"
        }
    }
}

// MARK: - Build Configuration

struct XCBuildConfigurationModel: Identifiable, Hashable {
    var id: String
    var name: String
    var buildSettings: [String: String]

    init(id: String, name: String, buildSettings: [String: String] = [:]) {
        self.id = id
        self.name = name
        self.buildSettings = buildSettings
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: XCBuildConfigurationModel, rhs: XCBuildConfigurationModel) -> Bool {
        lhs.id == rhs.id
    }

    func value(for key: String) -> String {
        buildSettings[key] ?? ""
    }
}

// MARK: - Build Phase

enum PBXBuildPhaseType: String, CaseIterable {
    case sources = "Compile Sources"
    case frameworks = "Link Binary With Libraries"
    case resources = "Copy Bundle Resources"
    case headers = "Headers"
    case runScript = "Run Script"
    case copyFiles = "Copy Files"

    var icon: String {
        switch self {
        case .sources: return "doc.text.fill"
        case .frameworks: return "link"
        case .resources: return "folder.fill"
        case .headers: return "h.square"
        case .runScript: return "applescript"
        case .copyFiles: return "doc.on.doc"
        }
    }
}

struct PBXBuildFileModel: Identifiable, Hashable {
    var id: String
    var name: String
    var path: String
    var compilerFlags: String

    init(id: String, name: String, path: String = "", compilerFlags: String = "") {
        self.id = id
        self.name = name
        self.path = path
        self.compilerFlags = compilerFlags
    }
}

struct PBXBuildPhaseModel: Identifiable, Hashable {
    var id: String
    var name: String
    var type: PBXBuildPhaseType
    var files: [PBXBuildFileModel]
    var shellPath: String
    var shellScript: String
    var inputPaths: [String]
    var outputPaths: [String]

    init(
        id: String,
        name: String,
        type: PBXBuildPhaseType,
        files: [PBXBuildFileModel] = [],
        shellPath: String = "/bin/sh",
        shellScript: String = "",
        inputPaths: [String] = [],
        outputPaths: [String] = []
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.files = files
        self.shellPath = shellPath
        self.shellScript = shellScript
        self.inputPaths = inputPaths
        self.outputPaths = outputPaths
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: PBXBuildPhaseModel, rhs: PBXBuildPhaseModel) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Build Rule

struct PBXBuildRuleModel: Identifiable, Hashable {
    var id: String
    var name: String
    var fileType: String
    var compilerSpec: String
    var script: String
    var outputFiles: [String]

    init(
        id: String,
        name: String = "Custom Rule",
        fileType: String = "pattern.proxy",
        compilerSpec: String = "com.apple.compilers.proxy.script",
        script: String = "",
        outputFiles: [String] = []
    ) {
        self.id = id
        self.name = name
        self.fileType = fileType
        self.compilerSpec = compilerSpec
        self.script = script
        self.outputFiles = outputFiles
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: PBXBuildRuleModel, rhs: PBXBuildRuleModel) -> Bool {
        lhs.id == rhs.id
    }
}
