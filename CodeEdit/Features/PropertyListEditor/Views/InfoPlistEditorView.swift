//
//  InfoPlistEditorView.swift
//  CodeEdit
//

import SwiftUI
import AppKit

public struct InfoPlistItem: Identifiable, Equatable {
    public let id = UUID()
    public var rawKey: String
    public var type: PropertyType
    public var stringValue: String
    public var boolValue: Bool
    public var arrayValues: [String]

    public enum PropertyType: String, CaseIterable, Identifiable {
        case string = "String"
        case boolean = "Boolean"
        case array = "Array"
        case dictionary = "Dictionary"
        public var id: String { rawValue }
    }

    public var friendlyName: String {
        InfoPlistEditorView.friendlyKeyDescriptions[rawKey] ?? rawKey
    }
}

public struct InfoPlistEditorView: View {
    @State private var items: [InfoPlistItem] = []
    @State private var searchText = ""
    @State private var showingAddSheet = false
    @State private var newKeyName = ""
    @State private var newKeyType: InfoPlistItem.PropertyType = .string

    public let fileURL: URL
    public let onSave: (([InfoPlistItem]) -> Void)?

    public static let friendlyKeyDescriptions: [String: String] = [
        "CFBundleDisplayName": "Bundle Display Name",
        "CFBundleIdentifier": "Bundle Identifier",
        "CFBundleVersion": "Bundle Version",
        "CFBundleShortVersionString": "Bundle Version String (Short)",
        "CFBundlePackageType": "Package Type",
        "LSRequiresIPhoneOS": "Application Requires iPhone Environment",
        "UIRequiredDeviceCapabilities": "Required Device Capabilities",
        "UISupportedInterfaceOrientations": "Supported Interface Orientations",
        "NSCameraUsageDescription": "Privacy - Camera Usage Description",
        "NSMicrophoneUsageDescription": "Privacy - Microphone Usage Description",
        "NSPhotoLibraryUsageDescription": "Privacy - Photo Library Usage Description",
        "NSLocationWhenInUseUsageDescription": "Privacy - Location When In Use Usage Description",
        "NSLocationAlwaysAndWhenInUseUsageDescription": "Privacy - Location Always & When In Use Usage Description",
        "NSBluetoothAlwaysUsageDescription": "Privacy - Bluetooth Always Usage Description",
        "NSFaceIDUsageDescription": "Privacy - Face ID Usage Description",
        "NSAppleMusicUsageDescription": "Privacy - Media Library Usage Description",
        "ITSAppUsesNonExemptEncryption": "App Uses Non-Exempt Encryption"
    ]

    public init(fileURL: URL, onSave: (([InfoPlistItem]) -> Void)? = nil) {
        self.fileURL = fileURL
        self.onSave = onSave
    }

    private var filteredItems: [InfoPlistItem] {
        if searchText.isEmpty { return items }
        return items.filter {
            $0.rawKey.localizedCaseInsensitiveContains(searchText) ||
            $0.friendlyName.localizedCaseInsensitiveContains(searchText) ||
            $0.stringValue.localizedCaseInsensitiveContains(searchText)
        }
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .font(.system(size: 11))
                TextField("Filter Keys", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))

                Spacer()

                Button {
                    showingAddSheet = true
                } label: {
                    Label("Add Key", systemImage: "plus")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Button {
                    savePropertyList()
                } label: {
                    Label("Save", systemImage: "square.and.arrow.down")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(nsColor: .controlBackgroundColor))

            Divider()

            // Key-value table
            Table(filteredItems) {
                TableColumn("Key") { item in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.friendlyName)
                            .font(.system(size: 12, weight: .medium))
                        if item.friendlyName != item.rawKey {
                            Text(item.rawKey)
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .width(min: 200, ideal: 260)

                TableColumn("Type") { item in
                    Text(item.type.rawValue)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .width(min: 70, ideal: 90)

                TableColumn("Value") { item in
                    valueEditor(for: item)
                }
                .width(min: 180, ideal: 300)

                TableColumn("Actions") { item in
                    Button {
                        deleteItem(item)
                    } label: {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                }
                .width(50)
            }
        }
        .onAppear {
            loadPropertyList()
        }
        .sheet(isPresented: $showingAddSheet) {
            addKeySheet
        }
    }

    @ViewBuilder
    private func valueEditor(for item: InfoPlistItem) -> some View {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            switch item.type {
            case .string:
                TextField("Value", text: $items[index].stringValue)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 11))
            case .boolean:
                Toggle("", isOn: $items[index].boolValue)
                    .toggleStyle(.switch)
                    .labelsHidden()
            case .array:
                Text("\(item.arrayValues.count) items")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            case .dictionary:
                Text("Dictionary values")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
        }
    }

