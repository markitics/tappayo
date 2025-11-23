//  ProductTileButtonStyle.swift
//  Tappayo
//
//  Custom button style that exposes press state for immediate cart row animation

import SwiftUI

struct ProductTileButtonStyle: ButtonStyle {
    let onPressChanged: (Bool) -> Void

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(  // Blue background behind content when pressed
                RoundedRectangle(cornerRadius: 8)
                    .fill(configuration.isPressed ? Color.blue.opacity(0.35) : Color.clear)
            )
            .scaleEffect(configuration.isPressed ? 1.08 : 1.0)  // Grow to 108% (subtle swell)
            .animation(
                configuration.isPressed
                    ? .easeOut(duration: 0.03)  // Very fast smooth press (30ms)
                    : .bouncy(duration: 0.4, extraBounce: 0.3),  // Bouncy when released
                value: configuration.isPressed
            )
            .onChange(of: configuration.isPressed) { oldValue, newValue in
                onPressChanged(newValue)
            }
    }
}
