//
//  PBXProjParser.swift
//  CodeEdit
//
//  Created by Austin Condiff on 14/09/26.
//

import Foundation

enum PBXProjParserError: Error {
    case invalidData
    case missingRootObject
}

final class PBXProjParser {
    static let shared = PBXProjParser()

    func parse(data: Data) throws -> PBXProjectModel {
        guard let plist = try PropertyListSerialization.propertyList(
            from: data,
            options: [],
            format: nil
        ) as? [String: Any] else {
            throw PBXProjParserError.invalidData
        }

        guard let objects = plist["objects"] as? [String: [String: Any]],
              let rootObjectId = plist["rootObject"] as? String,
              let rootDict = objects[rootObjectId] else {
            throw PBXProjParserError.missingRootObject
        }

        let projectName = (rootDict["name"] as? String) ?? "Project"
        let compatibilityVersion = (rootDict["compatibilityVersion"] as? String) ?? "Xcode 14.0"
        let developmentRegion = (rootDict["developmentRegion"] as? String) ?? "en"
        let knownRegions = (rootDict["knownRegions"] as? [String]) ?? ["en", "Base"]
        let attributes = (rootDict["attributes"] as? [String: Any]) ?? [:]

        let projectConfigs = parseConfigurations(
            configListId: rootDict["buildConfigurationList"] as? String,
            objects: objects
        )

        let targetIds = (rootDict["targets"] as? [String]) ?? []
        let targets = targetIds.compactMap { targetId -> PBXTargetModel? in
            guard let targetDict = objects[targetId] else { return nil }
            return parseTarget(id: targetId, dict: targetDict, objects: objects)
        }

        return PBXProjectModel(
            id: rootObjectId,
            name: projectName,
            targets: targets,
            configurations: projectConfigs,
            compatibilityVersion: compatibilityVersion,
            developmentRegion: developmentRegion,
            knownRegions: knownRegions,
            attributes: attributes
        )
    }

    private func parseTarget(
        id: String,
        dict: [String: Any],
        objects: [String: [String: Any]]
    ) -> PBXTargetModel {
        let name = (dict["name"] as? String) ?? "Target"
        let productName = (dict["productName"] as? String) ?? name
        let productType = (dict["productType"] as? String) ?? "com.apple.product-type.application"

        let configs = parseConfigurations(
            configListId: dict["buildConfigurationList"] as? String,
            objects: objects
        )
        let buildPhases = parseBuildPhases(
            phaseIds: dict["buildPhases"] as? [String] ?? [],
            objects: objects
        )
        let buildRules = parseBuildRules(
            ruleIds: dict["buildRules"] as? [String] ?? [],
            objects: objects
        )
        let dependencies = parseDependencies(
            depIds: dict["dependencies"] as? [String] ?? [],
            objects: objects
        )

        return PBXTargetModel(
            id: id,
            name: name,
            productName: productName,
            productType: productType,
            configurations: configs,
            buildPhases: buildPhases,
            buildRules: buildRules,
            dependencies: dependencies
        )
    }

    private func parseConfigurations(
        configListId: String?,
        objects: [String: [String: Any]]
    ) -> [XCBuildConfigurationModel] {
        guard let configListId = configListId,
              let configListDict = objects[configListId],
              let configIds = configListDict["buildConfigurations"] as? [String] else {
            return []
        }

        return configIds.compactMap { configId in
            guard let configDict = objects[configId] else { return nil }
            let name = (configDict["name"] as? String) ?? "Configuration"
            var settings: [String: String] = [:]
            if let rawSettings = configDict["buildSettings"] as? [String: Any] {
                for (key, val) in rawSettings {
                    if let stringVal = val as? String {
                        settings[key] = stringVal
                    } else if let arrayVal = val as? [String] {
                        settings[key] = arrayVal.joined(separator: " ")
                    } else {
                        settings[key] = "\(val)"
                    }
                }
            }
            return XCBuildConfigurationModel(id: configId, name: name, buildSettings: settings)
        }
    }

