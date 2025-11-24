//    ContentView.swift

import SwiftUI

//extension NumberFormatter // no, define in separate file in utils/ folder

struct ContentView: View {
    @State private var amountInCents: Int = 0
    @State private var basket: [CartItem] = []
    @State private var connectionStatus = "Not connected"
    @State private var isProcessingPayment = false
    @State private var receiptEmail = ""
    @State private var paymentSucceeded = false

    @State private var savedProducts: [Product] = UserDefaults.standard.savedProducts
    @State private var myAccentColor: Color = UserDefaults.standard.myAccentColor
    @State private var darkModePreference: String = UserDefaults.standard.darkModePreference
    @State private var businessName: String = UserDefaults.standard.businessName
    @State private var taxRateBasisPoints: Int = UserDefaults.standard.taxRateBasisPoints
    @State private var taxEnabled: Bool = UserDefaults.standard.taxEnabled
    @State private var tippingEnabled: Bool = UserDefaults.standard.tippingEnabled
    @State private var dismissKeypadAfterAdd: String = UserDefaults.standard.dismissKeypadAfterAdd
    @State private var inputMode: String = UserDefaults.standard.inputMode
    @State private var isKeypadActive: Bool = false

    @State private var editingItem: CartItem? = nil
    @State private var showQuantityEditor = false
    @State private var showCheckoutSheet = false
    @State private var isEmailFieldFocused = false

    // Animation state for cart row updates
    @State private var lastChangedItemId: UUID? = nil
    @State private var isAnimatingQuantity: Bool = false

    // Image cache to prevent repeated file I/O during animations
    @State private var imageCache: [String: UIImage] = [:]

    // Product icon sizing constant
    private let productIconSize: CGFloat = 40

    // Horizontal padding constant for consistent spacing
    private let horizontalPadding: CGFloat = 32

    // Vertical spacing between product tiles
    private let productGridSpacing: CGFloat = 14

    let readerDiscoveryController = ReaderDiscoveryViewController()

    var subtotalInCents: Int {
       basket.reduce(0) { total, item in
           let current = getCurrentProduct(for: item)
           return total + (current.priceInCents * item.quantity)
       }
    }

    var taxAmountInCents: Int {
        if taxEnabled && taxRateBasisPoints > 0 {
            // taxRateBasisPoints is stored as basis points (1000 = 10.00%)
            // So divide by 10000 to get the decimal multiplier
            return Int(round(Double(subtotalInCents) * Double(taxRateBasisPoints) / 10000.0))
        }
        return 0
    }

    var totalAmountInCents: Int {
        return subtotalInCents + taxAmountInCents
    }

    // Helper to get next manual item name
    private func nextManualItemName() -> String {
        let manualItemCount = basket.filter { !$0.isProduct }.count
        return "Custom Item \(manualItemCount + 1)"
    }

    // Helper to get cached image (loads from disk only once per photo)
    private func getCachedImage(for filename: String) -> UIImage? {
        if let cached = imageCache[filename] {
            return cached
        }
        if let loaded = PhotoStorageHelper.loadPhoto(filename) {
            imageCache[filename] = loaded
            return loaded
        }
        return nil
    }

    // Unified currency formatter with smart decimals and comma separators
    private func formatCurrency(_ cents: Int, forceDecimals: Bool = false) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        formatter.usesGroupingSeparator = true

        // Smart decimal logic: show .00 only when needed
        let shouldShowDecimals = forceDecimals || (cents % 100 != 0)
        formatter.minimumFractionDigits = shouldShowDecimals ? 2 : 0
        formatter.maximumFractionDigits = shouldShowDecimals ? 2 : 0

