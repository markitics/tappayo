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
    @State private var showingSaveCartAlert = false
    @State private var isKeyboardVisible = false
    @State private var dismissCountdown: Int = 30
    @State private var dismissTimer: Timer? = nil
    @State private var clearCartCountdown: Int = 5
    @State private var clearCartTimer: Timer? = nil
    @State private var showingClearCartCountdown = false
    @State private var showEmailField = false
    @FocusState private var isEmailFieldFocused: Bool
    @Binding var receiptEmail: String
    @State private var selectedTipPercentage: Double = 0.0  // 0, 12, 18, or 22
    @Environment(\.dismiss) private var dismiss

    let businessName: String
    let tippingEnabled: Bool
    let subtotalInCents: Int
    let taxAmountInCents: Int
    let totalAmountInCents: Int
    let formattedTotalAmount: String
    let connectionStatus: String
    let isProcessingPayment: Bool
    let paymentSucceeded: Bool
    let onCharge: (Int, String?) -> Void  // (amountInCents, email)
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

    // Tip calculation
    private var tipAmountInCents: Int {
        guard tippingEnabled else { return 0 }
        return Int(round(Double(subtotalInCents) * selectedTipPercentage / 100.0))
    }

    // Total with tip
    private var totalWithTipInCents: Int {
        return subtotalInCents + taxAmountInCents + tipAmountInCents
    }

    var body: some View {
        GeometryReader { geometry in
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

            // Hide cart items when email field is focused (keyboard takes up too much space)
            if !isEmailFieldFocused {
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
                                    .frame(width: geometry.size.width, height: 8)
                                    .cornerRadius(4)

                                // Progress
                                Rectangle()
                                    .fill(Color.green)
                                    .frame(width: geometry.size.width * CGFloat(5 - clearCartCountdown) / 5.0, height: 8)
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
                    .listStyle(.plain)
                    .padding(.horizontal, 24)
                    .padding(.top, 48) // Breathing room above cart
                    .frame(maxHeight: {
                        // Calculate fixed UI height (breakdown, email, tip, pay button, etc.)
                        let fixedUIHeight: CGFloat = 500 // Approximate: breakdown + email + tip selector + buttons + padding
                        let availableHeight = geometry.size.height - fixedUIHeight
                        let desiredHeight = CGFloat(200 + 50 * basket.count)
                        return max(200, min(availableHeight, desiredHeight)) // Minimum 200, max available
                    }())
                }
            }

            // Everything below cart needs horizontal padding
            VStack(spacing: 0) {
                // Subtotal, Tax, Tip, Total breakdown
                VStack(spacing: 8) {
                    // Show Subtotal only when there's a breakdown (tax > 0 or tip > 0)
                    let hasBreakdown = taxAmountInCents > 0 || tipAmountInCents > 0

                    if hasBreakdown {
                        HStack {
                            Text("Subtotal")
                            Spacer()
                            Text(formatMoney(subtotalInCents))
                                .font(.system(.body, design: .monospaced))
                        }
                        .padding(.horizontal, 12)
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

                    if tippingEnabled { // alternatively could have condition "if tipAmountInCents > 0" to keep things clean, but then UI jumpts around if we go from 0% to 18% (adding 1-2 more lines, maybe adding subtotal line, and def adding the 'Tip' line. Having this condition be "if tipppingEnabled" means we start with a "Tip      $0.00" line by defaul
                        HStack {
                            Text("Tip")
                            Spacer()
                            Text(formatMoney(tipAmountInCents))
                                .font(.system(.body, design: .monospaced))
                        }
                        .padding(.horizontal, 12)
                    }

                    // Total line - show when multiple items OR breakdown exists (tax/tip)
                    // Hide when single item with no tax/tip (item price = total, so redundant)
                    if basket.count != 1 || taxAmountInCents > 0 || tipAmountInCents > 0 {
                        HStack {
                            Text("Total")
                                .fontWeight(.semibold)
                            Spacer()
                            Text(formatMoney(totalWithTipInCents))
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
                                Text("Email for receipt")
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
                                .font(.body)
                                .submitLabel(.done)
                                .onSubmit {
                                    isEmailFieldFocused = false
                                }
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

                // Tip selector (only show if tipping enabled and before payment)
                if tippingEnabled && !paymentSucceeded {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tip")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        // Four conjoined tip buttons
                        HStack(spacing: 0) {
                            TipButton(percentage: 0, selectedPercentage: $selectedTipPercentage, position: .leading)
                            TipButton(percentage: 12, selectedPercentage: $selectedTipPercentage, position: .middle)
                            TipButton(percentage: 18, selectedPercentage: $selectedTipPercentage, position: .middle)
                            TipButton(percentage: 22, selectedPercentage: $selectedTipPercentage, position: .trailing)
                        }
                        .frame(height: 44)
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
                                    .frame(width: geometry.size.width, height: 8)
                                    .cornerRadius(4)

                                // Progress
                                Rectangle()
                                    .fill(Color.green)
                                    .frame(width: geometry.size.width * CGFloat(30 - dismissCountdown) / 30.0, height: 8)
                                    .cornerRadius(4)
                                    .animation(.linear(duration: 1.0), value: dismissCountdown)
                            }
                        }
                        .frame(height: 8)
                        .padding(.horizontal, 40)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                } else if totalWithTipInCents > 49 && !isKeyboardVisible {
                    Button(action: {
                        // Dismiss keyboard before processing payment
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        onCharge(totalWithTipInCents, receiptEmail.isEmpty ? nil : receiptEmail)
                    }) {
                        HStack {
                            Image(systemName: "wave.3.right.circle.fill")
                            Text("Pay \(formatMoney(totalWithTipInCents))")
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
                        showingSaveCartAlert = true
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
        .onChange(of: paymentSucceeded) { _, newValue in
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
        .onChange(of: isEmailFieldFocused) { _, isFocused in
            if isFocused && showingClearCartCountdown {
                // User tapped email field during countdown - abort timer
                clearCartTimer?.invalidate()
                clearCartTimer = nil
                showingClearCartCountdown = false
            }

            // If email field loses focus and is empty, collapse back to button
            if !isFocused && receiptEmail.isEmpty {
                showEmailField = false
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
        .alert("Feature Not Available", isPresented: $showingSaveCartAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("This feature isn't live yet. Contact us to vote for which feature we should add next!")
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
        .interactiveDismissDisabled(isKeyboardVisible) // Prevent swipe-down from dismissing sheet when keyboard is visible
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
            } // Close VStack
        } // Close GeometryReader
    }

// MARK: - Tip Button Component

enum ButtonPosition {
    case leading, middle, trailing
}

struct TipButton: View {
    let percentage: Double
    @Binding var selectedPercentage: Double
    let position: ButtonPosition

    private var isSelected: Bool {
        selectedPercentage == percentage
    }

    private var cornerRadius: CGFloat { 8 }

    var body: some View {
        Group {
            switch position {
            case .leading:
                leadingButton
            case .middle:
                middleButton
            case .trailing:
                trailingButton
            }
        }
    }

    private var leadingButton: some View {
        Button(action: { selectedPercentage = percentage }) {
            Text(percentage == 0 ? "None" : "\(Int(percentage))%")
                .font(.body)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : .blue)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(isSelected ? Color.blue : Color(UIColor.secondarySystemGroupedBackground))
                .clipShape(UnevenRoundedRectangle(
                    topLeadingRadius: cornerRadius,
                    bottomLeadingRadius: cornerRadius,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: 0
                ))
                .overlay(
                    UnevenRoundedRectangle(
                        topLeadingRadius: cornerRadius,
                        bottomLeadingRadius: cornerRadius,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: 0
                    )
                    .stroke(Color.blue, lineWidth: 1)
                )
        }
    }

    private var middleButton: some View {
        Button(action: { selectedPercentage = percentage }) {
            Text(percentage == 0 ? "None" : "\(Int(percentage))%")
                .font(.body)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : .blue)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(isSelected ? Color.blue : Color(UIColor.secondarySystemGroupedBackground))
                .clipShape(Rectangle())
                .overlay(Rectangle().stroke(Color.blue, lineWidth: 1))
        }
    }

    private var trailingButton: some View {
        Button(action: { selectedPercentage = percentage }) {
            Text(percentage == 0 ? "None" : "\(Int(percentage))%")
                .font(.body)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : .blue)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(isSelected ? Color.blue : Color(UIColor.secondarySystemGroupedBackground))
                .clipShape(UnevenRoundedRectangle(
                    topLeadingRadius: 0,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: cornerRadius,
                    topTrailingRadius: cornerRadius
                ))
                .overlay(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 0,
                        bottomLeadingRadius: 0,
                        bottomTrailingRadius: cornerRadius,
                        topTrailingRadius: cornerRadius
                    )
                    .stroke(Color.blue, lineWidth: 1)
                )
        }
    }
}
