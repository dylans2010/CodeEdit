import SwiftUI

struct CapabilityItem: Identifiable {
    var id: String
    var title: String
    var subtitle: String
    var icon: String
    var isEnabled: Bool
}

struct CapabilitiesTabView: View {
    @ObservedObject var manager: XcodeProjectManager
    @State private var capabilities: [CapabilityItem] = [
        CapabilityItem(
            id: "sandbox",
            title: "App Sandbox",
            subtitle: "Restricts access to user data and system resources.",
            icon: "shippingbox",
            isEnabled: true
        ),
        CapabilityItem(
            id: "hardened_runtime",
            title: "Hardened Runtime",
            subtitle: "Protects the integrity of software by preventing runtime code injection.",
            icon: "shield.checkerboard",
            isEnabled: true
        ),
        CapabilityItem(
            id: "app_groups",
            title: "App Groups",
            subtitle: "Allows multiple apps produced by a single development team to share data.",
            icon: "person.3",
            isEnabled: true
        ),
        CapabilityItem(
            id: "push",
            title: "Push Notifications",
            subtitle: "Enables receiving remote notifications from Apple Push Notification service.",
            icon: "bell.badge",
            isEnabled: false
        ),
        CapabilityItem(
            id: "keychain",
            title: "Keychain Sharing",
            subtitle: "Enables sharing keychain items among apps produced by a single development team.",
            icon: "key",
            isEnabled: false
        ),
        CapabilityItem(
            id: "background_modes",
            title: "Background Modes",
            subtitle: "Configures background task execution and audio playback.",
            icon: "waveform.path",
            isEnabled: false
        )
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerView
                capabilitiesList
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Target Capabilities")
                    .font(.headline)
                Text("Configure app sandbox, security services, and entitlement features.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
    }

    private var capabilitiesList: some View {
        VStack(spacing: 12) {
            ForEach($capabilities) { $item in
                HStack(alignment: .top, spacing: 14) {
                    Image(systemName: item.icon)
                        .font(.system(size: 22))
                        .foregroundColor(item.isEnabled ? .accentColor : .secondary)
                        .frame(width: 32, height: 32)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.title)
                            .font(.system(size: 14, weight: .medium))
                        Text(item.subtitle)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Toggle("", isOn: $item.isEnabled)
                        .toggleStyle(.switch)
                        .labelsHidden()
                }
                .padding(14)
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(8)
            }
        }
    }
}
