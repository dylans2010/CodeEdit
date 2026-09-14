import SwiftUI

struct XcodeProjectEditorView: View {
    @StateObject private var manager: XcodeProjectManager

    init(projectURL: URL) {
        _manager = StateObject(wrappedValue: XcodeProjectManager(projectURL: projectURL))
    }

    var body: some View {
        HSplitView {
            targetsSidebar
                .frame(minWidth: 180, idealWidth: 220, maxWidth: 280)

            mainContentView
                .frame(minWidth: 500, maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    // MARK: - Sidebar

    private var targetsSidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            projectRow
            Divider()
            targetsSectionHeader
            targetsList
        }
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private var projectRow: some View {
        HStack(spacing: 8) {
            Image(systemName: "hammer.fill")
                .foregroundColor(.accentColor)
                .font(.system(size: 16))
            VStack(alignment: .leading, spacing: 2) {
                Text(manager.project?.name ?? "Project")
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)
                Text(manager.project?.compatibilityVersion ?? "Xcode Project")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(12)
    }

    private var targetsSectionHeader: some View {
        HStack {
            Text("TARGETS")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.secondary)
            Spacer()
            if let count = manager.project?.targets.count {
                Text("\(count)")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 12)
        .padding(.bottom, 6)
    }

    private var targetsList: some View {
        ScrollView {
            LazyVStack(spacing: 2) {
                ForEach(manager.project?.targets ?? []) { target in
                    targetRow(target)
                }
            }
            .padding(.horizontal, 8)
        }
    }

    private func targetRow(_ target: PBXTargetModel) -> some View {
        let isSelected = manager.selectedTargetId == target.id
        return Button {
            manager.selectedTargetId = target.id
        } label: {
            HStack(spacing: 8) {
                Image(systemName: target.targetIcon)
                    .font(.system(size: 14))
                    .foregroundColor(isSelected ? .white : .accentColor)
                    .frame(width: 18)

                VStack(alignment: .leading, spacing: 1) {
                    Text(target.name)
                        .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                        .foregroundColor(isSelected ? .white : .primary)
                        .lineLimit(1)
                    Text(target.targetTypeDescription)
                        .font(.system(size: 10))
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                }
                Spacer()
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .background(isSelected ? Color.accentColor : Color.clear)
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Main Content

    private var mainContentView: some View {
        VStack(spacing: 0) {
            headerBar
            Divider()

            if manager.isLoading {
                loadingView
            } else if let err = manager.errorMessage {
                errorView(err)
            } else {
                tabContentView
            }
        }
    }

    private var headerBar: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: manager.selectedTarget?.targetIcon ?? "cube")
                    .font(.system(size: 20))
                    .foregroundColor(.accentColor)

                Text(manager.selectedTarget?.name ?? manager.project?.name ?? "Xcode Project")
                    .font(.title3)
                    .fontWeight(.semibold)

                Spacer()
            }

            tabBar
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 8)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var tabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(XcodeProjectTab.allCases) { tab in
                    let isSelected = manager.selectedTab == tab
                    Button {
                        manager.selectedTab = tab
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 11))
                            Text(tab.rawValue)
                                .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(isSelected ? Color.accentColor.opacity(0.18) : Color.clear)
                        .foregroundColor(isSelected ? .accentColor : .secondary)
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @ViewBuilder
    private var tabContentView: some View {
        switch manager.selectedTab {
        case .general:
            GeneralTabView(manager: manager)
        case .signing:
            SigningTabView(manager: manager)
        case .capabilities:
            CapabilitiesTabView(manager: manager)
        case .resourceTags:
            ResourceTagsTabView(manager: manager)
        case .info:
            InfoTabView(manager: manager)
        case .buildSettings:
            BuildSettingsTabView(manager: manager)
        case .buildPhases:
            BuildPhasesTabView(manager: manager)
        case .buildRules:
            BuildRulesTabView(manager: manager)
        }
    }

    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("Loading Xcode Project...")
                .font(.callout)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 36))
                .foregroundColor(.yellow)
            Text("Failed to Load Project")
                .font(.headline)
            Text(message)
                .font(.callout)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
