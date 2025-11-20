//  ProductEditorView.swift
//  Tappayo
//
//  Sheet for editing products from Settings

import SwiftUI

struct ProductEditorView: View {
    @Binding var product: Product
    @Binding var savedProducts: [Product]
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
        .presentationDetents([.fraction(0.85)])
        .onDisappear {
            saveChanges()
        }
    }

    private func saveChanges() {
        UserDefaults.standard.savedProducts = savedProducts
    }
}
