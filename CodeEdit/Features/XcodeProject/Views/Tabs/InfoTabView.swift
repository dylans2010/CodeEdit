import SwiftUI

struct TargetPropertyItem: Identifiable {
    var id: String
    var key: String
    var type: String
    var value: String
}

struct InfoTabView: View {
    @ObservedObject var manager: XcodeProjectManager

    var properties: [TargetPropertyItem] {
        var items: [TargetPropertyItem] = []
        let bundleId = manager.getSetting("PRODUCT_BUNDLE_IDENTIFIER", defaultValue: "com.example.app")
        let name = manager.getSetting("PRODUCT_NAME", defaultValue: manager.selectedTarget?.productName ?? "App")
        let version = manager.getSetting("MARKETING_VERSION", defaultValue: "1.0.0")
        let build = manager.getSetting("CURRENT_PROJECT_VERSION", defaultValue: "1")
        let infoPlist = manager.getSetting("INFOPLIST_FILE", defaultValue: "Info.plist")

        items.append(TargetPropertyItem(id: "1", key: "Bundle identifier", type: "String", value: bundleId))
        items.append(TargetPropertyItem(id: "2", key: "Bundle name", type: "String", value: name))
        items.append(TargetPropertyItem(id: "3", key: "Bundle version string (short)", type: "String", value: version))
        items.append(TargetPropertyItem(id: "4", key: "Bundle version", type: "String", value: build))
        items.append(TargetPropertyItem(id: "5", key: "Info.plist File", type: "String", value: infoPlist))
        items.append(TargetPropertyItem(id: "6", key: "Executable name", type: "String", value: "$(EXECUTABLE_NAME)"))
        items.append(TargetPropertyItem(id: "7", key: "Principal class", type: "String", value: "NSApplication"))
        items.append(TargetPropertyItem(id: "8", key: "Main storyboard file base name", type: "String", value: "Main"))
        return items
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                targetPropertiesSection
                documentTypesSection
                urlTypesSection
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var targetPropertiesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "list.bullet.rectangle")
                    .foregroundColor(.accentColor)
                Text("Custom Target Properties")
                    .font(.headline)
            }

            VStack(spacing: 0) {
                tableHeader(col1: "Key", col2: "Type", col3: "Value")
                Divider()

                ForEach(properties) { prop in
                    HStack {
                        Text(prop.key)
                            .font(.system(size: 13, weight: .medium))
                            .frame(width: 220, alignment: .leading)
                        Text(prop.type)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .frame(width: 90, alignment: .leading)
                        Text(prop.value)
                            .font(.system(size: 13))
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    Divider()
                }
            }
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(8)
        }
    }

    private var documentTypesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "doc.badge.plus")
                    .foregroundColor(.accentColor)
                Text("Document Types")
                    .font(.headline)
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Configured Document Types: 1")
                        .font(.system(size: 13, weight: .medium))
                    Spacer()
                }
                Text("Viewer & Editor types associated with this application.")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .padding(14)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(8)
        }
    }

    private var urlTypesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "link.badge.plus")
                    .foregroundColor(.accentColor)
                Text("URL Types")
                    .font(.headline)
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Configured URL Schemes: 0")
                        .font(.system(size: 13, weight: .medium))
                    Spacer()
                }
                Text("Custom URL schemes supported for deep-linking into this application.")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .padding(14)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(8)
        }
    }

    private func tableHeader(col1: String, col2: String, col3: String) -> some View {
        HStack {
            Text(col1)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
                .frame(width: 220, alignment: .leading)
            Text(col2)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
                .frame(width: 90, alignment: .leading)
            Text(col3)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(Color(nsColor: .quaternaryLabelColor))
    }
}
