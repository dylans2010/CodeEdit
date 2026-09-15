//
//  CodeForArtboardGenerator.swift
//  CodeEdit
//
//

import Foundation
import SwiftUI

/// Translates visual canvas component hierarchies to and from SwiftUI source code.
public struct CodeForArtboardGenerator: Sendable {
    public init() {}

    /// Serializes an array of canvas nodes into a clean SwiftUI View struct.
    public static func generateSwiftUICode(
        viewName: String = "GeneratedView",
        rootNodes: [CanvasComponentNode]
    ) -> String {
        var bodyLines: [String] = []

        for node in rootNodes {
            bodyLines.append(serializeNode(node: node, indentLevel: 3))
        }

        let bodyContent = bodyLines.isEmpty ? "            Text(\"Empty Artboard\")" : bodyLines.joined(separator: "\n")

        return """
        import SwiftUI

        struct \(viewName): View {
            var body: some View {
                VStack(spacing: 16) {
        \(bodyContent)
                }
                .padding()
            }
        }

        #Preview {
            \(viewName)()
        }
        """
    }

    private static func serializeNode(node: CanvasComponentNode, indentLevel: Int) -> String {
        let indent = String(repeating: "    ", count: indentLevel)

        switch node.type {
        case .text:
            return "\(indent)Text(\"\(node.title)\")"
        case .image:
            return "\(indent)Image(systemName: \"star.fill\").foregroundStyle(Color(hex: \"\(node.colorHex)\"))"
        case .button:
            return "\(indent)Button(\"\(node.title)\") {}\n\(indent)    .buttonStyle(.borderedProminent)"
        case .textField:
            return "\(indent)TextField(\"\(node.title)\", text: .constant(\"\"))\n\(indent)    .textFieldStyle(.roundedBorder)"
        case .toggle:
            return "\(indent)Toggle(\"\(node.title)\", isOn: .constant(true))"
        case .slider:
            return "\(indent)Slider(value: .constant(0.5))"
        case .rectangle:
            return "\(indent)RoundedRectangle(cornerRadius: \(node.cornerRadius))\n\(indent)    .frame(width: \(node.width), height: \(node.height))"
        case .circle:
            return "\(indent)Circle().frame(width: \(node.width), height: \(node.height))"
        case .capsule:
            return "\(indent)Capsule().frame(width: \(node.width), height: \(node.height))"
        case .vstack, .hstack, .zstack:
            var childLines: [String] = []
            for child in node.children {
                childLines.append(serializeNode(node: child, indentLevel: indentLevel + 1))
            }
            let childrenCode = childLines.isEmpty ? "\(indent)    EmptyView()" : childLines.joined(separator: "\n")
            return "\(indent)\(node.type.rawValue) {\n\(childrenCode)\n\(indent)}"
        }
    }
}

/// Interactive Full App Runner previewing the synthesized artboard view.
public struct RunFullAppView: View {
    public let nodes: [CanvasComponentNode]

    public init(nodes: [CanvasComponentNode]) {
        self.nodes = nodes
    }

    public var body: some View {
        VStack(spacing: 16) {
            ForEach(nodes) { node in
                HStack {
                    Text(node.title)
                        .font(.headline)
                    Spacer()
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 16, height: 16)
                }
                .padding()
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(node.cornerRadius)
            }
        }
        .padding()
        .frame(minWidth: 320, minHeight: 480)
    }
}
