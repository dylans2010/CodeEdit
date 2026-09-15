//
//  UIBuilderModels.swift
//  CodeEdit
//
//

import Foundation
import SwiftUI

/// Preset screen frame formats for the multi-device artboard canvas.
public enum ArtboardDevicePreset: String, CaseIterable, Sendable {
    case iPhone15Pro = "iPhone 15 Pro"
    case iPadAir = "iPad Air (11-inch)"
    case macDesktop = "Mac Studio"

    public var dimensions: CGSize {
        switch self {
        case .iPhone15Pro: return CGSize(width: 393, height: 852)
        case .iPadAir: return CGSize(width: 820, height: 1180)
        case .macDesktop: return CGSize(width: 1200, height: 800)
        }
    }
}

/// Primitive UI component types.
public enum UIPrimitiveType: String, CaseIterable, Codable, Sendable {
    case text = "Text"
    case image = "Image"
    case button = "Button"
    case textField = "TextField"
    case toggle = "Toggle"
    case slider = "Slider"
    case vstack = "VStack"
    case hstack = "HStack"
    case zstack = "ZStack"
    case rectangle = "Rectangle"
    case circle = "Circle"
    case capsule = "Capsule"
}

/// A node on the Visual UI Builder canvas.
public struct CanvasComponentNode: Identifiable, Codable, Sendable {
    public let id: UUID
    public var type: UIPrimitiveType
    public var title: String
    public var width: Double
    public var height: Double
    public var cornerRadius: Double
    public var colorHex: String
    public var children: [CanvasComponentNode]

    public init(
        type: UIPrimitiveType,
        title: String = "",
        width: Double = 120,
        height: Double = 40,
        cornerRadius: Double = 8,
        colorHex: String = "#007AFF",
        children: [CanvasComponentNode] = []
    ) {
        self.id = UUID()
        self.type = type
        self.title = title.isEmpty ? type.rawValue : title
        self.width = width
        self.height = height
        self.cornerRadius = cornerRadius
        self.colorHex = colorHex
        self.children = children
    }
}

/// Animation configuration for canvas elements.
public struct CanvasAnimationConfig: Codable, Sendable {
    public var curve: String // "linear", "easeInOut", "spring"
    public var duration: Double
    public var mass: Double
    public var stiffness: Double
    public var damping: Double

    public init(
        curve: String = "easeInOut",
        duration: Double = 0.35,
        mass: Double = 1.0,
        stiffness: Double = 100.0,
        damping: Double = 10.0
    ) {
        self.curve = curve
        self.duration = duration
        self.mass = mass
        self.stiffness = stiffness
        self.damping = damping
    }
}
