//    ContentView.swift

import SwiftUI

//extension NumberFormatter // no, define in separate file in utils/ folder

struct ContentView: View {
    @State private var amountInCents: Int = 0
    @State private var basket: [CartItem] = []
    @State private var connectionStatus = "Not connected"

    @State private var savedProducts: [Product] = UserDefaults.standard.savedProducts
    @State private var myAccentColor: Color = UserDefaults.standard.myAccentColor
    @State private var darkModePreference: String = UserDefaults.standard.darkModePreference
    @State private var businessName: String = UserDefaults.standard.businessName
    @State private var taxRate: Double = UserDefaults.standard.taxRate
    @State private var dismissKeypadAfterAdd: String = UserDefaults.standard.dismissKeypadAfterAdd
    @State private var inputMode: String = UserDefaults.standard.inputMode
    @State private var isKeypadActive: Bool = false

    @State private var editingItem: CartItem? = nil
    @State private var showQuantityEditor = false
    @State private var showCheckoutSheet = false

    // Animation state for cart row updates
    @State private var lastChangedItemId: UUID? = nil
    @State private var isAnimatingQuantity: Bool = false

    // Image cache to prevent repeated file I/O during animations
    @State private var imageCache: [String: UIImage] = [:]

    // Product icon sizing constant
    private let productIconSize: CGFloat = 40

    let readerDiscoveryController = ReaderDiscoveryViewController()

    var subtotalInCents: Int {
       basket.reduce(0) { total, item in
           let current = getCurrentProduct(for: item)
           return total + (current.priceInCents * item.quantity)
       }
    }

    var taxAmountInCents: Int {
        if taxRate > 0 {
            return Int(round(Double(subtotalInCents) * taxRate / 100.0))
        }
        return 0
    }

    var totalAmountInCents: Int {
        return subtotalInCents + taxAmountInCents
    }

