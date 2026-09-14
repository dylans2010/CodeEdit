//
//  BlurButtonStyle.swift
//  CodeEdit
//
//  Created by Wouter Hennen on 21/01/2023.
//

import SwiftUI

extension ButtonStyle where Self == BlurButtonStyle {
    static var blur: BlurButtonStyle { BlurButtonStyle() }
}

struct BlurButtonStyle: ButtonStyle {
    @Environment(\.controlSize) var controlSize

    var height: CGFloat {
        switch controlSize {
        case .large:
            return 28
        default:
            return 20
        }
    }

    @Environment(\.colorScheme) var colorScheme

    @ViewBuilder
    private func backgroundView(isPressed: Bool) -> some View {
        switch colorScheme {
        case .dark:
            let base: Color = Color.gray.opacity(0.001)
            let tint: Color = Color.gray.opacity(0.30)
            let press: Color = Color.white.opacity(isPressed ? 0.20 : 0.00)
            base
                .overlay(.regularMaterial.blendMode(.plusLighter))
                .overlay(tint)
                .overlay(press)
        case .light:
            let base: Color = Color.gray.opacity(0.001)
            let tint: Color = Color.gray.opacity(0.15)
            base
                .overlay(.regularMaterial.blendMode(.darken))
                .overlay(AnyView(tint).blendMode(.plusDarker))
        @unknown default:
            Color.black
        }
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(height: height)
            .buttonStyle(.bordered)
            .background(backgroundView(isPressed: configuration.isPressed))
            .cornerRadius(6)
    }
}
