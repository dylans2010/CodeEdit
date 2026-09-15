//
//  EntitlementsEditorView.swift
//  CodeEdit
//

import SwiftUI
import AppKit

public struct EntitlementCapability: Identifiable, Equatable {
    public let id: String
    public let name: String
    public let summary: String
    public let iconName: String
    public var isEnabled: Bool
    public let rawKey: String
    public var customPayload: [String: Any]

    public static func == (lhs: EntitlementCapability, rhs: EntitlementCapability) -> Bool {
        lhs.id == rhs.id && lhs.isEnabled == rhs.isEnabled
    }
}

public struct EntitlementsEditorView: View {
    public let fileURL: URL
    @State private var capabilities: [EntitlementCapability] = [
        EntitlementCapability(
            id: "sandbox",
            name: "App Sandbox",
            summary: "Restricts access to user data and system resources to increase security.",
            iconName: "shippingbox.fill",
            isEnabled: true,
            rawKey: "com.apple.security.app-sandbox",
            customPayload: [:]
        ),
        EntitlementCapability(
            id: "network_client",
            name: "Outgoing Network Connections (Client)",
            summary: "Enables your app to establish outgoing client network connections.",
            iconName: "network",
            isEnabled: true,
            rawKey: "com.apple.security.network.client",
            customPayload: [:]
        ),
        EntitlementCapability(
            id: "network_server",
            name: "Incoming Network Connections (Server)",
            summary: "Enables your app to open a network listening socket for incoming connections.",
            iconName: "server.rack",
            isEnabled: false,
            rawKey: "com.apple.security.network.server",
            customPayload: [:]
        ),
        EntitlementCapability(
            id: "camera",
            name: "Camera Access",
            summary: "Permits capture of video and images using built-in or external cameras.",
            iconName: "camera.fill",
            isEnabled: false,
            rawKey: "com.apple.security.device.camera",
            customPayload: [:]
        ),
        EntitlementCapability(
            id: "microphone",
            name: "Microphone Access",
            summary: "Permits audio recording via built-in or external microphones.",
            iconName: "mic.fill",
            isEnabled: false,
            rawKey: "com.apple.security.device.microphone",
            customPayload: [:]
        ),
        EntitlementCapability(
            id: "push",
            name: "Push Notifications",
            summary: "Permits receiving remote notifications from Apple Push Notification service.",
            iconName: "bell.badge.fill",
            isEnabled: false,
            rawKey: "aps-environment",
            customPayload: ["aps-environment": "development"]
        ),
        EntitlementCapability(
            id: "keychain",
            name: "Keychain Sharing",
            summary: "Permits sharing of Keychain credentials across app groups or bundle IDs.",
            iconName: "key.fill",
            isEnabled: false,
            rawKey: "keychain-access-groups",
            customPayload: [:]
        ),
        EntitlementCapability(
            id: "icloud",
            name: "iCloud Containers",
            summary: "Enables syncing documents and CloudKit records across user devices.",
            iconName: "icloud.fill",
            isEnabled: false,
            rawKey: "com.apple.developer.icloud-container-identifiers",
            customPayload: [:]
        ),
        EntitlementCapability(
            id: "associated_domains",
            name: "Associated Domains",
            summary: "Enables Universal Links, shared web credentials, and app clip verification.",
            iconName: "link",
            isEnabled: false,
            rawKey: "com.apple.developer.associated-domains",
            customPayload: [:]
        ),
        EntitlementCapability(
            id: "apple_sign_in",
            name: "Sign in with Apple",
            summary: "Permits integrating user authentication using Apple ID credentials.",
            iconName: "applelogo",
            isEnabled: false,
            rawKey: "com.apple.developer.applesignin",
            customPayload: [:]
        )
    ]

    public init(fileURL: URL) {
        self.fileURL = fileURL
    }

    public var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Entitlements & Capabilities")
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                Button {
                    saveEntitlements()
                } label: {
                    Label("Save Entitlements", systemImage: "square.and.arrow.down")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            .padding(12)
            .background(Color(nsColor: .controlBackgroundColor))

            Divider()

            ScrollView {
                VStack(spacing: 12) {
                    ForEach($capabilities) { $cap in
                        HStack(alignment: .top, spacing: 14) {
                            Image(systemName: cap.iconName)
                                .font(.system(size: 20))
                                .foregroundColor(cap.isEnabled ? .accentColor : .secondary)
                                .frame(width: 28)

                            VStack(alignment: .leading, spacing: 3) {
                                Text(cap.name)
                                    .font(.system(size: 13, weight: .medium))
                                Text(cap.summary)
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                                Text(cap.rawKey)
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(.secondary.opacity(0.8))
                                    .padding(.top, 2)
                            }

                            Spacer()

                            Toggle("", isOn: $cap.isEnabled)
                                .toggleStyle(.switch)
                                .labelsHidden()
                        }
                        .padding(12)
                        .background(Color(nsColor: .controlBackgroundColor).opacity(0.6))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(cap.isEnabled ? Color.accentColor.opacity(0.3) : Color.secondary.opacity(0.15), lineWidth: 1)
                        )
                    }
                }
                .padding(16)
            }
        }
        .onAppear {
            loadEntitlements()
        }
    }

    private func loadEntitlements() {
        guard let data = try? Data(contentsOf: fileURL),
              let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any] else {
            return
        }

        for index in capabilities.indices {
            let key = capabilities[index].rawKey
            if let val = plist[key] {
                if let boolVal = val as? Bool {
                    capabilities[index].isEnabled = boolVal
                } else {
                    capabilities[index].isEnabled = true
                }
            } else {
                capabilities[index].isEnabled = false
            }
        }
    }

    private func saveEntitlements() {
        var dict: [String: Any] = [:]
        for cap in capabilities where cap.isEnabled {
            if cap.rawKey == "aps-environment" {
                dict[cap.rawKey] = "development"
            } else if !cap.customPayload.isEmpty {
                for (payloadKey, payloadVal) in cap.customPayload {
                    dict[payloadKey] = payloadVal
                }
            } else {
                dict[cap.rawKey] = true
            }
        }

        if let data = try? PropertyListSerialization.data(fromPropertyList: dict, format: .xml, options: 0) {
            try? data.write(to: fileURL)
        }
    }
}
