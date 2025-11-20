//  ProductTileButtonStyle.swift
//  Tappayo
//
//  Custom button style that exposes press state for immediate cart row animation

import SwiftUI

struct ProductTileButtonStyle: ButtonStyle {
    let onPressChanged: (Bool) -> Void

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.6 : 1.0)  // Standard iOS dimming effect
            .onChange(of: configuration.isPressed) { oldValue, newValue in
                onPressChanged(newValue)
            }
    }
}
