//  CheckoutSheet.swift
//  Tappayo
//
//  Sheet view for reviewing cart and initiating payment

import SwiftUI

struct CheckoutSheet: View {
    @Binding var basket: [CartItem]
    let subtotalInCents: Int
    let taxAmountInCents: Int
    let totalAmountInCents: Int
    let formattedTotalAmount: String
    let connectionStatus: String
    let onCharge: () -> Void

    private func formatMoney(_ cents: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        formatter.usesGroupingSeparator = true
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: Double(cents) / 100)) ?? "$0.00"
    }

    var body: some View {
        VStack(spacing: 16) {
            ScrollView {
                VStack(spacing: 16) {
                    // Cart items (only visible when expanded - cut off when collapsed)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Cart")
                            .font(.headline)
                            .fontWeight(.bold)

                        ForEach(basket) { item in
                            HStack {
                                Text(item.name)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                if item.quantity > 1 {
                                    Text("×\(item.quantity)")
                                        .font(.system(.body, design: .monospaced))
                                        .foregroundColor(.secondary)
                                }

                                Text(formatMoney(item.priceInCents * item.quantity))
                                    .font(.system(.body, design: .monospaced))
                            }
                        }
                    }
                    .padding(.horizontal)

                    Divider()

            // Subtotal & Tax
            VStack(spacing: 8) {
                HStack {
                    Text("Subtotal")
                    Spacer()
                    Text(formatMoney(subtotalInCents))
                }
                if taxAmountInCents > 0 {
                    HStack {
                        Text("Tax")
                        Spacer()
                        Text(formatMoney(taxAmountInCents))
                    }
                }
            }
            .font(.subheadline)
            .padding(.horizontal)

            // Charge Button
            if totalAmountInCents > 49 {
                Button(action: onCharge) {
                    HStack {
                        Image(systemName: "wave.3.right.circle.fill")
                        Text("Charge card $\(formattedTotalAmount)")
                            .font(.title2)
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
            } else {
                Text("Minimum charge $0.50")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            }

                    // Connection status (only visible when expanded)
                    Text(connectionStatus)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.top, 16)
                }
            }
        }
        .background(Color(.systemBackground))
        .padding(.bottom, 8)
    }
}
