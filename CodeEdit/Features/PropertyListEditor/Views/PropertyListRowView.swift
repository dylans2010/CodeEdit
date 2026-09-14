//
//  PropertyListRowView.swift
//  CodeEdit
//
//  Created by Austin Condiff on 14/09/26.
//

import SwiftUI

struct PropertyListRowView: View {
    @ObservedObject var node: PlistNode
    var parent: PlistNode?
    @ObservedObject var manager: PropertyListManager
    var depth: Int

    var body: some View {
        VStack(spacing: 0) {
            rowContent
            Divider()

            if (node.type == .dictionary || node.type == .array) && node.isExpanded {
                ForEach(node.children) { child in
                    PropertyListRowView(
                        node: child,
                        parent: node,
                        manager: manager,
                        depth: depth + 1
                    )
                }
            }
        }
    }

    private var rowContent: some View {
        HStack(spacing: 8) {
            indentationAndDisclosure
            keyField
            typePicker
            valueField
            Spacer()
            actionButtons
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 12)
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private var indentationAndDisclosure: some View {
        HStack(spacing: 4) {
            if depth > 0 {
                Spacer()
                    .frame(width: CGFloat(depth * 18))
            }

            if node.type == .dictionary || node.type == .array {
                Button {
                    node.isExpanded.toggle()
                } label: {
                    Image(systemName: node.isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)
                        .frame(width: 14, height: 14)
                }
                .buttonStyle(.plain)
            } else {
                Spacer()
                    .frame(width: 14)
            }
        }
    }

    private var keyField: some View {
        HStack {
            if parent?.type == .array {
                Text(node.key)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .frame(width: 140, alignment: .leading)
            } else {
                TextField("Key", text: $node.key)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12, weight: .medium))
                    .frame(width: 180, alignment: .leading)
            }
        }
    }

    private var typePicker: some View {
        Picker("", selection: $node.type) {
            ForEach(PlistType.allCases) { itemType in
                Text(itemType.rawValue).tag(itemType)
            }
        }
        .pickerStyle(.menu)
        .frame(width: 110)
    }

    @ViewBuilder
    private var valueField: some View {
        switch node.type {
        case .string, .number, .data, .date:
            TextField("Value", text: $node.stringValue)
                .textFieldStyle(.plain)
                .font(.system(size: 12))
                .frame(minWidth: 120, alignment: .leading)
        case .boolean:
            Toggle("", isOn: $node.boolValue)
                .toggleStyle(.switch)
                .labelsHidden()
                .frame(width: 60, alignment: .leading)
        case .dictionary, .array:
            Text("(\(node.children.count) items)")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .frame(minWidth: 80, alignment: .leading)
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 4) {
            if node.type == .dictionary || node.type == .array {
                Button {
                    manager.addRow(to: node)
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 11))
                        .foregroundColor(.accentColor)
                }
                .buttonStyle(.plain)
            }

            if let parentItem = parent {
                Button {
                    manager.deleteRow(node, from: parentItem)
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 11))
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(width: 48)
    }
}
