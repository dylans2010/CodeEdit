//
//  VisualUIBuilder.swift
//  UniversalIDE
//

import SwiftUI
import Foundation

public struct CanvasDeviceFrame: Identifiable, Sendable {
    public let id: UUID
    public var name: String
    public var width: CGFloat
    public var height: CGFloat

    public init(id: UUID = UUID(), name: String, width: CGFloat, height: CGFloat) {
        self.id = id
        self.name = name
        self.width = width
        self.height = height
    }
}

public struct UIComponentPrimitive: Identifiable, Sendable {
    public let id: UUID
    public var type: String // Text, Button, Image, VStack, HStack
    public var properties: [String: String]

    public init(id: UUID = UUID(), type: String, properties: [String: String] = [:]) {
        self.id = id
        self.type = type
        self.properties = properties
    }
}

public final class CodeForArtboard {
    public static func generateSwiftUI(components: [UIComponentPrimitive]) -> String {
        var code = "import SwiftUI\n\nstruct GeneratedView: View {\n    var body: some View {\n        VStack {\n"
        for comp in components {
            if comp.type == "Text" {
                let text = comp.properties["text"] ?? "Hello World"
                code += "            Text(\"\(text)\")\n"
            } else if comp.type == "Button" {
                let title = comp.properties["title"] ?? "Click Me"
                code += "            Button(\"\(title)\") { }\n"
            }
        }
        code += "        }\n    }\n}\n"
        return code
    }
}

public struct VisualUIBuilderCanvasView: View {
    @State private var frames: [CanvasDeviceFrame] = [
        CanvasDeviceFrame(name: "iPhone 15 Pro", width: 393, height: 852),
        CanvasDeviceFrame(name: "iPad Air", width: 820, height: 1180)
    ]
    @State private var zoomScale: CGFloat = 1.0

    public init() {}

    public var body: some View {
        VStack {
            HStack {
                Text("Artboard Canvas").font(.headline)
                Spacer()
                Text("Zoom: \(Int(zoomScale * 100))%")
            }
            .padding()

            ScrollView([.horizontal, .vertical]) {
                HStack(spacing: 30) {
                    ForEach(frames) { frame in
                        VStack {
                            Text(frame.name).font(.caption).bold()
                            Rectangle()
                                .fill(Color.white)
                                .border(Color.secondary, width: 1)
                                .frame(width: frame.width * zoomScale, height: frame.height * zoomScale)
                                .overlay(
                                    VStack {
                                        Text("SwiftUI Live Visual Canvas")
                                            .foregroundColor(.gray)
                                    }
                                )
                        }
                    }
                }
                .padding()
            }
        }
    }
}

public struct RunFullAppView: View {
    public init() {}

    public var body: some View {
        VStack {
            Text("Interactive App Runner")
                .font(.headline)
            Spacer()
            Text("Full View Hierarchy Interactivity Active")
            Spacer()
        }
        .padding()
    }
}
