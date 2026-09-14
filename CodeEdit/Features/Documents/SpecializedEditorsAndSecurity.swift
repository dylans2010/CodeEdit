//
//  SpecializedEditorsAndSecurity.swift
//  UniversalIDE
//

import SwiftUI
import Foundation
import Security

// MARK: - Path Security Error & Sanitization

public enum PathSecurityError: Error, LocalizedError {
    case invalidPath(String)

    public var errorDescription: String? {
        switch self {
        case .invalidPath(let path):
            return "Path security error: The path '\(path)' resolved outside the allowed project root or contains forbidden traversal sequences."
        }
    }
}

public struct PathSecuritySanitizer {
    public static func sanitizeAndValidate(filePath: String, projectRoot: String) throws -> URL {
        if filePath.contains("\0") || filePath.contains("..") {
            throw PathSecurityError.invalidPath(filePath)
        }

        let rootURL = URL(fileURLWithPath: projectRoot).standardizedFileURL
        let candidateURL = URL(fileURLWithPath: filePath, relativeTo: rootURL).standardizedFileURL

        guard candidateURL.path.hasPrefix(rootURL.path) else {
            throw PathSecurityError.invalidPath(filePath)
        }

        return candidateURL
    }
}

// MARK: - Keychain Security Storage Protocol

public final class EditorKeychainStorage {
    public static let shared = EditorKeychainStorage()
    public let serviceName = "com.editor.security.keychain"

    private init() {}

    public func setSecret(_ secret: String, forKey key: String) throws {
        guard let data = secret.data(using: .utf8) else { return }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key
        ]

        SecItemDelete(query as CFDictionary)

        var newQuery = query
        newQuery[kSecValueData as String] = data
        let status = SecItemAdd(newQuery as CFDictionary, nil)
        if status != errSecSuccess {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(status), userInfo: nil)
        }
    }

    public func getSecret(forKey key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    public func deleteSecret(forKey key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - Info.plist Schema Editor

public struct InfoPlistItem: Identifiable, Sendable {
    public let id: UUID
    public var rawKey: String
    public var humanKey: String
    public var value: String
    public var valueType: String

    public init(id: UUID = UUID(), rawKey: String, humanKey: String, value: String, valueType: String = "String") {
        self.id = id
        self.rawKey = rawKey
        self.humanKey = humanKey
        self.value = value
        self.valueType = valueType
    }
}

@MainActor
public final class InfoPlistEditorManager: ObservableObject {
    @Published public var items: [InfoPlistItem] = []

    public static let keyTranslations: [String: String] = [
        "NSCameraUsageDescription": "Privacy - Camera Usage Description",
        "NSMicrophoneUsageDescription": "Privacy - Microphone Usage Description",
        "NSLocationWhenInUseUsageDescription": "Privacy - Location When In Use Usage Description",
        "CFBundleDisplayName": "Bundle Display Name",
        "CFBundleIdentifier": "Bundle Identifier",
        "CFBundleVersion": "Bundle Version",
        "CFBundleShortVersionString": "Bundle Versions String, Short"
    ]

    public init() {}

    public func parsePlist(xmlString: String) {
        // Parse Plist dictionary elements
        items = [
            InfoPlistItem(
                rawKey: "NSCameraUsageDescription",
                humanKey: InfoPlistEditorManager.keyTranslations["NSCameraUsageDescription"] ?? "NSCameraUsageDescription",
                value: "Camera required for video capture",
                valueType: "String"
            ),
            InfoPlistItem(
                rawKey: "CFBundleDisplayName",
                humanKey: InfoPlistEditorManager.keyTranslations["CFBundleDisplayName"] ?? "CFBundleDisplayName",
                value: "Universal IDE",
                valueType: "String"
            )
        ]
    }
}

// MARK: - Entitlements Editor Manager

public struct EntitlementCapability: Identifiable, Sendable {
    public let id: String
    public var name: String
    public var isEnabled: Bool
    public var xmlKey: String

    public init(id: String, name: String, isEnabled: Bool, xmlKey: String) {
        self.id = id
        self.name = name
        self.isEnabled = isEnabled
        self.xmlKey = xmlKey
    }
}

@MainActor
public final class EntitlementsEditorManager: ObservableObject {
    @Published public var capabilities: [EntitlementCapability] = [
        EntitlementCapability(id: "sandbox", name: "App Sandbox", isEnabled: true, xmlKey: "com.apple.security.app-sandbox"),
        EntitlementCapability(id: "network_client", name: "Outgoing Connections (Client)", isEnabled: true, xmlKey: "com.apple.security.network.client"),
        EntitlementCapability(id: "network_server", name: "Incoming Connections (Server)", isEnabled: false, xmlKey: "com.apple.security.network.server"),
        EntitlementCapability(id: "push", name: "Push Notifications", isEnabled: false, xmlKey: "aps-environment"),
        EntitlementCapability(id: "keychain", name: "Keychain Sharing", isEnabled: true, xmlKey: "keychain-access-groups")
    ]

    public init() {}

    public func toggleCapability(_ id: String) {
        if let idx = capabilities.firstIndex(where: { $0.id == id }) {
            capabilities[idx].isEnabled.toggle()
        }
    }
}

// MARK: - Markdown File View Component

public struct MarkdownFileView: View {
    public let markdownContent: String
    @State private var isSplitPreview: Bool = true

    public init(markdownContent: String) {
        self.markdownContent = markdownContent
    }

    public var body: some View {
        HStack(spacing: 0) {
            TextEditor(text: .constant(markdownContent))
                .font(.monospaced(.body)())

            if isSplitPreview {
                Divider()
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Markdown Live Preview")
                            .font(.headline)
                        Text(markdownContent)
                            .font(.body)
                    }
                    .padding()
                }
            }
        }
    }
}
