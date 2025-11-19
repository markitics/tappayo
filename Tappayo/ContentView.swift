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
    @State private var showPlusMinusButtons: Bool = UserDefaults.standard.showPlusMinusButtons
    @State private var businessName: String = UserDefaults.standard.businessName
    @State private var taxRate: Double = UserDefaults.standard.taxRate
    @State private var dismissKeypadAfterAdd: String = UserDefaults.standard.dismissKeypadAfterAdd
    @State private var inputMode: String = UserDefaults.standard.inputMode
    @State private var isKeypadActive: Bool = false

    @State private var editingItem: CartItem? = nil
    @State private var showQuantityEditor = false
    @State private var showCheckoutSheet = false

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

    // Helper to format currency cleanly (no .00 for whole dollars)
    private func formatCurrency(_ cents: Int) -> String {
        let dollars = Double(cents) / 100.0
        if cents % 100 == 0 {
            return String(format: "$%.0f", dollars)
        } else {
            return String(format: "$%.2f", dollars)
        }
    }

    // Helper to format amount for display (always with decimals)
    private func formatAmount(_ cents: Int) -> String {
        let dollars = Double(cents) / 100.0
        return String(format: "$%.2f", dollars)
    }

    // Helper to format cart amounts with consistent decimal places
    private func formatCartAmount(_ cents: Int, forceDecimals: Bool) -> String {
        let dollars = Double(cents) / 100.0
        if forceDecimals || cents % 100 != 0 {
            return String(format: "$%.2f", dollars)
        } else {
            return String(format: "$%.0f", dollars)
        }
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
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        formatter.usesGroupingSeparator = true

        let dollars = Double(totalAmountInCents) / 100.0

        if totalAmountInCents % 100 == 0 {
            formatter.minimumFractionDigits = 0
            formatter.maximumFractionDigits = 0
        } else {
            formatter.minimumFractionDigits = 2
            formatter.maximumFractionDigits = 2
        }

        return formatter.string(from: NSNumber(value: dollars)) ?? String(format: "%.2f", dollars)
    }

    var body: some View {
        ZStack {
        NavigationView {
            VStack {
                // Tappable amount display (triggers custom keypad)
                AmountInputButton(
                    amountInCents: amountInCents,
                    formatAmount: formatAmount,
                    onTap: { isKeypadActive = true }
                )
                .padding(.bottom, 12)

                HStack {
                    Text("Quick add items")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.leading)
                        .padding(.top, 8)
                    Spacer()
                }

                let columns = [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ]

                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(savedProducts.filter({ $0.priceInCents > 0 }), id: \.id) { product in
                        Button(action: {
                            // Check if this product is already in the cart
                            if let index = basket.firstIndex(where: { $0.productId == product.id && $0.isProduct }) {
                                // Increment quantity
                                basket[index].quantity += 1
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
                                Text(product.name)
                                    .font(.caption)
                                    .lineLimit(1)
                                Text("$\(String(format: "%.2f", Double(product.priceInCents) / 100.0))")
                                    .font(.body)
                                    .fontWeight(.medium)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .padding()
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }
                .padding([.leading, .trailing])
                .padding([.top], 4)
                .padding([.bottom], 14)

                if !basket.isEmpty {
                    Divider()
                    HStack {
                        Text("Cart").font(.headline)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.leading)
                            .padding(.bottom, 2)
                            .padding(.top, 16)
                        Spacer()
                    }
                }
                List {
                    Section {
                        if basket.isEmpty {
                            Text("Cart is empty").font(.subheadline)
                                .foregroundColor(Color(.systemGray2))
                        }
                        ForEach(basket) { item in
                            let current = getCurrentProduct(for: item)
                            HStack(spacing: 12) {
                                // Product name (left-aligned, live lookup)
                                Text(current.name)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                // Quantity (right-aligned, monospace) - only show if not all items are qty 1
                                if !allItemsQuantityOne {
                                    Text("×\(item.quantity)")
                                        .font(.system(.body, design: .monospaced))
                                        .foregroundColor(.secondary)
                                        .frame(minWidth: 40, alignment: .trailing)
                                }

                                // Total price (right-aligned, monospace, live price)
                                Text(formatCartAmount(current.priceInCents * item.quantity, forceDecimals: cartHasAnyCents))
                                    .font(.system(.body, design: .monospaced))
                                    .frame(minWidth: 60, alignment: .trailing)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                editingItem = item
                                showQuantityEditor = true
                            }
                            .swipeActions(edge: .leading) {
                                Button {
                                    if let index = basket.firstIndex(where: { $0.id == item.id }) {
                                        basket[index].quantity += 1
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
                                            basket[index].quantity -= 1
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
                        }
                    } footer: {
                        if !basket.isEmpty {
                            Text("Swipe right: +1 • Swipe left: -1 or Delete")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                    }
                }
//                .listStyle(.plain)
                

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

                            Text(formatCartAmount(subtotalInCents, forceDecimals: taxSummaryHasCents))
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

                            Text(formatCartAmount(taxAmountInCents, forceDecimals: taxSummaryHasCents))
                                .font(.system(.subheadline, design: .monospaced))
                                .frame(minWidth: 60, alignment: .trailing)
                        }
                        .padding(.horizontal, 20)

                        Divider()
                            .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 8)
                }

                if totalAmountInCents > 49 && amountInCents == 0 {
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

                Text(connectionStatus)
                    .font(.caption) // Add this line to make the text smaller
                    .foregroundColor(.gray)
                    .padding(.top, 10)
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
                showPlusMinusButtons = UserDefaults.standard.showPlusMinusButtons
                businessName = UserDefaults.standard.businessName
                taxRate = UserDefaults.standard.taxRate
                dismissKeypadAfterAdd = UserDefaults.standard.dismissKeypadAfterAdd
                inputMode = UserDefaults.standard.inputMode
                applyDarkModePreference()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Text(businessName)
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Text("Settings").foregroundColor(myAccentColor)
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
            .sheet(isPresented: $showQuantityEditor) {
                if let item = editingItem,
                   let index = basket.firstIndex(where: { $0.id == item.id }) {
                    ItemEditorView(
                        item: item,
                        basketIndex: index,
                        basket: $basket,
                        savedProducts: $savedProducts,
                        isPresented: $showQuantityEditor,
                        formatAmount: formatCartAmount
                    )
                    .presentationDetents([.height(350), .medium])
                    .presentationDragIndicator(.visible)
                } else {
                    // Debug fallback - should never appear
                    VStack {
                        Text("Error: Could not find item")
                            .foregroundColor(.red)
                        Text("editingItem: \(editingItem?.name ?? "nil")")
                        Text("basket count: \(basket.count)")
                        Button("Close") {
                            showQuantityEditor = false
                        }
                    }
                    .padding()
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
                    showPlusMinusButtons: showPlusMinusButtons,
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
                .presentationDetents([.medium, .large])
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
                .font(.largeTitle)
                .foregroundColor(amountInCents > 0 ? .primary : .secondary)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
        }
    }
}

struct CustomKeypadView: View {
    @Binding var amountInCents: Int
    let onAddToCart: () -> Void
    let onCancel: () -> Void
    let showPlusMinusButtons: Bool
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

            // Plus/Minus buttons (if enabled in settings)
            if showPlusMinusButtons {
                HStack(spacing: 16) {
                    Button(action: {
                        if amountInCents > 99 {
                            amountInCents -= 100
                        }
                    }) {
                        Text("-$1")
                            .font(.body)
                            .foregroundColor(.white)
                    }
                    .frame(width: 80, height: 36)
                    .background(Color.red.opacity(0.8))
                    .cornerRadius(8)

                    Spacer()

                    Button(action: {
                        amountInCents += 100
                    }) {
                        Text("+$1")
                            .font(.body)
                            .foregroundColor(.white)
                    }
                    .frame(width: 80, height: 36)
                    .background(Color.green.opacity(0.8))
                    .cornerRadius(8)
                }
                .padding(.horizontal, 40)
            }

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
                    Text("Dismiss")
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
        let dollars = Double(cents) / 100.0
        return String(format: "$%.2f", dollars)
    }
}

// MARK: - Checkout Sheet

struct CheckoutSheet: View {
    @Binding var basket: [CartItem]
    let subtotalInCents: Int
    let taxAmountInCents: Int
    let totalAmountInCents: Int
    let formattedTotalAmount: String
    let connectionStatus: String
    let onCharge: () -> Void

    private func formatMoney(_ cents: Int) -> String {
        String(format: "$%.2f", Double(cents) / 100.0)
    }

    var body: some View {
        VStack(spacing: 16) {
            // Drag handle
            Capsule()
                .fill(Color.secondary.opacity(0.3))
                .frame(width: 40, height: 5)
                .padding(.top, 8)

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

// MARK: - Item Editor

struct ItemEditorView: View {
    let item: CartItem
    let basketIndex: Int
    @Binding var basket: [CartItem]
    @Binding var savedProducts: [Product]
    @Binding var isPresented: Bool
    let formatAmount: (Int, Bool) -> String

    @State private var editedName: String = ""
    @State private var currentQuantity: Int
    @FocusState private var isNameFieldFocused: Bool

    init(item: CartItem, basketIndex: Int, basket: Binding<[CartItem]>, savedProducts: Binding<[Product]>, isPresented: Binding<Bool>, formatAmount: @escaping (Int, Bool) -> String) {
        self.item = item
        self.basketIndex = basketIndex
        self._basket = basket
        self._savedProducts = savedProducts
        self._isPresented = isPresented
        self.formatAmount = formatAmount

        // Initialize quantity from current item
        _currentQuantity = State(initialValue: item.quantity)

        // Initialize name from current item
        if item.isProduct, let productId = item.productId {
            if let product = savedProducts.wrappedValue.first(where: { $0.id == productId }) {
                _editedName = State(initialValue: product.name)
            } else {
                _editedName = State(initialValue: item.name)
            }
        } else {
            _editedName = State(initialValue: item.name)
        }
    }

    var body: some View {
        VStack(spacing: 24) {
            // Drag indicator
            Capsule()
                .fill(Color.secondary.opacity(0.3))
                .frame(width: 40, height: 5)
                .padding(.top, 8)

            // Name editing section
            VStack(alignment: .leading, spacing: 8) {
                Text(item.isProduct ? "Product Name" : "Item Name")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                TextField("Enter name", text: $editedName)
                    .font(.title3)
                    .textFieldStyle(.roundedBorder)
                    .focused($isNameFieldFocused)
                    .onSubmit {
                        saveNameChange()
                    }
            }
            .padding(.horizontal)

            // Quantity section
            VStack(spacing: 16) {
                Text("Quantity")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                HStack(spacing: 40) {
                    // Delete/Minus button
                    Button(action: {
                        if currentQuantity == 1 {
                            // Delete item
                            basket.remove(at: basketIndex)
                            isPresented = false
                        } else {
                            currentQuantity -= 1
                            basket[basketIndex].quantity = currentQuantity
                        }
                    }) {
                        if currentQuantity == 1 {
                            Text("Delete")
                                .font(.headline)
                                .foregroundColor(.red)
                                .frame(width: 80)
                        } else {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 44))
                                .foregroundColor(.blue)
                        }
                    }

                    Text("\(currentQuantity)")
                        .font(.system(size: 50, weight: .semibold, design: .rounded))
                        .frame(minWidth: 70)

                    Button(action: {
                        currentQuantity += 1
                        basket[basketIndex].quantity = currentQuantity
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 44))
                            .foregroundColor(.blue)
                    }
                }
            }

            // Price/Subtotal section
            VStack(spacing: 8) {
                Text("Price")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                if currentQuantity > 1 {
                    // Show calculation
                    Text("\(formatAmount(item.priceInCents, true)) × \(currentQuantity) = \(formatAmount(item.priceInCents * currentQuantity, true))")
                        .font(.title2)
                        .fontWeight(.medium)
                } else {
                    // Show just the price
                    Text(formatAmount(item.priceInCents, true))
                        .font(.title2)
                        .fontWeight(.medium)
                }
            }

            Spacer()

            // Done button
            Button(action: {
                saveNameChange()
                isPresented = false
            }) {
                Text("Done")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .background(Color(.systemBackground))
    }

    private func saveNameChange() {
        guard editedName != item.name else { return }

        if item.isProduct, let productId = item.productId {
            // Update global product name
            if let productIndex = savedProducts.firstIndex(where: { $0.id == productId }) {
                savedProducts[productIndex].name = editedName
                UserDefaults.standard.savedProducts = savedProducts
            }
        } else {
            // Update cart item name (need to recreate CartItem since name is immutable)
            let updatedItem = CartItem(
                id: item.id,
                productId: item.productId,
                name: editedName,
                priceInCents: item.priceInCents,
                quantity: currentQuantity,
                isProduct: item.isProduct
            )
            basket[basketIndex] = updatedItem
        }
    }
}
