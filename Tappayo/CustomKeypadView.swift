//  CustomKeypadView.swift
//  Tappayo
//
//  Custom numeric keypad for entering manual item prices

import SwiftUI

struct CustomKeypadView: View {
    @Binding var amountInCents: Int
    let onAddToCart: () -> Void
    let onCancel: () -> Void
    let inputMode: String
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        GeometryReader { geometry in
            let horizontalEdgePadding: CGFloat = 48  // Padding on left/right edges of entire keypad
            let buttonSpacing: CGFloat = 20          // Space between individual buttons

            let availableWidth = geometry.size.width - (2 * horizontalEdgePadding)
            let calculatedSize = (availableWidth - (2 * buttonSpacing)) / 3  // 3 buttons per row
            let buttonSize = max(calculatedSize, 60)  // Ensure minimum 60pt (prevents invalid frames build warning)

            keypadContent(buttonSize: buttonSize, spacing: buttonSpacing, horizontalEdgePadding: horizontalEdgePadding)
        }
        .sheetGradientBackground()
    }

    private func keypadContent(buttonSize: CGFloat, spacing: CGFloat, horizontalEdgePadding: CGFloat) -> some View {
        VStack(spacing: 40) {
            // Amount display
            Text(formatAmount(amountInCents))
                .font(.system(size: 56, weight: .medium, design: .default))
                .foregroundStyle(.primary)
                .frame(height: 70)
                .padding(.top, 40)

            // Number pad grid
            VStack(spacing: spacing) {
                // Row 1: 1, 2, 3
                HStack(spacing: spacing) {
                    ForEach(1...3, id: \.self) { number in
                        numberButton(number, size: buttonSize)
                    }
                }

                // Row 2: 4, 5, 6
                HStack(spacing: spacing) {
                    ForEach(4...6, id: \.self) { number in
                        numberButton(number, size: buttonSize)
                    }
                }

                // Row 3: 7, 8, 9
                HStack(spacing: spacing) {
                    ForEach(7...9, id: \.self) { number in
                        numberButton(number, size: buttonSize)
                    }
                }

                // Row 4: Add/Empty, 0, Backspace/Empty
                HStack(spacing: spacing) {
                    if amountInCents > 0 {
                        // Add to cart button (bottom-left when amount > 0)
                        Button(action: onAddToCart) {
                            Image(systemName: "plus")
                                .font(.system(size: buttonSize * 0.35, weight: .medium))  // Scales with button
                                .foregroundStyle(.white)
                        }
                        .frame(width: buttonSize, height: buttonSize)
                        .background(Color.blue)
                        .clipShape(Circle())
                        .shadow(color: .blue.opacity(0.3), radius: 8, y: 4)
                    } else {
                        // Empty space when amount is 0
                        Color.clear
                            .frame(width: buttonSize, height: buttonSize)
                    }

                    // Zero button (always in center)
                    numberButton(0, size: buttonSize)

                    if amountInCents > 0 {
                        // Backspace button (bottom-right when amount > 0)
                        Button(action: {
                            if inputMode == "dollars" {
                                // In dollars mode, remove last dollar digit
                                let currentDollars = amountInCents / 100
                                let newDollars = currentDollars / 10
                                amountInCents = newDollars * 100
                            } else {
                                // In cents mode, remove last digit normally
                                amountInCents = amountInCents / 10
                            }
                        }) {
                            Image(systemName: "delete.left")
                                .font(.system(size: buttonSize * 0.31, weight: .medium))  // Scales with button
                                .foregroundStyle(colorScheme == .light ? .black : .white)  // Dark text in light mode, white in dark
                                .frame(width: buttonSize, height: buttonSize)
                        }
                        .buttonStyle(GlassButtonStyle())
                    } else {
                        // Empty space when amount is 0
                        Color.clear
                            .frame(width: buttonSize, height: buttonSize)
                    }
                }
            }
//            .padding(.vertical, 20) removed this; increased overall VStack spacing to 40 instead, for consistency of gab between (i) top number and keypad and (ii) keypad and "add to cart" row.

            // Bottom buttons: Add to Cart and Dismiss
            HStack(spacing: 12) {
                // Add to Cart button (2/3 width)
                Button(action: onAddToCart) {
                    Text("Add to Cart")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                }
                .background(amountInCents > 0 ? Color.blue : Color.gray.opacity(0.5))
                .cornerRadius(10)
                .disabled(amountInCents == 0)
                .shadow(color: amountInCents > 0 ? .blue.opacity(0.3) : .clear, radius: 8, y: 4)
                .frame(maxWidth: .infinity, alignment: .leading)

                // Dismiss button (1/3 width)
                Button(action: onCancel) {
                    Text("Cancel")
                        .font(.callout)
                        .fontWeight(.medium)
                        .foregroundStyle(.white)
                        .frame(width: 100, height: 50)
                }
                .background(Color.red.opacity(0.8))
                .cornerRadius(10)
                .shadow(color: .red.opacity(0.2), radius: 6, y: 3)
            }
        }
        .padding(.vertical, 30)
        .padding(.horizontal, horizontalEdgePadding)  // Consistent padding on all edges
    }

    // Helper to create number buttons
    private func numberButton(_ number: Int, size: CGFloat) -> some View {
        Button(action: {
            // Maximum value: $999,999.99 (prevents overflow and unrealistic amounts)
            let maxCents = 99_999_999

            if inputMode == "dollars" {
                // In dollars mode, build whole dollar amounts (always multiples of 100 cents)
                let currentDollars = amountInCents / 100
                let newDollars = currentDollars * 10 + number
                let newCents = newDollars * 100

                // Only update if under maximum
                if newCents <= maxCents {
                    amountInCents = newCents
                }
            } else {
                // In cents mode, append digit normally
                let newAmount = amountInCents * 10 + number

                // Only update if under maximum
                if newAmount <= maxCents {
                    amountInCents = newAmount
                }
            }
        }) {
            Text("\(number)")
                .font(.system(size: size * 0.4, weight: .medium))  // Font scales with button (40% of button size)
                .foregroundStyle(colorScheme == .light ? .black : .white)  // Dark text in light mode, white in dark
                .frame(width: size, height: size)
        }
        .buttonStyle(GlassButtonStyle())
    }

    // Helper to format the amount display
    private func formatAmount(_ cents: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        formatter.usesGroupingSeparator = true
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: Double(cents) / 100)) ?? "$0.00"
    }
}