    private func parseBuildPhases(
        phaseIds: [String],
        objects: [String: [String: Any]]
    ) -> [PBXBuildPhaseModel] {
        return phaseIds.compactMap { phaseId in
            guard let phaseDict = objects[phaseId],
                  let isa = phaseDict["isa"] as? String else { return nil }

            let phaseType = mapBuildPhaseType(isa: isa)
            let defaultName = phaseType.rawValue
            let name = (phaseDict["name"] as? String) ?? defaultName

            let files = parseBuildFiles(
                fileIds: phaseDict["files"] as? [String] ?? [],
                objects: objects
            )
            let shellPath = (phaseDict["shellPath"] as? String) ?? "/bin/sh"
            let shellScript = (phaseDict["shellScript"] as? String) ?? ""
            let inputPaths = (phaseDict["inputPaths"] as? [String]) ?? []
            let outputPaths = (phaseDict["outputPaths"] as? [String]) ?? []

            return PBXBuildPhaseModel(
                id: phaseId,
                name: name,
                type: phaseType,
                files: files,
                shellPath: shellPath,
                shellScript: shellScript,
                inputPaths: inputPaths,
                outputPaths: outputPaths
            )
        }
    }

    private func mapBuildPhaseType(isa: String) -> PBXBuildPhaseType {
        switch isa {
        case "PBXSourcesBuildPhase": return .sources
        case "PBXFrameworksBuildPhase": return .frameworks
        case "PBXResourcesBuildPhase": return .resources
        case "PBXHeadersBuildPhase": return .headers
        case "PBXShellScriptBuildPhase": return .runScript
        case "PBXCopyFilesBuildPhase": return .copyFiles
        default: return .sources
        }
    }

    private func parseBuildFiles(
        fileIds: [String],
        objects: [String: [String: Any]]
    ) -> [PBXBuildFileModel] {
        return fileIds.compactMap { fileId in
            guard let buildFileDict = objects[fileId] else { return nil }
            let fileRefId = buildFileDict["fileRef"] as? String
            var fileName = "File"
            var filePath = ""

            if let refId = fileRefId, let fileRefDict = objects[refId] {
                fileName = (fileRefDict["path"] as? String) ?? (fileRefDict["name"] as? String) ?? "File"
                filePath = (fileRefDict["path"] as? String) ?? ""
            }

            let compilerFlags = (buildFileDict["settings"] as? [String: Any])?["COMPILER_FLAGS"] as? String ?? ""

            return PBXBuildFileModel(
                id: fileId,
                name: fileName,
                path: filePath,
                compilerFlags: compilerFlags
            )
        }
    }

    private func parseBuildRules(
        ruleIds: [String],
        objects: [String: [String: Any]]
    ) -> [PBXBuildRuleModel] {
        return ruleIds.compactMap { ruleId in
            guard let ruleDict = objects[ruleId] else { return nil }
            let name = (ruleDict["name"] as? String) ?? "Build Rule"
            let fileType = (ruleDict["fileType"] as? String) ?? "pattern.proxy"
            let compilerSpec = (ruleDict["compilerSpec"] as? String) ?? "com.apple.compilers.proxy.script"
            let script = (ruleDict["script"] as? String) ?? ""
            let outputFiles = (ruleDict["outputFiles"] as? [String]) ?? []

            return PBXBuildRuleModel(
                id: ruleId,
                name: name,
                fileType: fileType,
                compilerSpec: compilerSpec,
                script: script,
                outputFiles: outputFiles
            )
        }
    }

    private func parseDependencies(
        depIds: [String],
        objects: [String: [String: Any]]
    ) -> [String] {
        return depIds.compactMap { depId in
            guard let depDict = objects[depId] else { return nil }
            if let targetId = depDict["target"] as? String,
               let targetDict = objects[targetId] {
                return (targetDict["name"] as? String) ?? targetId
            }
            return depDict["name"] as? String
        }
    }
}
