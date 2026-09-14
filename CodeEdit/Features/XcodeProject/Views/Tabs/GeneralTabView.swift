//
//  GeneralTabView.swift
//  CodeEdit
//
//  Created by Austin Condiff on 14/09/26.
//

import SwiftUI

struct GeneralTabView: View {
    @ObservedObject var manager: XcodeProjectManager

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                identitySection
                supportedDestinationsSection
                deploymentInfoSection
                appIconsSection
                frameworksSection
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var identitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Identity", icon: "person.crop.square")

            VStack(spacing: 8) {
                settingRow(
                    label: "Display Name",
                    key: "PRODUCT_NAME",
                    placeholder: manager.selectedTarget?.productName ?? ""
                )
                settingRow(
                    label: "Bundle Identifier",
                    key: "PRODUCT_BUNDLE_IDENTIFIER",
                    placeholder: "com.example.app"
                )
                HStack(spacing: 16) {
                    settingRow(
                        label: "Version",
                        key: "MARKETING_VERSION",
                        placeholder: "1.0.0"
                    )
                    settingRow(
                        label: "Build",
                        key: "CURRENT_PROJECT_VERSION",
                        placeholder: "1"
                    )
                }
            }
            .padding(12)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(8)
        }
    }

    private var supportedDestinationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Supported Destinations", icon: "display.2")

            HStack(spacing: 12) {
                destinationBadge(title: "macOS", icon: "laptopcomputer", active: true)
                destinationBadge(title: "iOS", icon: "iphone", active: isIOS)
                destinationBadge(title: "iPadOS", icon: "ipad", active: isIOS)
                destinationBadge(title: "watchOS", icon: "applewatch", active: false)
                destinationBadge(title: "visionOS", icon: "visionpro", active: false)
            }
            .padding(12)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(8)
        }
    }

    private var isIOS: Bool {
        let platforms = manager.getSetting("SUPPORTED_PLATFORMS")
        let sdk = manager.getSetting("SDKROOT")
        return platforms.contains("iphoneos") || sdk.contains("iphoneos")
    }

    private var deploymentInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Deployment Info", icon: "arrow.up.forward.app")

            VStack(spacing: 8) {
                settingRow(
                    label: "macOS Deployment Target",
                    key: "MACOSX_DEPLOYMENT_TARGET",
                    placeholder: "13.0"
                )
                settingRow(
                    label: "iOS Deployment Target",
                    key: "IPHONEOS_DEPLOYMENT_TARGET",
                    placeholder: "16.0"
                )
            }
            .padding(12)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(8)
        }
    }

    private var appIconsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("App Icons and Launch Images", icon: "photo.stack")

            VStack(spacing: 8) {
                settingRow(
                    label: "App Icon Source",
                    key: "ASSETCATALOG_COMPILER_APPICON_NAME",
                    placeholder: "AppIcon"
                )
            }
            .padding(12)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(8)
        }
    }

    private var frameworksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Frameworks, Libraries, and Embedded Content", icon: "shippingbox")

            let frameworksPhase = manager.selectedTarget?.buildPhases.first(where: { $0.type == .frameworks })
            let files = frameworksPhase?.files ?? []

            if files.isEmpty {
                Text("No frameworks or libraries linked")
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .padding(12)
            } else {
                VStack(spacing: 0) {
                    ForEach(files) { file in
                        HStack(spacing: 8) {
                            Image(systemName: "shippingbox.fill")
                                .foregroundColor(.accentColor)
                            Text(file.name)
                                .font(.system(size: 13))
                            Spacer()
                            Text("Do Not Embed")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        Divider()
                    }
                }
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(8)
            }
        }
    }

    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
            Text(title)
                .font(.headline)
        }
    }

    private func destinationBadge(title: String, icon: String, active: Bool) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
            Text(title)
                .font(.system(size: 12, weight: .medium))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(active ? Color.accentColor.opacity(0.15) : Color(nsColor: .quaternaryLabelColor))
        .foregroundColor(active ? .accentColor : .secondary)
        .cornerRadius(6)
    }

    private func settingRow(label: String, key: String, placeholder: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
                .frame(width: 180, alignment: .leading)
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
}
