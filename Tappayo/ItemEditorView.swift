//  ItemEditorView.swift
//  Tappayo
//
//  Sheet view for editing cart items (name, quantity, delete)

import SwiftUI

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
            Spacer()

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

// MARK: - Preview Provider

struct ItemEditorView_Previews: PreviewProvider {
    static var previews: some View {
        // Sample cart item for preview
        let sampleItem = CartItem(
            name: "Sample Item",
            priceInCents: 599,
            quantity: 2,
            isProduct: false
        )

        ItemEditorView(
            item: sampleItem,
            basketIndex: 0,
            basket: .constant([sampleItem]),
            savedProducts: .constant([]),
            isPresented: .constant(true),
            formatAmount: { cents, forceDecimals in
                let formatter = NumberFormatter()
                formatter.numberStyle = .currency
                formatter.currencySymbol = "$"
                return formatter.string(from: NSNumber(value: Double(cents) / 100)) ?? "$0.00"
            }
        )
        .presentationDetents([.height(350), .medium])
    }
}
