//  ProductsView.swift
//  Tappayo
//
//  Dedicated screen for managing saved products

import SwiftUI

enum ProductSortOption: String, CaseIterable {
    case defaultOrder = "Default"
    case alphabetical = "A-Z"
    case price = "Price"
}

struct ProductsView: View {
    @State private var savedProducts: [Product] = UserDefaults.standard.savedProducts
    @State private var editingProduct: Product?
    @State private var isEditingNewProduct = false
    @AppStorage("productSortOption") private var sortOptionRaw: String = ProductSortOption.defaultOrder.rawValue

    private var sortOption: ProductSortOption {
        get { ProductSortOption(rawValue: sortOptionRaw) ?? .defaultOrder }
    }

    private var sortedProductIndices: [Int] {
        let indices = Array(savedProducts.indices)
        switch sortOption {
        case .defaultOrder:
            return indices
        case .alphabetical:
            return indices.sorted { savedProducts[$0].name.lowercased() < savedProducts[$1].name.lowercased() }
        case .price:
            return indices.sorted { savedProducts[$0].priceInCents < savedProducts[$1].priceInCents }
        }
    }

    var body: some View {
        List {
            // Sort picker (only shown when more than 6 products)
            if savedProducts.count > 6 {
                Section {
                    Picker("Sort by", selection: Binding(
                        get: { sortOption },
                        set: { sortOptionRaw = $0.rawValue }
                    )) {
                        ForEach(ProductSortOption.allCases, id: \.self) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }

            ForEach(sortedProductIndices, id: \.self) { index in
                HStack(spacing: 12) {
                    // Visibility toggle (tappable eye icon)
                    Button(action: {
                        savedProducts[index].isVisible.toggle()
                        UserDefaults.standard.savedProducts = savedProducts
                    }) {
                        Image(systemName: savedProducts[index].isVisible ? "eye.fill" : "eye.slash")
                            .foregroundColor(savedProducts[index].isVisible ? .accentColor : .secondary)
                            .font(.body)
                            .frame(width: 30)
                    }
                    .buttonStyle(.plain)

                    // Product details (tappable to edit)
                    Button(action: {
                        isEditingNewProduct = false
                        editingProduct = savedProducts[index]
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
                                Image(systemName: "photo.badge.plus")
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

                            // Chevron
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .onDelete { indexSet in
                // Map display indices back to actual array indices
                let indicesToDelete = indexSet.map { sortedProductIndices[$0] }
                // Delete in reverse order to preserve indices
                for index in indicesToDelete.sorted().reversed() {
                    savedProducts.remove(at: index)
                }
                UserDefaults.standard.savedProducts = savedProducts
            }

            // Add Product button
            Button(action: {
                let newProduct = Product(name: "", priceInCents: 0)
                savedProducts.append(newProduct)
                UserDefaults.standard.savedProducts = savedProducts
                isEditingNewProduct = true
                editingProduct = newProduct
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Product")
                }
            }

            // Footer section with helper text
            Section {
                // Placeholder for future actions like "Add Sample Products" or "Delete All"
            } footer: {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Tap the eye icon to show or hide a product.")
                    Text("Swipe left to delete a product.")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Products")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $editingProduct) { product in
            if let productIndex = savedProducts.firstIndex(where: { $0.id == product.id }) {
                ProductEditorView(
                    product: $savedProducts[productIndex],
                    savedProducts: $savedProducts,
                    isNewProduct: isEditingNewProduct
                )
            }
        }
        .onAppear {
            savedProducts = UserDefaults.standard.savedProducts
        }
        .onChange(of: savedProducts) { _, newValue in
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
