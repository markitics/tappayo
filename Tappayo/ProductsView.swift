//  ProductsView.swift
//  Tappayo
//
//  Dedicated screen for managing saved products

import SwiftUI

struct ProductsView: View {
    @State private var savedProducts: [Product] = UserDefaults.standard.savedProducts
    @State private var editingProduct: Product?
    @State private var showingProductEditor = false

    var body: some View {
        List {
            ForEach(savedProducts.indices, id: \.self) { index in
                Button(action: {
                    editingProduct = savedProducts[index]
                    showingProductEditor = true
                }) {
                    HStack(spacing: 12) {
                        // Product icon
                        if let photoFilename = savedProducts[index].photoFilename,
                           let image = PhotoStorageHelper.loadPhoto(photoFilename) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 50, height: 50)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        } else if let emoji = savedProducts[index].emoji {
                            Text(emoji)
                                .font(.system(size: 40))
                                .frame(width: 50, height: 50)
                        } else {
                            Image(systemName: "camera.circle")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                                .frame(width: 50, height: 50)
                        }

                        // Product name and price
                        VStack(alignment: .leading, spacing: 4) {
                            Text(savedProducts[index].name.isEmpty ? "Unnamed Product" : savedProducts[index].name)
                                .font(.body)
                                .foregroundColor(.primary)
                            Text(formatCurrency(savedProducts[index].priceInCents))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        // Visibility indicator
                        if !savedProducts[index].isVisible {
                            Image(systemName: "eye.slash")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }

                        // Chevron
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .onDelete { indexSet in
                savedProducts.remove(atOffsets: indexSet)
                UserDefaults.standard.savedProducts = savedProducts
            }

            // Add Product button
            Button(action: {
                let newProduct = Product(name: "", priceInCents: 0)
                savedProducts.append(newProduct)
                UserDefaults.standard.savedProducts = savedProducts
                editingProduct = newProduct
                showingProductEditor = true
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Product")
                }
            }
        }
        .navigationTitle("Products")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingProductEditor) {
            if let product = editingProduct,
               let productIndex = savedProducts.firstIndex(where: { $0.id == product.id }) {
                ProductEditorView(
                    product: $savedProducts[productIndex],
                    savedProducts: $savedProducts
                )
            }
        }
        .onAppear {
            savedProducts = UserDefaults.standard.savedProducts
        }
        .onChange(of: savedProducts) { newValue in
            UserDefaults.standard.savedProducts = newValue
        }
    }

    private func formatCurrency(_ cents: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        formatter.usesGroupingSeparator = true
        let shouldShowDecimals = cents % 100 != 0
        formatter.minimumFractionDigits = shouldShowDecimals ? 2 : 0
        formatter.maximumFractionDigits = shouldShowDecimals ? 2 : 0
        return formatter.string(from: NSNumber(value: Double(cents) / 100)) ?? "$0.00"
    }
}
