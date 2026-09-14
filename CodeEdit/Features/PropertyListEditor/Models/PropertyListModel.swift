//
//  PropertyListModel.swift
//  CodeEdit
//
//  Created by Austin Condiff on 14/09/26.
//

import SwiftUI

enum PlistType: String, CaseIterable, Identifiable {
    case string = "String"
    case boolean = "Boolean"
    case number = "Number"
    case date = "Date"
    case data = "Data"
    case array = "Array"
    case dictionary = "Dictionary"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .string: return "textformat"
        case .boolean: return "switch.2"
        case .number: return "number"
        case .date: return "calendar"
        case .data: return "memorychip"
        case .array: return "list.bullet"
        case .dictionary: return "books.vertical"
        }
    }
}

final class PlistNode: Identifiable, ObservableObject {
    let id: UUID
    @Published var key: String
    @Published var type: PlistType
    @Published var stringValue: String
    @Published var boolValue: Bool
    @Published var numberValue: Double
    @Published var children: [PlistNode]
    @Published var isExpanded: Bool

    init(
        id: UUID = UUID(),
        key: String,
        type: PlistType,
        stringValue: String = "",
        boolValue: Bool = false,
        numberValue: Double = 0,
        children: [PlistNode] = [],
        isExpanded: Bool = true
    ) {
        self.id = id
        self.key = key
        self.type = type
        self.stringValue = stringValue
        self.boolValue = boolValue
        self.numberValue = numberValue
        self.children = children
        self.isExpanded = isExpanded
    }

    func toObject() -> Any {
        switch type {
        case .string:
            return stringValue
        case .boolean:
            return boolValue
        case .number:
            return numberValue
        case .date:
            return Date()
        case .data:
            return stringValue.data(using: .utf8) ?? Data()
        case .array:
            return children.map { $0.toObject() }
        case .dictionary:
            var dict: [String: Any] = [:]
            for child in children {
                dict[child.key] = child.toObject()
            }
            return dict
        }
    }

    static func from(key: String, value: Any) -> PlistNode {
        if let str = value as? String {
            return PlistNode(key: key, type: .string, stringValue: str)
        } else if let num = value as? NSNumber {
            if CFGetTypeID(num) == CFBooleanGetTypeID() {
                return PlistNode(key: key, type: .boolean, boolValue: num.boolValue)
            } else {
                return PlistNode(key: key, type: .number, numberValue: num.doubleValue)
            }
        } else if let dict = value as? [String: Any] {
            let sortedKeys = dict.keys.sorted()
            let children = sortedKeys.map { key in
                PlistNode.from(key: key, value: dict[key]!)
            }
            return PlistNode(key: key, type: .dictionary, children: children)
        } else if let array = value as? [Any] {
            let children = array.enumerated().map { idx, val in
                PlistNode.from(key: "Item \(idx)", value: val)
            }
            return PlistNode(key: key, type: .array, children: children)
        } else if let data = value as? Data {
            return PlistNode(key: key, type: .data, stringValue: data.base64EncodedString())
        } else {
            return PlistNode(key: key, type: .string, stringValue: "\(value)")
        }
    }
}
