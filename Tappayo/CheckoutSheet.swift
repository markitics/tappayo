//  CheckoutSheet.swift
//  Tappayo
//
//  Sheet view for reviewing cart and initiating payment

import SwiftUI

struct CheckoutSheet: View {
    @Binding var basket: [CartItem]
    @Binding var savedProducts: [Product]
    @State private var editingItem: CartItem? = nil
    @Binding var lastChangedItemId: UUID?
    @Binding var isAnimatingQuantity: Bool

    let businessName: String
    let subtotalInCents: Int
    let taxAmountInCents: Int
    let totalAmountInCents: Int
    let formattedTotalAmount: String
    let connectionStatus: String
    let isProcessingPayment: Bool
    let onCharge: () -> Void

    // Helper functions passed from ContentView
    let getCurrentProduct: (CartItem) -> (name: String, priceInCents: Int)
    let formatCurrency: (Int, Bool) -> String
    let getCachedImage: (String) -> UIImage?
    let allItemsQuantityOne: Bool
    let cartHasAnyCents: Bool

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
        VStack(spacing: 0) {
            // Business name header
            Text(businessName)
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.top, 20)
                .padding(.bottom, 12)
            Spacer()
            // Cart section header
//            HStack {
//                Text("Cart")
//                    .font(.headline)
//                    .fontWeight(.bold)
//                    .padding(.horizontal, 20)
////                Spacer()
//            }

            // Interactive cart list (with swipe actions and tap to edit)
            CartListView(
                basket: $basket,
                savedProducts: $savedProducts,
                editingItem: $editingItem,
                lastChangedItemId: $lastChangedItemId,
                isAnimatingQuantity: $isAnimatingQuantity,
                getCurrentProduct: getCurrentProduct,
                formatCurrency: formatCurrency,
                getCachedImage: getCachedImage,
                allItemsQuantityOne: allItemsQuantityOne,
                cartHasAnyCents: cartHasAnyCents
            )
            .frame(maxHeight: 250)

            Divider()
                .padding(.vertical, 8)
                .padding(.horizontal, 20)

            // Subtotal & Tax
            VStack(spacing: 8) {
                HStack {
                    Text("Subtotal")
                    Spacer()
                    Text(formatMoney(subtotalInCents))
                        .font(.system(.body, design: .monospaced))
                }
                if taxAmountInCents > 0 {
                    HStack {
                        Text("Tax")
                        Spacer()
                        Text(formatMoney(taxAmountInCents))
                            .font(.system(.body, design: .monospaced))
                    }
                }
            }
            .padding(.horizontal, 20)
            
            Spacer()
            
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
                .disabled(isProcessingPayment)
                .opacity(isProcessingPayment ? 0.6 : 1.0)
                .padding(.horizontal, 20)
                .padding(.top, 16)
            } else {
                Text("Minimum charge $0.50")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
            }

            // Connection status
            Text(connectionStatus)
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.top, 16)
                .padding(.bottom, 8)
        }
        .background(Color(.systemBackground))
        .sheet(item: $editingItem) { item in
            // Nested sheet for editing cart items
            if let index = basket.firstIndex(where: { $0.id == item.id }) {
                ItemEditorView(
                    item: item,
                    basketIndex: index,
                    basket: $basket,
                    savedProducts: $savedProducts,
                    formatAmount: formatCurrency
                )
                .presentationDetents([.fraction(0.7), .fraction(0.9)])
                .presentationDragIndicator(.visible)
            }
        }
    }
}