    // Helper to get next manual item name
    private func nextManualItemName() -> String {
        let manualItemCount = basket.filter { !$0.isProduct }.count
        return "Item \(manualItemCount + 1)"
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
        let rounded = round(taxRate * 100) / 100  // Round to 2 decimals
        if rounded.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", rounded)
        } else if (rounded * 10).truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.1f", rounded)
        } else {
            return String(format: "%.2f", rounded)
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
            VStack {
                // Tappable amount display (triggers custom keypad)
                AmountInputButton(
                    amountInCents: amountInCents,
                    formatAmount: { formatCurrency($0, forceDecimals: true) },
                    onTap: { isKeypadActive = true }
                )
                .padding(.bottom, 12)

//                HStack {
//                    Text("Quick add items")
//                        .font(.caption)
//                        .foregroundColor(.gray)
//                        .multilineTextAlignment(.leading)
//                        .padding(.top, 8)
//                    Spacer()
//                }

                let columns = [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ]

                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(savedProducts.filter({ $0.priceInCents > 0 && ($0.emoji != nil || $0.photoFilename != nil) }), id: \.id) { product in
                        let quantityInCart = basket.first(where: { $0.productId == product.id && $0.isProduct })?.quantity ?? 0

                        Button(action: {
                            // Check if this product is already in the cart
                            if let index = basket.firstIndex(where: { $0.productId == product.id && $0.isProduct }) {
                                // Increment quantity with animation
                                let itemId = basket[index].id
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    basket[index].quantity += 1
                                }
                                lastChangedItemId = itemId
                                isAnimatingQuantity = true

                                // Reset animation state
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    lastChangedItemId = nil
                                    isAnimatingQuantity = false
                                }
                            } else {
                                // Add new product to cart
                                let item = CartItem(
                                    productId: product.id,
                                    name: product.name,
                                    priceInCents: product.priceInCents,
                                    quantity: 1,
                                    isProduct: true
                                )
                                basket.append(item)
                            }
                        }) {
                            VStack(spacing: 4) {
                                // Show photo or emoji
                                if let photoFilename = product.photoFilename,
                                   let image = getCachedImage(for: photoFilename) {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: productIconSize, height: productIconSize)
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                } else if let emoji = product.emoji {
                                    Text(emoji)
                                        .font(.system(size: productIconSize - 4))
                                        .frame(width: productIconSize, height: productIconSize)
                                }

                                Text(product.name)
                                    .font(.caption)
                                    .lineLimit(1)
                                Text(formatCurrency(product.priceInCents))
                                    .font(.body)
                                    .fontWeight(.medium)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .padding()
                        .background(Color.clear)
                        .foregroundColor(.primary)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(quantityInCart > 0 ? Color.blue : Color.gray,  lineWidth: quantityInCart > 0 ? 3 : 1)
                        )
                        .overlay(alignment: .topLeading) {
                            // Quantity badge in top-left corner
                            if quantityInCart > 0 {
                                Text("\(quantityInCart)")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 4)
                                    .background(
                                        Capsule()
                                            .fill(Color.blue)
                                            .frame(minWidth: 22, minHeight: 22)
                                    )
                                    .offset(x: -2, y: -2)
                            }
                        }
                    }
                }
                .padding([.leading, .trailing])
                .padding([.top], 4)
                .padding([.bottom], 14)

                if !basket.isEmpty {
//                    Divider() // divider above Cart
                    HStack {
                        Text("Cart").font(.headline)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.leading)
                            .padding(.bottom, 2)
                            .padding(.top, 2) // was .top, 16
                            .padding(.horizontal, 16) // 4pt outer + 12pt to match cart row content
                        Spacer()
                    }
                }
                List {
                    Section {
                        if basket.isEmpty {
                            Text("Cart is empty").font(.subheadline)
//                                .foregroundColor(Color(.systemGray2))
                        }
                        ForEach(basket) { item in
                            let current = getCurrentProduct(for: item)
                            HStack(spacing: 2) {
                                // Icon column (fixed width for alignment)
                                HStack(spacing: 0) {
                                    if item.isProduct, let product = savedProducts.first(where: { $0.id == item.productId }) {
                                        if let photoFilename = product.photoFilename,
                                           let image = getCachedImage(for: photoFilename) {
                                            Image(uiImage: image)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 30, height: 30)
                                                .clipShape(Circle())
                                        } else if let emoji = product.emoji {
                                            Text(emoji)
                                                .font(.title3)
                                        }
                                    }
                                }
                                .frame(width: 34, alignment: .leading)

                                // Product name (left-aligned, live lookup)
                                Text(current.name)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                // Quantity (right-aligned, monospace) - only show if not all items are qty 1
                                if !allItemsQuantityOne {
                                    Text("×\(item.quantity)")
                                        .font(.system(.body, design: .monospaced))
                                        .foregroundColor(.secondary)
                                        .frame(minWidth: 40, alignment: .trailing)
                                        .scaleEffect(lastChangedItemId == item.id && isAnimatingQuantity ? 1.1 : 1.0)
                                }

                                // Total price (right-aligned, monospace, live price)
                                Text(formatCurrency(current.priceInCents * item.quantity, forceDecimals: cartHasAnyCents))
                                    .font(.system(.body, design: .monospaced))
                                    .frame(width: 110, alignment: .trailing)
                            }
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(
                                        lastChangedItemId == item.id && isAnimatingQuantity
                                            ? Color.blue.opacity(0.15)
                                            : Color.clear
                                    )
                            )
                            .padding(.horizontal, 4)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                editingItem = item
                            }
                            .swipeActions(edge: .leading) {
                                Button {
                                    if let index = basket.firstIndex(where: { $0.id == item.id }) {
                                        let itemId = basket[index].id
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            basket[index].quantity += 1
                                        }
                                        lastChangedItemId = itemId
                                        isAnimatingQuantity = true

                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                            lastChangedItemId = nil
                                            isAnimatingQuantity = false
                                        }
                                    }
                                } label: {
                                    Label("1", systemImage: "plus")
                                }
                                .tint(.green)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                // Only show -1 button if quantity > 1
                                if item.quantity > 1 {
                                    Button {
                                        if let index = basket.firstIndex(where: { $0.id == item.id }) {
                                            let itemId = basket[index].id
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                basket[index].quantity -= 1
                                            }
                                            lastChangedItemId = itemId
                                            isAnimatingQuantity = true

                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                                lastChangedItemId = nil
                                                isAnimatingQuantity = false
                                            }
                                        }
                                    } label: {
                                        Label("1", systemImage: "minus")
                                    }
                                    .tint(.orange)
                                }

                                Button(role: .destructive) {
                                    if let index = basket.firstIndex(where: { $0.id == item.id }) {
                                        basket.remove(at: index)
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .listRowInsets(EdgeInsets())
                        }
                    } footer: {
                        if !basket.isEmpty {
                            Text("Swipe any row right or left to add or remove")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                    }
                }
                .listStyle(.plain) // this removes the systemGray6 background; without style plain, the rows have rounded corners
                

