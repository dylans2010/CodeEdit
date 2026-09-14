//
//  PropertyListManager.swift
//  CodeEdit
//
//  Created by Austin Condiff on 14/09/26.
//

import SwiftUI

enum PlistViewMode: String, CaseIterable {
    case propertyList = "Property List"
    case sourceCode = "Source Code"
}

final class PropertyListManager: ObservableObject {
    @Published var fileURL: URL
    @Published var rootNode: PlistNode
    @Published var viewMode: PlistViewMode = .propertyList
    @Published var searchText: String = ""
    @Published var rawContent: String = ""
    @Published var errorMessage: String?

    init(fileURL: URL, rawContent: String = "") {
        self.fileURL = fileURL
        self.rawContent = rawContent
        self.rootNode = PlistNode(key: "Root", type: .dictionary)
        self.load()
    }

    func load() {
        do {
            let data: Data
            if let contentData = rawContent.data(using: .utf8), !rawContent.isEmpty {
                data = contentData
            } else {
                data = try Data(contentsOf: fileURL)
                rawContent = String(data: data, encoding: .utf8) ?? ""
            }

            guard let plist = try PropertyListSerialization.propertyList(
                from: data,
                options: [],
                format: nil
            ) as? [String: Any] else {
                return
            }

            let sortedKeys = plist.keys.sorted()
            let children = sortedKeys.map { key in
                PlistNode.from(key: key, value: plist[key]!)
            }
            self.rootNode = PlistNode(key: "Root", type: .dictionary, children: children)
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }

    func saveToDisk() {
        let rootObj = rootNode.toObject()
        guard let dict = rootObj as? [String: Any] else { return }

        do {
            let data = try PropertyListSerialization.data(
                fromPropertyList: dict,
                format: .xml,
                options: 0
            )
            try data.write(to: fileURL)
            if let str = String(data: data, encoding: .utf8) {
                self.rawContent = str
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }

    func addRow(to parent: PlistNode) {
        let key = parent.type == .array ? "Item \(parent.children.count)" : "NewKey"
        let child = PlistNode(key: key, type: .string, stringValue: "")
        parent.children.append(child)
        objectWillChange.send()
    }

    func deleteRow(_ node: PlistNode, from parent: PlistNode) {
        parent.children.removeAll(where: { $0.id == node.id })
        objectWillChange.send()
    }
}
