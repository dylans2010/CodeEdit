//
//  EditorKeychainManager.swift
//  CodeEdit
//

import Foundation
import Security

/// Universal Keychain Manager for securely storing API keys, OAuth tokens, and trust certificates.
/// Conforms to Section 1.3 Security & Keychain Storage Protocol.
public final class EditorKeychainManager: Sendable {
    public static let shared = EditorKeychainManager()

    public static let serviceName = "com.editor.security.keychain"

    public enum Key: String, CaseIterable, Sendable {
        case openRouterAPIKey = "openrouter_api_key"
        case gitHubPersonalAccessToken = "github_personal_access_token"
        case codexUserAPIKey = "codex_user_api_key"
        case codexAppAPIKey = "codex_app_api_key"
        case deployVercelToken = "deploy_vercel_token"
        case deployNetlifyToken = "deploy_netlify_token"
        case connectTruststoreKeys = "connect_truststore_keys"
    }

    private init() {}

    // MARK: - Generic Set / Get / Delete

    @discardableResult
    public func set(_ value: String, forKey key: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }
        return set(data, forKey: key)
    }

    @discardableResult
    public func set(_ data: Data, forKey key: String) -> Bool {
        // Delete any existing item first
        delete(forKey: key)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.serviceName,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    public func get(forKey key: String) -> String? {
        guard let data = getData(forKey: key) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    public func getData(forKey key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.serviceName,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        guard status == errSecSuccess, let data = item as? Data else {
            return nil
        }
        return data
    }

    @discardableResult
    public func delete(forKey key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.serviceName,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }

    // MARK: - Typed Key Helpers

    @discardableResult
    public func set(_ value: String, forTypedKey key: Key) -> Bool {
        set(value, forKey: key.rawValue)
    }

    public func get(forTypedKey key: Key) -> String? {
        get(forKey: key.rawValue)
    }

    @discardableResult
    public func delete(forTypedKey key: Key) -> Bool {
        delete(forKey: key.rawValue)
    }
}