//                Spacer()

                // Tax summary (only if tax > 0 and cart not empty)
                if taxRate > 0 && !basket.isEmpty {
                    VStack(spacing: 8) {
                        HStack(spacing: 12) {
                            Text("Subtotal")
                                .font(.subheadline)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            // Empty space matching quantity column width (only if quantity column shown)
                            if !allItemsQuantityOne {
                                Text("")
                                    .frame(minWidth: 40, alignment: .trailing)
                            }

                            Text(formatCurrency(subtotalInCents, forceDecimals: taxSummaryHasCents))
                                .font(.system(.subheadline, design: .monospaced))
                                .frame(minWidth: 60, alignment: .trailing)
                        }
                        .padding(.horizontal, 20)

                        HStack(spacing: 12) {
                            Text("Tax (\(formattedTaxRate)%)")
                                .font(.subheadline)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            // Empty space matching quantity column width (only if quantity column shown)
                            if !allItemsQuantityOne {
                                Text("")
                                    .frame(minWidth: 40, alignment: .trailing)
                            }

                            Text(formatCurrency(taxAmountInCents, forceDecimals: taxSummaryHasCents))
                                .font(.system(.subheadline, design: .monospaced))
                                .frame(minWidth: 60, alignment: .trailing)
                        }
                        .padding(.horizontal, 20)

                        Divider()
                            .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 8)
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
                } else if totalAmountInCents > 0 && totalAmountInCents <= 49 {
                    Text("Total amount must be > $0.49. Add more items to cart.")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            .padding()
            .onAppear {
                readerDiscoveryController.updateConnectionStatus = { status in
                    self.connectionStatus = status
                }
                readerDiscoveryController.viewDidLoad()

                // next lines so the changes we make in settings are reflected immediately, without needing to restart the app
                savedProducts = UserDefaults.standard.savedProducts
                myAccentColor = UserDefaults.standard.myAccentColor
                darkModePreference = UserDefaults.standard.darkModePreference
                businessName = UserDefaults.standard.businessName
                taxRate = UserDefaults.standard.taxRate
                dismissKeypadAfterAdd = UserDefaults.standard.dismissKeypadAfterAdd
                inputMode = UserDefaults.standard.inputMode
                applyDarkModePreference()
            }
            .navigationTitle(businessName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Text("Admin").foregroundColor(myAccentColor)
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
                    .presentationDetents([.fraction(0.7), .large])
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
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showCheckoutSheet) {
                CheckoutSheet(
                    basket: $basket,
                    subtotalInCents: subtotalInCents,
                    taxAmountInCents: taxAmountInCents,
                    totalAmountInCents: totalAmountInCents,
                    formattedTotalAmount: formattedTotalAmount,
                    connectionStatus: connectionStatus,
                    onCharge: {
                        do {
                            try readerDiscoveryController.checkoutAction(amount: totalAmountInCents)
                        } catch {
                            print("Error occurred: \(error)")
                        }
                    }
                )
                .presentationDetents([/*.medium, */.large])
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
            Text(amountInCents > 0 ? formatAmount(amountInCents) : "Enter amount")
                .font(.title)
                .foregroundColor(amountInCents > 0 ? .primary : .secondary)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
        }
    }
}

