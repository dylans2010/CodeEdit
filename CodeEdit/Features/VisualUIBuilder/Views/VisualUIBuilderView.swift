//
//  VisualUIBuilderView.swift
//  CodeEdit
//
//

import SwiftUI

/// Infinite multi-device artboard canvas and visual UI builder workspace.
public struct VisualUIBuilderView: View {
    @State private var zoomScale: Double = 1.0
    @State private var selectedDevice: ArtboardDevicePreset = .iPhone15Pro
    @State private var canvasNodes: [CanvasComponentNode] = [
        CanvasComponentNode(type: .text, title: "Welcome to Universal IDE"),
        CanvasComponentNode(type: .button, title: "Get Started", colorHex: "#007AFF"),
        CanvasComponentNode(type: .toggle, title: "Enable Notifications")
    ]
    @State private var selectedNodeID: UUID?
    @State private var showingCodeSheet: Bool = false
    @State private var generatedCode: String = ""

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            topToolbar
            Divider()

            HSplitView {
                componentPalette
                artboardCanvas
                inspectorSidebar
            }
        }
        .sheet(isPresented: $showingCodeSheet) {
            codeExportSheet
        }
    }

    private var topToolbar: some View {
        HStack(spacing: 12) {
            Image(systemName: "square.grid.2x2")
                .foregroundStyle(.purple)
            Text("Visual UI Builder")
                .font(.headline)

            Spacer()

            Picker("Device", selection: $selectedDevice) {
                ForEach(ArtboardDevicePreset.allCases, id: \.self) { preset in
                    Text(preset.rawValue).tag(preset)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 320)

            HStack(spacing: 4) {
                Button {
                    zoomScale = max(0.2, zoomScale - 0.1)
                } label: { Image(systemName: "minus.magnifyingglass") }

                Text("\(Int(zoomScale * 100))%")
                    .font(.caption.monospaced())
                    .frame(width: 44)

                Button {
                    zoomScale = min(3.0, zoomScale + 0.1)
                } label: { Image(systemName: "plus.magnifyingglass") }
            }

            Button("Export SwiftUI") {
                self.generatedCode = CodeForArtboardGenerator.generateSwiftUICode(rootNodes: canvasNodes)
                self.showingCodeSheet = true
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(8)
    }

    private var componentPalette: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Components")
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.top, 8)

            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 8) {
                    ForEach(UIPrimitiveType.allCases, id: \.self) { prim in
                        Button {
                            let newNode = CanvasComponentNode(type: prim)
                            canvasNodes.append(newNode)
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: iconForPrimitive(prim))
                                    .font(.title3)
                                Text(prim.rawValue)
                                    .font(.caption2)
                            }
                            .frame(maxWidth: .infinity, minHeight: 54)
                            .background(Color(nsColor: .controlBackgroundColor))
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(8)
            }
        }
        .frame(minWidth: 160, maxWidth: 220)
    }

    private var artboardCanvas: some View {
        ScrollView([.horizontal, .vertical]) {
            ZStack {
                // Background grid
                Color(nsColor: .windowBackgroundColor)
                    .frame(width: 2000, height: 2000)

                // Artboard Device Frame
                VStack(spacing: 16) {
                    ForEach(canvasNodes) { node in
                        nodeRowView(node: node)
                    }
                }
                .padding(24)
                .frame(width: selectedDevice.dimensions.width, height: selectedDevice.dimensions.height)
                .background(Color.white)
                .cornerRadius(44)
                .shadow(color: .black.opacity(0.18), radius: 20, x: 0, y: 10)
                .scaleEffect(zoomScale)
            }
        }
    }

    private func nodeRowView(node: CanvasComponentNode) -> some View {
        HStack {
            Text(node.title)
                .foregroundStyle(.black)
            Spacer()
        }
        .padding()
        .frame(height: node.height)
        .background(node.id == selectedNodeID ? Color.blue.opacity(0.15) : Color.gray.opacity(0.1))
        .cornerRadius(node.cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: node.cornerRadius)
                .stroke(node.id == selectedNodeID ? Color.blue : Color.clear, lineWidth: 2)
        )
        .onTapGesture {
            self.selectedNodeID = node.id
        }
    }

    private var inspectorSidebar: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Inspector")
                .font(.headline)
                .padding(.top, 8)

            if let selectedID = selectedNodeID,
               let index = canvasNodes.firstIndex(where: { $0.id == selectedID }) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Title")
                        .font(.caption)
                    TextField("Title", text: $canvasNodes[index].title)
                        .textFieldStyle(.roundedBorder)

                    Text("Height: \(Int(canvasNodes[index].height))")
                        .font(.caption)
                    Slider(value: $canvasNodes[index].height, in: 24...120)

                    Text("Corner Radius: \(Int(canvasNodes[index].cornerRadius))")
                        .font(.caption)
                    Slider(value: $canvasNodes[index].cornerRadius, in: 0...32)

                    Button("Delete Element", role: .destructive) {
                        canvasNodes.remove(at: index)
                        self.selectedNodeID = nil
                    }
                    .padding(.top, 8)
                }
            } else {
                Text("Select an item on the artboard to customize properties.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding()
        .frame(minWidth: 200, maxWidth: 280)
    }

    private var codeExportSheet: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Generated SwiftUI Code")
                    .font(.headline)
                Spacer()
                Button("Done") { showingCodeSheet = false }
            }
            ScrollView {
                Text(generatedCode)
                    .font(.system(.caption, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(8)
        }
        .padding()
        .frame(width: 500, height: 400)
    }

    private func iconForPrimitive(_ prim: UIPrimitiveType) -> String {
        switch prim {
        case .text: return "textformat"
        case .image: return "photo"
        case .button: return "hand.tap"
        case .textField: return "character.cursor.ibeam"
        case .toggle: return "switch.2"
        case .slider: return "slider.horizontal.3"
        case .vstack: return "square.stack"
        case .hstack: return "sidebar.left"
        case .zstack: return "square.2.layers.3d"
        case .rectangle: return "rectangle"
        case .circle: return "circle"
        case .capsule: return "capsule"
        }
    }
}
