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
    let formatAmount: (Int, Bool) -> String

    @Environment(\.dismiss) private var dismiss
    @State private var editedName: String = ""
    @State private var editedPriceInCents: Int
    @State private var currentQuantity: Int

    init(item: CartItem, basketIndex: Int, basket: Binding<[CartItem]>, savedProducts: Binding<[Product]>, formatAmount: @escaping (Int, Bool) -> String) {
        self.item = item
        self.basketIndex = basketIndex
        self._basket = basket
        self._savedProducts = savedProducts
        self.formatAmount = formatAmount

        // Initialize quantity from current item
        _currentQuantity = State(initialValue: item.quantity)

        // Initialize price from current item
        _editedPriceInCents = State(initialValue: item.priceInCents)

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

    // Get the current product if this is a saved product
    private var currentProduct: Product? {
        guard item.isProduct, let productId = item.productId else { return nil }
        return savedProducts.first(where: { $0.id == productId })
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer()

            // Product icon editing (only for saved products)
            if let product = currentProduct,
               let productIndex = savedProducts.firstIndex(where: { $0.id == product.id }) {
                ProductIconPicker(product: $savedProducts[productIndex], savedProducts: $savedProducts)
                    .padding(.bottom, 8)
            }

            // Name editing
            ProductNameField(
                name: $editedName,
                label: item.isProduct ? "Product Name" : "Item Name",
                onSubmit: saveChanges
            )

            // Price editing
            ProductPriceField(priceInCents: $editedPriceInCents)

            // Calculation row (only if quantity > 1)
            if currentQuantity > 1 {
                Text("\(formatAmount(editedPriceInCents, true)) × \(currentQuantity) = \(formatAmount(editedPriceInCents * currentQuantity, true))")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
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
                            dismiss()
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
            }
            .background(Color(.systemBackground))
            .navigationTitle(item.isProduct ? "Edit Product" : "Edit Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onDisappear {
            // Auto-save changes when sheet is dismissed (swipe, Done button, or any dismissal method)
            // This prevents data loss if user swipes down without tapping Done
            saveChanges()
        }
    }

    private func saveChanges() {
        let nameChanged = editedName != item.name
        let priceChanged = editedPriceInCents != item.priceInCents

        guard nameChanged || priceChanged else { return }

        // If this is a saved product, update the global product library
        if item.isProduct, let productId = item.productId {
            if let productIndex = savedProducts.firstIndex(where: { $0.id == productId }) {
                if nameChanged {
                    savedProducts[productIndex].name = editedName
                }
                if priceChanged {
                    savedProducts[productIndex].priceInCents = editedPriceInCents
                }
                UserDefaults.standard.savedProducts = savedProducts
            }
        }

        // Always update the cart item (whether saved product or free-form item)
        let updatedItem = CartItem(
            id: item.id,
            productId: item.productId,
            name: editedName,
            priceInCents: editedPriceInCents,
            quantity: currentQuantity,
            isProduct: item.isProduct
        )
        basket[basketIndex] = updatedItem
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
            formatAmount: { cents, forceDecimals in
                let formatter = NumberFormatter()
                formatter.numberStyle = .currency
                formatter.currencySymbol = "$"
                return formatter.string(from: NSNumber(value: Double(cents) / 100)) ?? "$0.00"
            }
        )
    }
}
