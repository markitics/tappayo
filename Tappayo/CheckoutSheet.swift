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
    @State private var showingClearCartAlert = false
    @Binding var receiptEmail: String
    @Environment(\.dismiss) private var dismiss

    let businessName: String
    let subtotalInCents: Int
    let taxAmountInCents: Int
    let totalAmountInCents: Int
    let formattedTotalAmount: String
    let connectionStatus: String
    let isProcessingPayment: Bool
    let paymentSucceeded: Bool
    let onCharge: (String?) -> Void

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
//            .frame(maxHeight: .infinity)  // No! don't use maxHeight: .inifinity, because The List needs a height constraint to enable scrolling. we want .scrollIndicators visible.
            .frame(maxHeight: 400)  // Effectively unlimited; search for 99987 to adjust.

            // Everything below cart needs horizontal padding
            VStack(spacing: 0) {
                Divider()
                    .padding(.vertical, 8)

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
                
                Spacer()

                // Email field for receipt (optional) OR receipt confirmation
                if paymentSucceeded {
                    // Show receipt confirmation only if email was provided
                    if !receiptEmail.isEmpty {
                        Text("Receipt sent to \(receiptEmail)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.bottom, 8)
                    }
                    // If no email: hide this section entirely
                } else {
                    // Before payment: show email input field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email for receipt (optional)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        TextField("customer@example.com", text: $receiptEmail)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .textFieldStyle(.roundedBorder)
                            .foregroundStyle(.primary, .secondary)
                    }
                    .padding(.bottom, 8)
                }

                Spacer()

                // Charge Button or Success Message
                if paymentSucceeded {
                    // Success UI
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                        Text("Payment Received!")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text("Thanks for your payment")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                } else if totalAmountInCents > 49 {
                    Button(action: {
                        // Dismiss keyboard before processing payment
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        onCharge(receiptEmail.isEmpty ? nil : receiptEmail)
                    }) {
                        HStack {
                            Image(systemName: "wave.3.right.circle.fill")
                            Text("Pay $\(formattedTotalAmount)")
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
                    .padding(.top, 16)
                } else {
                    Text("Minimum charge $0.50")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 16)
                }

                // Connection status
                Text(connectionStatus)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.top, 16)
                    .padding(.bottom, 8)

                Spacer()

                // Clear cart and Save cart buttons
                HStack {
                    Button(action: {
                        showingClearCartAlert = true
                    }) {
                        Text("Clear Cart")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }

                    Spacer()

                    Button(action: {
                        // TODO: Implement save cart functionality
                    }) {
                        Text("Save Cart")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.bottom, 8)
            }
            .padding(.horizontal, 20)
        }
        .background(Color(.systemBackground))
        .overlay(
            GeometryReader { geometry in
                if paymentSucceeded {
                    ForEach(0..<50, id: \.self) { index in
                        Circle()
                            .fill([Color.red, .blue, .green, .yellow, .orange, .pink, .purple].randomElement() ?? .blue)
                            .frame(width: CGFloat.random(in: 6...12), height: CGFloat.random(in: 6...12))
                            .position(
                                x: CGFloat.random(in: 0...geometry.size.width),
                                y: paymentSucceeded ? geometry.size.height + 50 : -20
                            )
                            .opacity(paymentSucceeded ? 0 : 1)
                            .animation(.easeOut(duration: 2.5).delay(Double(index) * 0.02), value: paymentSucceeded)
                    }
                }
            }
            .allowsHitTesting(false)
        )
        .onChange(of: paymentSucceeded) { newValue in
            if newValue {
                // Play success haptic
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
            }
        }
        .alert("Clear Cart?", isPresented: $showingClearCartAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                basket.removeAll()
                receiptEmail = ""
                // Auto-dismiss sheet after 3 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    dismiss()
                }
            }
        } message: {
            Text("This will remove all items from your cart.")
        }
//        .background(Color(.red)) // only while debugging
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