// MARK: - Preview Provider

struct CustomKeypadView_Previews: PreviewProvider {
    static var previews: some View {
        CustomKeypadView(
            amountInCents: .constant(1234),
            onAddToCart: {},
            onCancel: {},
            inputMode: "cents"
        )
        .presentationDetents([.fraction(0.8), .large]) // just the preview; what matters is contentview where this is called
    }
}

// MARK: - Glass Button Style

struct GlassButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) var colorScheme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                Circle()
                    .fill(configuration.isPressed ? Color.blue : Color.clear)
            )
            .background(
                // Light mode: white frosted glass; Dark mode: dark frosted glass
                Group {
                    if colorScheme == .light {
                        Circle()
                            .fill(.white.opacity(0.7))
                            .background(.ultraThinMaterial, in: Circle())
                    } else {
                        Circle()
                            .fill(Color.clear)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                }
            )
            .overlay(
                Circle()
                    .strokeBorder(
                        colorScheme == .light
                            ? Color.gray.opacity(0.2)  // Subtle gray border in light mode
                            : Color.white.opacity(0.2),  // White border in dark mode
                        lineWidth: 0.5
                    )
            )
            .shadow(
                color: colorScheme == .light
                    ? Color.gray.opacity(0.15)  // Subtle gray shadow in light mode
                    : Color.black.opacity(0.1),  // Black shadow in dark mode
                radius: 8,
                y: 4
            )
            .scaleEffect(configuration.isPressed ? 1.15 : 1.0)  // Grow to 115% (lock screen style)
            .animation(
                configuration.isPressed
                    ? .easeOut(duration: 0.03)  // Very fast smooth press (30ms)
                    : .bouncy(duration: 0.4, extraBounce: 0.3),  // Bouncy when released
                value: configuration.isPressed
            )
            .contentShape(Circle())  // Define exact hit area (prevents sheet from capturing touches)
    }
}
