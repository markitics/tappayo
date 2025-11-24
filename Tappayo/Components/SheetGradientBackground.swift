//  SheetGradientBackground.swift
//  Tappayo
//
//  Reusable ViewModifier for consistent sheet gradient backgrounds across the app

import SwiftUI

/// Applies the standard sheet gradient background (light mode: green-gray gradient, dark mode: system background)
struct SheetGradientBackground: ViewModifier {
    @Environment(\.colorScheme) var colorScheme

    func body(content: Content) -> some View {
        content
            .background(
                Group {
                    if colorScheme == .light {
                        LinearGradient(
                            colors: [
                                Color(red: 0.90, green: 0.94, blue: 0.92),  // Soft green-gray (top)
                                Color(red: 0.96, green: 0.98, blue: 0.97)   // Very light green-white (bottom)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .ignoresSafeArea()  // Extend gradient to fill entire sheet
                    } else {
                        Color(.systemBackground)  // Dark mode: standard background
                    }
                }
            )
    }
}

/// Convenience extension for applying sheet gradient background
extension View {
    func sheetGradientBackground() -> some View {
        modifier(SheetGradientBackground())
    }
}
