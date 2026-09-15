//
//  LivePreviewContainerView.swift
//  CodeEdit
//
//

import SwiftUI

/// Container view hosting the live SwiftUI preview canvas and interactive environment controls.
public struct LivePreviewContainerView: View {
    @ObservedObject private var reloadManager = PreviewLiveReloadManager.shared
    @State private var availableSimulators: [SimulatorDevice] = []
    @State private var selectedSimulatorUDID: String = ""

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            previewToolbar
            Divider()

            ZStack {
                Color(nsColor: .windowBackgroundColor)
                    .ignoresSafeArea()

                if let error = reloadManager.lastErrorMessage {
                    errorView(message: error)
                } else {
                    canvasView
                }

                if reloadManager.isCompiling {
                    compilingOverlay
                }
            }
        }
        .task {
            let sims = await SimulatorManager.shared.listSimulators()
            self.availableSimulators = sims
            if let first = sims.first {
                self.selectedSimulatorUDID = first.udid
            }
        }
    }

    private var previewToolbar: some View {
        HStack(spacing: 12) {
            Button {
                reloadManager.toggleColorScheme()
            } label: {
                Image(systemName: reloadManager.isColorSchemeDark ? "moon.fill" : "sun.max.fill")
            }
            .help("Toggle Color Scheme (Light / Dark)")

            Button {
                reloadManager.toggleOrientation()
            } label: {
                Image(systemName: reloadManager.orientation == .portrait ? "iphone" : "iphone.landscape")
            }
            .help("Toggle Orientation (Portrait / Landscape)")

            Picker("Type", selection: $reloadManager.dynamicType) {
                ForEach(PreviewDynamicType.allCases, id: \.self) { item in
                    Text(item.rawValue).tag(item)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 140)

            Spacer()

            if !availableSimulators.isEmpty {
                Picker("Simulator", selection: $selectedSimulatorUDID) {
                    ForEach(availableSimulators) { sim in
                        Text(sim.name).tag(sim.udid)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 160)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
    }

    private var canvasView: some View {
        VStack(spacing: 16) {
            Image(systemName: "swift")
                .font(.system(size: 48))
                .foregroundStyle(.orange)

            Text("Live SwiftUI Preview")
                .font(.title2.weight(.semibold))

            Text("Orientation: \(reloadManager.orientation.rawValue) | Reloads: \(reloadManager.reloadCount)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(
            width: reloadManager.orientation == .portrait ? 320 : 480,
            height: reloadManager.orientation == .portrait ? 560 : 300
        )
        .background(
            RoundedRectangle(cornerRadius: 32)
                .fill(reloadManager.isColorSchemeDark ? Color.black : Color.white)
                .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 4)
        )
        .preferredColorScheme(reloadManager.isColorSchemeDark ? .dark : .light)
        .environment(\.dynamicTypeSize, reloadManager.dynamicType.dynamicTypeSize)
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title)
                .foregroundStyle(.red)
            Text("Preview Compilation Error")
                .font(.headline)
            ScrollView {
                Text(message)
                    .font(.caption.monospaced())
                    .padding()
            }
            .frame(maxHeight: 180)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(8)
        }
        .padding()
    }

    private var compilingOverlay: some View {
        VStack(spacing: 8) {
            ProgressView()
            Text("Recompiling...")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}
