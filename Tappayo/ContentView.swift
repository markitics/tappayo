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

    let readerDiscoveryController = ReaderDiscoveryViewController()

    var totalAmountInCents: Int {
       basket.reduce(0) { total, item in
           let current = getCurrentProduct(for: item)
           return total + (current.priceInCents * item.quantity)
       }
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
        NavigationView {
            VStack {
                HStack {
                    if showPlusMinusButtons {
                        Spacer()

                        Button(action: {
                            if amountInCents > 99 {
                                amountInCents -= 100
                            }
                        }) {
                            Text("-$1")
                        }
                        .padding(4)
                        .foregroundColor(Color.red)
                        .buttonStyle(.bordered)
                        .cornerRadius(8)
                    }

                    Spacer()

                    CurrencyTextField(value: $amountInCents, placeholder: "Enter amount", font: .largeTitle)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .frame(height: 50) // Limit the height
                        .multilineTextAlignment(.center)

                    Spacer()

                    if showPlusMinusButtons {
                        Button(action: {
                            amountInCents += 100
                        }) {
                            Text("+$1")
                        }
                        .padding(4)
                        .foregroundColor(.green)
                        .buttonStyle(.bordered)
                        .cornerRadius(8)

                        Spacer()
                    }
                }
                .padding(.bottom, 12)

                if amountInCents > 0 {
                    HStack {
                        Button(action: {
                            let item = CartItem(
                                name: nextManualItemName(),
                                priceInCents: amountInCents,
                                quantity: 1,
                                isProduct: false
                            )
                            basket.append(item)
                            amountInCents = 0
                        }) {
                            Text("Add to Cart")
                                .fontWeight(.medium)
                        }
                        .padding()
                        .background(.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)

                        Button(action: {
                            amountInCents = 0
                        }) {
                            Text("Cancel").font(.callout)
                                .fontWeight(.medium)
                        }
                        .padding()
                        .foregroundColor(.red)
                        .cornerRadius(8)
                        .buttonStyle(.bordered)
                    }
                    .padding([.bottom], 10)
                }

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
                            .padding(.bottom, 6)
                            .padding(.top, 16)
                        Spacer()
                    }
                }

                List {
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

                            // Quantity (right-aligned, monospace)
                            Text("×\(item.quantity)")
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.secondary)
                                .frame(minWidth: 40, alignment: .trailing)

                            // Total price (right-aligned, monospace, live price)
                            Text(formatCartAmount(current.priceInCents * item.quantity, forceDecimals: cartHasAnyCents))
                                .font(.system(.body, design: .monospaced))
                                .frame(minWidth: 60, alignment: .trailing)
                        }
                    }
                    .onDelete(perform: deleteItem)
                    if !basket.isEmpty {
                        HStack {
                            Spacer()
                            Text("Swipe any item left to delete")
                                .font(.caption2)
                                .foregroundColor(Color.gray)
                                .multilineTextAlignment(.center)
                            Spacer()
                        }
                    }
                }
//                .frame(maxHeight: 400) // Adjust height to ensure visibility
                
                Spacer()

                if totalAmountInCents > 49 && amountInCents == 0 {
                    Button(action: {
                        do {
                            try readerDiscoveryController.checkoutAction(amount: totalAmountInCents)
                        } catch {
                            print("Error occurred: \(error)")
                        }
                    }) {
                        HStack{
//                            wave.3.right.circle.fill or wave.3.right.circle
                            Image(systemName: "wave.3.right.circle.fill")
                            Text("Charge card $\(formattedTotalAmount)").font(.title2)
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
                applyDarkModePreference()
            }
            .navigationTitle(businessName)
            .navigationBarItems(trailing: NavigationLink(destination: SettingsView()) {
                Text("Settings").foregroundColor(myAccentColor)
            })
            .background( // this is to dismiss the keyboard when the user taps outside the text field
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
            )
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
