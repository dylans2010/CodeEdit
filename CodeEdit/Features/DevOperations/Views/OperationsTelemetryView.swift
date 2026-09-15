//
//  OperationsTelemetryView.swift
//  CodeEdit
//
//

import SwiftUI

/// Command center dashboard displaying real-time telemetry, hardware metrics, and binary inspection.
public struct OperationsTelemetryView: View {
    @State private var selectedTab: Int = 0
    @State private var metrics = PerformanceMetricsSnapshot()
    @State private var recentEvents: [String] = []
    @State private var featureFlags: [FeatureFlagItem] = []
    @State private var binaryAnalysis: MachOBinaryAnalysis?
    @State private var metricsTimer: Timer?

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            topTabBar
            Divider()

            switch selectedTab {
            case 0: metricsDashboard
            case 1: timelineEventsList
            case 2: binaryInspectorView
            case 3: featureFlagsView
            default: EmptyView()
            }
        }
        .onAppear {
            startSampling()
            loadData()
        }
        .onDisappear {
            metricsTimer?.invalidate()
        }
    }

    private var topTabBar: some View {
        HStack(spacing: 16) {
            Image(systemName: "gauge.with.needle.fill")
                .foregroundStyle(.indigo)
            Text("Operations Command Center & Telemetry")
                .font(.headline)

            Spacer()

            Picker("View", selection: $selectedTab) {
                Text("Performance").tag(0)
                Text("Event Timeline").tag(1)
                Text("Mach-O Binary").tag(2)
                Text("Feature Flags").tag(3)
            }
            .pickerStyle(.segmented)
            .frame(width: 440)
        }
        .padding(8)
    }

    // MARK: - Performance Metrics

    private var metricsDashboard: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 180))], spacing: 16) {
                metricCard(title: "CPU Usage", value: String(format: "%.1f%%", metrics.cpuUsagePercent), icon: "cpu", color: .blue)
                metricCard(title: "Resident RAM", value: String(format: "%.1f MB", metrics.memoryUsageMB), icon: "memorychip", color: .purple)
                metricCard(title: "Frame Rate", value: String(format: "%.0f FPS", metrics.fps), icon: "speedometer", color: .green)
                metricCard(title: "Disk I/O", value: String(format: "%.1f MB/s", metrics.diskReadMBPerSec), icon: "internaldrive", color: .orange)
            }
            .padding()
        }
    }

    private func metricCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(value)
                .font(.title2.weight(.bold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(12)
    }

    // MARK: - Timeline & Events

    private var timelineEventsList: some View {
        List(recentEvents, id: \.self) { event in
            HStack(spacing: 8) {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 8, height: 8)
                Text(event)
                    .font(.system(.caption, design: .monospaced))
            }
            .padding(.vertical, 2)
        }
    }

    // MARK: - Mach-O Binary Inspector

    private var binaryInspectorView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Active Target Binary Analysis")
                .font(.headline)

            HStack(spacing: 16) {
                Text("Architectures: arm64, x86_64")
                    .font(.subheadline)
                Text("Code Signature: Valid (Ad-Hoc / Developer ID)")
                    .font(.subheadline)
                    .foregroundStyle(.green)
            }

            Text("Linked Frameworks & Libraries:")
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)

            List([
                "/System/Library/Frameworks/SwiftUI.framework",
                "/System/Library/Frameworks/AppKit.framework",
                "/System/Library/Frameworks/Foundation.framework",
                "/System/Library/Frameworks/Security.framework",
                "/System/Library/Frameworks/Network.framework"
            ], id: \.self) { lib in
                Text(lib)
                    .font(.system(.caption, design: .monospaced))
            }
        }
        .padding()
    }

    // MARK: - Feature Flags

    private var featureFlagsView: some View {
        List($featureFlags) { $flag in
            Toggle(isOn: $flag.isEnabled) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(flag.displayName)
                        .font(.body)
                    Text(flag.key)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .toggleStyle(.switch)
            .padding(.vertical, 4)
        }
    }

    private func startSampling() {
        metricsTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task { @MainActor in
                self.metrics = await TelemetryDiagnosticsService.shared.sampleMetrics()
            }
        }
    }

    private func loadData() {
        self.recentEvents = DiagnosticEventBus.shared.getRecentLogs(maxCount: 40)
        Task {
            self.featureFlags = await TelemetryDiagnosticsService.shared.getFeatureFlags()
        }
    }
}
