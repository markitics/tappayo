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
    @State private var isKeyboardVisible = false
    @State private var dismissCountdown: Int = 30
    @State private var dismissTimer: Timer? = nil
    @State private var clearCartCountdown: Int = 5
    @State private var clearCartTimer: Timer? = nil
    @State private var showingClearCartCountdown = false
    @State private var showEmailField = false
    @FocusState private var isEmailFieldFocused: Bool
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
    let onDismiss: () -> Void

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
            // Business name header removed - .presentationDetents([.fraction(0.9)]) means we can see business name on the main page behind this sheet
//            Text(businessName)
//                .font(.title2)
//                .fontWeight(.semibold)
//                .padding(.top, 28)
//                .padding(.bottom, 8)
//                .padding(.horizontal, 24)

            // Cart section header
//            HStack {
//                Text("Cart")
//                    .font(.headline)
//                    .fontWeight(.bold)
//                    .padding(.horizontal, 20)
//                Spacer()
//            }

            Spacer() // spacer between business name and cart items
            // Interactive cart list (with swipe actions and tap to edit)
            if showingClearCartCountdown && basket.isEmpty {
                // Empty cart countdown state
                VStack(spacing: 16) {
                    Text("Cart is empty")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .padding(.top, 40)

                    Spacer()

                    Text("Returning to shop in \(clearCartCountdown) seconds...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    // Green progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Background
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 8)
                                .cornerRadius(4)

                            // Progress
                            Rectangle()
                                .fill(Color.green)
                                .frame(width: geometry.size.width * CGFloat(6 - clearCartCountdown) / 5.0, height: 8)
                                .cornerRadius(4)
                                .animation(.linear(duration: 1.0), value: clearCartCountdown)
                        }
                    }
                    .frame(height: 8)

                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)
                .frame(maxHeight: min(500, CGFloat(150 + 40 * basket.count)))
            } else {
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
                .padding(.horizontal, 24)
                .padding(.top, 48) // Breathing room above cart
                .frame(maxHeight: min(500, CGFloat(150 + 40 * basket.count)))
            }

            // Everything below cart needs horizontal padding
            VStack(spacing: 0) {
                // Subtotal & Tax (only show Subtotal line if multiple items or if it's just visual separation)
                VStack(spacing: 8) {
                    // Only show subtotal line if there are multiple items OR no items
                    // Skip it if exactly 1 item (unless there's tax, then we need the breakdown)
                    if basket.count != 1 || taxAmountInCents > 0 {
                        if !isKeyboardVisible {
                            Divider()
                                .padding(.bottom, 8)
                        }
                        if basket.count != 1 {
                            HStack {
                                Text("Subtotal")
                                Spacer()
                                Text(formatMoney(subtotalInCents))
                                    .font(.system(.body, design: .monospaced))
                            }
                            .padding(.horizontal, 12)
                        }
                    }
                    if taxAmountInCents > 0 {
                        HStack {
                            Text("Tax")
                            Spacer()
                            Text(formatMoney(taxAmountInCents))
                                .font(.system(.body, design: .monospaced))
                        }
                        .padding(.horizontal, 12)
                    }

                    // Total line (only show if multiple items OR tax exists - otherwise item price = total)
                    if basket.count != 1 || taxAmountInCents > 0 {
                        HStack {
                            Text("Total")
                                .fontWeight(.semibold)
                            Spacer()
                            Text(formatMoney(totalAmountInCents))
                                .font(.system(.body, design: .monospaced))
                                .fontWeight(.semibold)
                        }
                        .padding(.horizontal, 12)
                        .padding(.top, 8)  // Extra space above total for visual separation
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
                    // Before payment: progressive disclosure for email
                    if !showEmailField && receiptEmail.isEmpty {
                        // Button to reveal email field (only show if email is empty)
                        Button(action: {
                            showEmailField = true
                            isEmailFieldFocused = true
                        }) {
                            HStack {
                                Image(systemName: "envelope")
                                Text("Email me a receipt")
                            }
                            .font(.subheadline)
                            .foregroundColor(.blue)
                        }
                        .padding(.bottom, 8)
                    } else if showEmailField || !receiptEmail.isEmpty {
                        // Email field with remove option
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Email for receipt")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Button("Remove") {
                                    showEmailField = false
                                    receiptEmail = ""
                                    isEmailFieldFocused = false
                                }
                                .font(.caption)
                                .foregroundColor(.secondary)
                            }
                            TextField("your@email.com", text: $receiptEmail)
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .textFieldStyle(.roundedBorder)
                                .focused($isEmailFieldFocused)
                                .toolbar {
                                    ToolbarItemGroup(placement: .keyboard) {
                                        Spacer()
                                        Button("Done") {
                                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                        }
                                    }
                                }
                        }
                        .padding(.bottom, 8)
                    }
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
                        Text("Dismissing in \(dismissCountdown)s")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)

                        // Green progress bar
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                // Background
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(height: 8)
                                    .cornerRadius(4)

                                // Progress
                                Rectangle()
                                    .fill(Color.green)
                                    .frame(width: geometry.size.width * CGFloat(31 - dismissCountdown) / 30.0, height: 8)
                                    .cornerRadius(4)
                                    .animation(.linear(duration: 1.0), value: dismissCountdown)
                            }
                        }
                        .frame(height: 8)
                        .padding(.horizontal, 40)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                } else if totalAmountInCents > 49 && !isKeyboardVisible {
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
                } else if !isKeyboardVisible {
                    Text("Minimum charge $0.50")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 16)
                }

                // Connection status
                if !isKeyboardVisible {
                    Text(connectionStatus)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.top, 16)
                        .padding(.bottom, 8)
                }

                Spacer()

                // Clear cart and Save cart buttons
                if !isKeyboardVisible && !showingClearCartCountdown {
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
                    .padding(.bottom, 4)
                }
            }
            .padding(.horizontal, 24)
        }
//        .padding(.bottom, 20)
        .background(Color(.systemBackground))
//        .background(Color(.red))
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

                // Start countdown timer
                dismissCountdown = 30
                dismissTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
                    if dismissCountdown > 0 {
                        dismissCountdown -= 1
                    } else {
                        timer.invalidate()
                        dismissTimer = nil
                        onDismiss()
                    }
                }
            }
        }
        .onChange(of: isEmailFieldFocused) { isFocused in
            if isFocused && showingClearCartCountdown {
                // User tapped email field during countdown - abort timer
                clearCartTimer?.invalidate()
                clearCartTimer = nil
                showingClearCartCountdown = false
            }
        }
        .alert("Clear Cart?", isPresented: $showingClearCartAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                basket.removeAll()
                receiptEmail = ""
                showingClearCartCountdown = true
                clearCartCountdown = 5

                // Start countdown timer
                clearCartTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
                    if clearCartCountdown > 0 {
                        clearCartCountdown -= 1
                    } else {
                        timer.invalidate()
                        clearCartTimer = nil
                        showingClearCartCountdown = false
                        dismiss()
                    }
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
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            isKeyboardVisible = true
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            isKeyboardVisible = false
        }
        .onDisappear {
            // Cancel timers if sheet dismissed
            dismissTimer?.invalidate()
            dismissTimer = nil
            clearCartTimer?.invalidate()
            clearCartTimer = nil
            // If payment succeeded and user manually dismissed, trigger cleanup
            if paymentSucceeded {
                onDismiss()
            }
        }
    }
}
