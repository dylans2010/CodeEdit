//
//  SigningTabView.swift
//  CodeEdit
//
//  Created by Austin Condiff on 14/09/26.
//

import SwiftUI

struct SigningTabView: View {
    @ObservedObject var manager: XcodeProjectManager

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerSection
                signingSettingsSection
                certificateInfoSection
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var headerSection: some View {
        HStack(spacing: 8) {
            Image(systemName: "signature")
                .foregroundColor(.accentColor)
            Text("Signing & Capabilities")
                .font(.title2)
                .fontWeight(.semibold)
        }
    }

    private var signingSettingsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Toggle(
                    "Automatically manage signing",
                    isOn: Binding(
                        get: { manager.getSetting("CODE_SIGN_STYLE", defaultValue: "Automatic") == "Automatic" },
                        set: { manager.updateBuildSetting(key: "CODE_SIGN_STYLE", value: $0 ? "Automatic" : "Manual") }
                    )
                )
                .toggleStyle(.checkbox)
                Spacer()
            }

            VStack(spacing: 10) {
                signingRow(
                    label: "Team",
                    key: "DEVELOPMENT_TEAM",
                    placeholder: "None (Personal Team)"
                )
                signingRow(
                    label: "Bundle Identifier",
                    key: "PRODUCT_BUNDLE_IDENTIFIER",
                    placeholder: "com.example.app"
                )
                signingRow(
                    label: "Provisioning Profile",
                    key: "PROVISIONING_PROFILE_SPECIFIER",
                    placeholder: "Automatic"
                )
                signingRow(
                    label: "Signing Certificate",
                    key: "CODE_SIGN_IDENTITY",
                    placeholder: "Apple Development"
                )
            }
            .padding(14)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(8)
        }
    }

    private var certificateInfoSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundColor(.green)
                Text("Signing Status")
                    .font(.headline)
            }

            VStack(alignment: .leading, spacing: 8) {
                statusRow(
                    label: "Status",
                    value: "Code signing is configured for development and distribution."
                )
                statusRow(
                    label: "Team ID",
                    value: manager.getSetting("DEVELOPMENT_TEAM", defaultValue: "Not Specified")
                )
                statusRow(
                    label: "Code Sign Style",
                    value: manager.getSetting("CODE_SIGN_STYLE", defaultValue: "Automatic")
                )
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(8)
        }
    }

    private func signingRow(label: String, key: String, placeholder: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
                .frame(width: 160, alignment: .leading)
            TextField(
                placeholder,
                text: Binding(
                    get: { manager.getSetting(key, defaultValue: placeholder) },
                    set: { manager.updateBuildSetting(key: key, value: $0) }
                )
            )
            .textFieldStyle(.roundedBorder)
        }
    }

    private func statusRow(label: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(label + ":")
                .font(.system(size: 12, weight: .medium))
                .frame(width: 120, alignment: .leading)
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 12))
        }
    }
}
