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

    private let buttonSize: CGFloat = 70
    private let buttonSpacing: CGFloat = 16

    var body: some View {
        VStack(spacing: 20) {
            // Amount display
            Text(formatAmount(amountInCents))
                .font(.system(size: 48, weight: .medium, design: .default))
                .foregroundColor(.white)
                .frame(height: 60)

            // Number pad grid
            VStack(spacing: buttonSpacing) {
                // Row 1: 1, 2, 3
                HStack(spacing: buttonSpacing) {
                    ForEach(1...3, id: \.self) { number in
                        numberButton(number)
                    }
                }

                // Row 2: 4, 5, 6
                HStack(spacing: buttonSpacing) {
                    ForEach(4...6, id: \.self) { number in
                        numberButton(number)
                    }
                }

                // Row 3: 7, 8, 9
                HStack(spacing: buttonSpacing) {
                    ForEach(7...9, id: \.self) { number in
                        numberButton(number)
                    }
                }

                // Row 4: Add/Empty, 0, Backspace/Empty
                HStack(spacing: buttonSpacing) {
                    if amountInCents > 0 {
                        // Add to cart button (bottom-left when amount > 0)
                        Button(action: onAddToCart) {
                            Image(systemName: "plus")
                                .font(.system(size: 28, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .frame(width: buttonSize, height: buttonSize)
                        .background(Color.blue)
                        .clipShape(Circle())
                    } else {
                        // Empty space when amount is 0
                        Color.clear
                            .frame(width: buttonSize, height: buttonSize)
                    }

                    // Zero button (always in center)
                    numberButton(0)

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
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .frame(width: buttonSize, height: buttonSize)
                        .background(Color.gray.opacity(0.6))
                        .clipShape(Circle())
                    } else {
                        // Empty space when amount is 0
                        Color.clear
                            .frame(width: buttonSize, height: buttonSize)
                    }
                }
            }
            .padding(.vertical, 20)

            // Bottom buttons: Add to Cart and Dismiss
            HStack(spacing: 12) {
                // Add to Cart button (2/3 width)
                Button(action: onAddToCart) {
                    Text("Add to Cart")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                }
                .background(amountInCents > 0 ? Color.blue : Color.gray.opacity(0.5))
                .cornerRadius(10)
                .disabled(amountInCents == 0)
                .frame(maxWidth: .infinity, alignment: .leading)

                // Dismiss button (1/3 width)
                Button(action: onCancel) {
                    Text("Cancel")
                        .font(.callout)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .frame(width: 100, height: 50)
                }
                .background(Color.red.opacity(0.8))
                .cornerRadius(10)
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 30)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(UIColor.systemGray6).opacity(0.98))
        )
        .padding(.horizontal, 20)
    }

    // Helper to create number buttons
    private func numberButton(_ number: Int) -> some View {
        Button(action: {
            if inputMode == "dollars" {
                // In dollars mode, build whole dollar amounts (always multiples of 100 cents)
                let currentDollars = amountInCents / 100
                let newDollars = currentDollars * 10 + number
                amountInCents = newDollars * 100
            } else {
                // In cents mode, append digit normally
                amountInCents = amountInCents * 10 + number
            }
        }) {
            Text("\(number)")
                .font(.system(size: 32, weight: .medium))
                .foregroundColor(.white)
                .frame(width: buttonSize, height: buttonSize)
        }
        .background(Color.gray.opacity(0.8))
        .clipShape(Circle())
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
        .presentationDetents([.medium, .large])
    }
}
