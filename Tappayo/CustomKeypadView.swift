//  CustomKeypadView.swift
//  Tappayo
//
//  Custom numeric keypad for entering manual item prices

import SwiftUI

struct CustomKeypadView: View {
    @Binding var amountInCents: Int
    let defaultItemName: String
    let onAddToCart: (String) -> String  // Returns the next item name to display
    let onCancel: () -> Void
    let inputMode: String
    @Binding var toastMessage: String?
    @Environment(\.colorScheme) var colorScheme

    @Binding var itemName: String  // Changed from @State to @Binding to persist draft

    var body: some View {
        ZStack {
            GeometryReader { geometry in
                let horizontalEdgePadding: CGFloat = 60  // Padding on left/right edges of entire keypad content (check for long numbers like $123,456.78
                let buttonSpacing: CGFloat = 24            // Space between individual buttons

                let availableWidth = geometry.size.width - (2 * horizontalEdgePadding)
                let calculatedSize = (availableWidth - (2 * buttonSpacing)) / 3  // 3 buttons per row
                let buttonSize = max(calculatedSize, 60)  // Ensure minimum 60pt (prevents invalid frames build warning)

                keypadContent(buttonSize: buttonSize, spacing: buttonSpacing, horizontalEdgePadding: horizontalEdgePadding)
            }
            .sheetGradientBackground()
            .background(
                // Tap anywhere to dismiss keyboard
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
            )
            .onAppear {
                // Only set default if itemName is empty (first time or after reset)
                if itemName.isEmpty {
                    itemName = defaultItemName
                }
            }

            // Toast notification overlay
            if let message = toastMessage {
                VStack {
                    Spacer()
                    ToastView(message: message, isShowing: Binding(
                        get: { self.toastMessage != nil },
                        set: { if !$0 { self.toastMessage = nil } }
                    ))
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, 0)  // distance from bottom of iPhone screen
                    .id(message)  // Force view recreation when message changes to reset progress bar
                    // Button height (50) + VStack bottom padding (30) + spacing (30)
                }
                .animation(.spring(), value: toastMessage)
            }
        }
    }

    private func keypadContent(buttonSize: CGFloat, spacing: CGFloat, horizontalEdgePadding: CGFloat) -> some View {
        VStack(spacing: 40) {

            // Item name field
            ProductNameField(
                name: $itemName,
                label: "Description",
                onSubmit: nil,
                autoSelectDefaultText: true
            )
            .padding(.top, 40)
            .padding(.horizontal, -28)  // Partially counteracts horizontalEdgePadding. Current: 72 - 28 + field's internal 16 = 60pt from edge. To match ItemEditorView/ProductEditorView exactly (48pt from edge), use: -(horizontalEdgePadding - 32). With 72: use -40 for exact match.

            // Amount display
            Text(formatAmount(amountInCents))
                .font(.system(size: 56, weight: .medium, design: .default))
                .foregroundStyle(.primary)
                .frame(height: 70)
                .padding(.horizontal, -8)  // Partially counteracts aggressive horizontalEdgePadding; check it works for viewing all of $123,456.78
            
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
                        Button(action: {
                            onAddToCart(itemName)
                            // itemName updates via binding from ContentView
                        }) {
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
                Button(action: {
                    onAddToCart(itemName)
                    // itemName updates via binding from ContentView
                }) {
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
        .padding(.vertical, 10)
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
        Group {
            // Normal amount - for testing typical layout
            CustomKeypadView(
                amountInCents: .constant(2500),  // $25.00
                defaultItemName: "Custom item 1",
                onAddToCart: { name in return "Custom item 2" },
                onCancel: {},
                inputMode: "cents",
                toastMessage: .constant(nil),
                itemName: .constant("")
            )
            .previewDisplayName("Normal Amount ($25)")

            // Large amount - test horizontal padding with $123,456.78
            CustomKeypadView(
                amountInCents: .constant(12345678),  // $123,456.78
                defaultItemName: "Custom item 1",
                onAddToCart: { name in return "Custom item 2" },
                onCancel: {},
                inputMode: "cents",
                toastMessage: .constant(nil),
                itemName: .constant("")
            )
            .previewDisplayName("Large Amount ($123,456)")

            // With toast notification - test positioning
            CustomKeypadView(
                amountInCents: .constant(5600),  // $56.00
                defaultItemName: "Custom item 1",
                onAddToCart: { name in return "Custom item 2" },
                onCancel: {},
                inputMode: "cents",
                toastMessage: .constant("$56.00 added to cart"),
                itemName: .constant("")
            )
            .previewDisplayName("With Toast Notification")
        }
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