    private var addKeySheet: some View {
        VStack(spacing: 16) {
            Text("Add Property List Key")
                .font(.headline)

            VStack(alignment: .leading, spacing: 6) {
                Text("Key Name or Human Title")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextField("e.g. NSCameraUsageDescription", text: $newKeyName)
                    .textFieldStyle(.roundedBorder)

                Text("Type")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Picker("", selection: $newKeyType) {
                    ForEach(InfoPlistItem.PropertyType.allCases) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)
            }

            HStack {
                Button("Cancel") {
                    showingAddSheet = false
                    newKeyName = ""
                }
                Spacer()
                Button("Add") {
                    addNewKey()
                    showingAddSheet = false
                    newKeyName = ""
                }
                .buttonStyle(.borderedProminent)
                .disabled(newKeyName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(20)
        .frame(width: 380)
    }

    private func addNewKey() {
        let key = newKeyName.trimmingCharacters(in: .whitespaces)
        items.append(InfoPlistItem(
            rawKey: key,
            type: newKeyType,
            stringValue: "",
            boolValue: false,
            arrayValues: []
        ))
    }

    private func deleteItem(_ item: InfoPlistItem) {
        items.removeAll(where: { $0.id == item.id })
    }

    private func loadPropertyList() {
        guard let data = try? Data(contentsOf: fileURL),
              let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any] else {
            // Seed common keys if empty or unreadable
            items = [
                InfoPlistItem(rawKey: "CFBundleDisplayName", type: .string, stringValue: "My Application", boolValue: false, arrayValues: []),
                InfoPlistItem(rawKey: "CFBundleIdentifier", type: .string, stringValue: "com.example.app", boolValue: false, arrayValues: []),
                InfoPlistItem(rawKey: "CFBundleVersion", type: .string, stringValue: "1", boolValue: false, arrayValues: []),
                InfoPlistItem(rawKey: "CFBundleShortVersionString", type: .string, stringValue: "1.0.0", boolValue: false, arrayValues: []),
                InfoPlistItem(rawKey: "ITSAppUsesNonExemptEncryption", type: .boolean, stringValue: "", boolValue: false, arrayValues: [])
            ]
            return
        }

        items = plist.map { key, value in
            if let str = value as? String {
                return InfoPlistItem(rawKey: key, type: .string, stringValue: str, boolValue: false, arrayValues: [])
            } else if let num = value as? NSNumber, CFGetTypeID(num) == CFBooleanGetTypeID() {
                return InfoPlistItem(rawKey: key, type: .boolean, stringValue: "", boolValue: num.boolValue, arrayValues: [])
            } else if let arr = value as? [String] {
                return InfoPlistItem(rawKey: key, type: .array, stringValue: "", boolValue: false, arrayValues: arr)
            } else {
                return InfoPlistItem(rawKey: key, type: .string, stringValue: "\(value)", boolValue: false, arrayValues: [])
            }
        }.sorted(by: { $0.rawKey < $1.rawKey })
    }

    private func savePropertyList() {
        var dict: [String: Any] = [:]
        for item in items {
            switch item.type {
            case .string:
                dict[item.rawKey] = item.stringValue
            case .boolean:
                dict[item.rawKey] = item.boolValue
            case .array:
                dict[item.rawKey] = item.arrayValues
            case .dictionary:
                dict[item.rawKey] = item.stringValue
            }
        }

        if let data = try? PropertyListSerialization.data(fromPropertyList: dict, format: .xml, options: 0) {
            try? data.write(to: fileURL)
        }
        onSave?(items)
    }
}
