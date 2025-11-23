//  ProductEditorView.swift
//  Tappayo
//
//  Sheet for editing products from Settings

import SwiftUI

struct ProductEditorView: View {
    @Binding var product: Product
    @Binding var savedProducts: [Product]
    let isNewProduct: Bool
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer()

                // Product icon editing
                if let productIndex = savedProducts.firstIndex(where: { $0.id == product.id }) {
                    ProductIconPicker(product: $savedProducts[productIndex], savedProducts: $savedProducts)
                        .padding(.bottom, 8)
                }

                // Name editing
                ProductNameField(
                    name: Binding(
                        get: { product.name },
                        set: { newName in
                            if let index = savedProducts.firstIndex(where: { $0.id == product.id }) {
                                savedProducts[index].name = newName
                            }
                        }
                    ),
                    label: "Product Name"
                )

                // Price editing
                ProductPriceField(
                    priceInCents: Binding(
                        get: { product.priceInCents },
                        set: { newPrice in
                            if let index = savedProducts.firstIndex(where: { $0.id == product.id }) {
                                savedProducts[index].priceInCents = newPrice
                            }
                        }
                    )
                )

                // Visibility toggle
                VStack(alignment: .leading, spacing: 8) {
                    Toggle(isOn: Binding(
                        get: { product.isVisible },
                        set: { newValue in
                            if let index = savedProducts.firstIndex(where: { $0.id == product.id }) {
                                savedProducts[index].isVisible = newValue
                            }
                        }
                    )) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Available in Shop")
                                .font(.subheadline)
                            Text(product.isVisible ? "Visible on main screen" : "Hidden from main screen")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal)

                Spacer()
            }
            .background(Color(.systemBackground))
            .navigationTitle("Edit Product")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        saveChanges()
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.fraction(0.89), .large]) // detents of "add/edit item" sheet, which matches the "edit cart row" sheet detents
        .onDisappear {
            saveChanges()
        }
    }

    private func saveChanges() {
        // If this is a new product and it's empty, remove it instead of saving
        if isNewProduct && isProductEmpty() {
            savedProducts.removeAll { $0.id == product.id }
        }
        UserDefaults.standard.savedProducts = savedProducts
    }

    private func isProductEmpty() -> Bool {
        return product.name.isEmpty &&
               product.priceInCents == 0 &&
               product.emoji == nil &&
               product.photoFilename == nil
    }
}