        return formatter.string(from: NSNumber(value: Double(cents) / 100)) ?? "$0.00"
    }

    // Check if any cart item has cents (for consistent formatting)
    private var cartHasAnyCents: Bool {
        basket.contains { item in
            let current = getCurrentProduct(for: item)
            let total = current.priceInCents * item.quantity
            return total % 100 != 0
        }
    }

    // Check if tax summary (subtotal or tax) has cents
    private var taxSummaryHasCents: Bool {
        return subtotalInCents % 100 != 0 || taxAmountInCents % 100 != 0
    }

    // Format tax rate for display (up to 2 decimals, drop trailing zeros)
    private var formattedTaxRate: String {
        let percentage = Double(taxRateBasisPoints) / 100.0
        if percentage.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", percentage)
        } else if (percentage * 10).truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.1f", percentage)
        } else {
            return String(format: "%.2f", percentage)
        }
    }

    // Check if all cart items have quantity of 1
    private var allItemsQuantityOne: Bool {
        return !basket.isEmpty && basket.allSatisfy { $0.quantity == 1 }
    }

    // Helper to get current product data (live lookup for saved products)
    private func getCurrentProduct(for item: CartItem) -> (name: String, priceInCents: Int) {
        // If it's a saved product, look up current data from savedProducts
        if item.isProduct,
           let productId = item.productId,
           let product = savedProducts.first(where: { $0.id == productId }) {
            return (product.name, product.priceInCents)
        }
        // Otherwise use stored values (manual entries or deleted products)
        return (item.name, item.priceInCents)
    }

    var formattedTotalAmount: String {
        // Remove $ prefix since it's added in the UI context
        let formatted = formatCurrency(totalAmountInCents)
        return formatted.replacingOccurrences(of: "$", with: "")
    }

    var body: some View {
        ZStack {
        NavigationView {
            VStack(spacing: 0) {
                // Tappable amount display (triggers custom keypad)
                AmountInputButton(
                    amountInCents: amountInCents,
                    formatAmount: { formatCurrency($0, forceDecimals: true) },
                    onTap: { isKeypadActive = true }
                )
                .padding(.bottom, productGridSpacing)
                .padding(.horizontal, horizontalPadding)

//                HStack {
//                    Text("Quick add items")
//                        .font(.caption)
//                        .foregroundColor(.gray)
//                        .multilineTextAlignment(.leading)
//                        .padding(.top, 8)
//                    Spacer()
//                }

                let columns = [
                    GridItem(.flexible(), spacing: productGridSpacing),
                    GridItem(.flexible(), spacing: productGridSpacing),
                    GridItem(.flexible(), spacing: productGridSpacing)
                ]

                LazyVGrid(columns: columns, spacing: productGridSpacing) {
                    // used to also have requirement that to appear in shop, Product needed an image or emoji:
                    // $0.priceInCents > 0 && $0.isVisible && ($0.emoji != nil || $0.photoFilename != nil)
                    ForEach(savedProducts.filter({ $0.priceInCents > 0 && $0.isVisible }), id: \.id) { product in
                        let quantityInCart = basket.first(where: { $0.productId == product.id && $0.isProduct })?.quantity ?? 0

                        ProductGridButton(
                            product: product,
                            quantityInCart: quantityInCart,
                            productIconSize: productIconSize,
                            basket: $basket,
                            lastChangedItemId: $lastChangedItemId,
                            isAnimatingQuantity: $isAnimatingQuantity,
                            getCachedImage: getCachedImage,
                            formatCurrency: formatCurrency
                        )
                    }
                }
                .padding(.horizontal, horizontalPadding)
                .padding([.bottom], productGridSpacing+2) // optically we actually need slightly more spacing here (eyball'd it)

                // Edit: removing this heading entirely for now (temporary; to review)
//                if !basket.isEmpty {
////                    Divider() // divider above Cart
//                    HStack {
//                        Text("Cart").font(.headline)
//                            .fontWeight(.bold)
//                            .multilineTextAlignment(.leading)
//                            .padding(.bottom, 8)
//                            .padding(.top, 16) // was .top, 16
//                            .padding(.horizontal, 16) // 4pt outer + 12pt to match cart row content
//                            .background(Color(.systemGroupedBackground))
//                        Spacer()
//                    }
//                }
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
                

//                Spacer()

                // Tax summary (only if tax enabled and cart not empty)
                if taxEnabled && taxRateBasisPoints > 0 && !basket.isEmpty {
                    VStack(spacing: 8) {
                        HStack(spacing: 12) {
                            Text("Subtotal")
                                .font(.body)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            // Empty space matching quantity column width (only if quantity column shown)
                            if !allItemsQuantityOne {
                                Text("")
                                    .frame(minWidth: 40, alignment: .trailing)
                            }

                            Text(formatCurrency(subtotalInCents, forceDecimals: taxSummaryHasCents))
                                .font(.system(.body, design: .monospaced))
                                .frame(minWidth: 60, alignment: .trailing)
                        }

                        HStack(spacing: 12) {
                            Text("Tax (\(formattedTaxRate)%)")
                                .font(.body)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            // Empty space matching quantity column width (only if quantity column shown)
                            if !allItemsQuantityOne {
                                Text("")
                                    .frame(minWidth: 40, alignment: .trailing)
                            }

                            Text(formatCurrency(taxAmountInCents, forceDecimals: taxSummaryHasCents))
                                .font(.system(.body, design: .monospaced))
                                .frame(minWidth: 60, alignment: .trailing)
                        }

                        Divider()
                    }
                    .padding(.bottom, 8)
                    .padding(.horizontal, horizontalPadding)
                }

                if totalAmountInCents > 49 {
                    Button(action: {
                        showCheckoutSheet = true
                    }) {
                        HStack{
//                            wave.3.right.circle.fill or wave.3.right.circle
//                            Image(systemName: "wave.3.right.circle.fill")
                            Text("Review $\(formattedTotalAmount)").font(.title2)
                            .fontWeight(/*@START_MENU_TOKEN@*/.medium/*@END_MENU_TOKEN@*/)
                        }
                    }
                    .padding()
                    .background(.blue) // or accentColor
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .disabled(totalAmountInCents == 0)
                    .padding(.horizontal, horizontalPadding)
                } else if totalAmountInCents > 0 && totalAmountInCents <= 49 {
                    Text("Total amount must be > $0.49. Add more items to cart.")
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal, horizontalPadding)
                }
            }
            .padding(.vertical) // this was simply .padding(), I want cartlistview to extend entirely left/right in light mode, so we have that grey gradient background
            .onAppear {
                readerDiscoveryController.updateConnectionStatus = { status in
                    self.connectionStatus = status
                }
                readerDiscoveryController.updatePaymentProcessing = { isProcessing in
                    self.isProcessingPayment = isProcessing
                }
                readerDiscoveryController.onPaymentSuccess = {
                    self.paymentSucceeded = true
                    // Timer and cleanup now managed by CheckoutSheet
                }
                readerDiscoveryController.viewDidLoad()

                // next lines so the changes we make in settings are reflected immediately, without needing to restart the app
                savedProducts = UserDefaults.standard.savedProducts
                myAccentColor = UserDefaults.standard.myAccentColor
                darkModePreference = UserDefaults.standard.darkModePreference
                businessName = UserDefaults.standard.businessName
                taxRateBasisPoints = UserDefaults.standard.taxRateBasisPoints
                taxEnabled = UserDefaults.standard.taxEnabled
                tippingEnabled = UserDefaults.standard.tippingEnabled
                dismissKeypadAfterAdd = UserDefaults.standard.dismissKeypadAfterAdd
                inputMode = UserDefaults.standard.inputMode
                applyDarkModePreference()
            }
            .navigationTitle(businessName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Text("Admin").font(.body).foregroundColor(myAccentColor)
                    }
                }
            }
            .background( // this is to dismiss the keyboard when the user taps outside the text field
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
            )
            .sheet(item: $editingItem) { item in
                if let index = basket.firstIndex(where: { $0.id == item.id }) {
                    ItemEditorView(
                        item: item,
                        basketIndex: index,
                        basket: $basket,
                        savedProducts: $savedProducts,
                        formatAmount: formatCurrency
                    )
                    .presentationDetents([.fraction(0.89), .large]) // detents of cart row item editor
                    .presentationDragIndicator(.visible)
                }
            }
            .sheet(isPresented: $isKeypadActive) {
                CustomKeypadView(
                    amountInCents: $amountInCents,
                    onAddToCart: {
                        // Add to cart action
                        let item = CartItem(
                            name: nextManualItemName(),
                            priceInCents: amountInCents,
                            quantity: 1,
                            isProduct: false
                        )
                        basket.append(item)
                        amountInCents = 0

                        // Dismiss keypad if setting is "dismiss"
                        if dismissKeypadAfterAdd == "dismiss" {
                            isKeypadActive = false
                        }
                    },
                    onCancel: {
                        amountInCents = 0
                        isKeypadActive = false
                    },
                    inputMode: inputMode
                )
//                .presentationDetents([.fraction(0.8), .large]) // original detents of the keypad, but if not max-size (large), then ios sheet animations distract from button-presses. Work-around, just have full-screen mode, so the only visual response when I touch a button is the custom animation we have (swelling button size, blue tint, then bounce back to original size with extraBounce
                .presentationDetents([.large]) // new detents of the keypad (force full-screen only)
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showCheckoutSheet) {
                CheckoutSheet(
                    basket: $basket,
                    savedProducts: $savedProducts,
                    lastChangedItemId: $lastChangedItemId,
                    isAnimatingQuantity: $isAnimatingQuantity,
                    isEmailFieldFocused: $isEmailFieldFocused,
                    receiptEmail: $receiptEmail,
                    businessName: businessName,
                    tippingEnabled: tippingEnabled,
                    subtotalInCents: subtotalInCents,
                    taxAmountInCents: taxAmountInCents,
                    totalAmountInCents: totalAmountInCents,
                    formattedTotalAmount: formattedTotalAmount,
                    connectionStatus: connectionStatus,
                    isProcessingPayment: isProcessingPayment,
                    paymentSucceeded: paymentSucceeded,
                    onCharge: { amountInCents, email in
                        do {
                            try readerDiscoveryController.checkoutAction(amount: amountInCents, receiptEmail: email)
                        } catch {
                            print("Error occurred: \(error)")
                        }
                    },
                    onDismiss: {
                        self.basket.removeAll()
                        self.receiptEmail = ""
                        self.paymentSucceeded = false
                        self.showCheckoutSheet = false
                    },
                    getCurrentProduct: getCurrentProduct,
                    formatCurrency: formatCurrency,
                    getCachedImage: getCachedImage,
                    allItemsQuantityOne: allItemsQuantityOne,
                    cartHasAnyCents: cartHasAnyCents
                )
                .presentationDetents(isEmailFieldFocused
                    ? [.fraction(0.6), .large]  // Shorter when keyboard visible
                    : [.fraction(0.96), .large]) // Full height normally (0.96 = preferred, leave a little room on top to see the business name in the background, and to make it obvious it's a sheet we can dismiss down; .large is full-screen if we really want max height to view items)
                .presentationDragIndicator(.visible)
            }
        }
    }
    }

    private func deleteItem(at offsets: IndexSet) {
        basket.remove(atOffsets: offsets)
    }
    
//    private 
    func applyDarkModePreference() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        guard let window = windowScene.windows.first else { return }
        switch darkModePreference {
        case "on":
            window.overrideUserInterfaceStyle = .dark
        case "off":
            window.overrideUserInterfaceStyle = .light
        default:
            window.overrideUserInterfaceStyle = .unspecified
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct AmountInputButton: View {
    let amountInCents: Int
    let formatAmount: (Int) -> String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Text("Custom amount")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(formatAmount(amountInCents))
                    .font(.body)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 70)
            .padding()
            .contentShape(Rectangle())
        }
        .foregroundColor(.primary)
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray, lineWidth: 1)
        )
    }
}

