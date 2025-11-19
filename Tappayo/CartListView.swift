//  CartListView.swift
//  Tappayo
//
//  Reusable cart list component with tap-to-edit and swipe actions

import SwiftUI

struct CartListView: View {
    // Data bindings
    @Binding var basket: [CartItem]
    @Binding var savedProducts: [Product]
    @Binding var editingItem: CartItem?
    @Binding var lastChangedItemId: UUID?
    @Binding var isAnimatingQuantity: Bool

    // Helper functions passed from parent
    let getCurrentProduct: (CartItem) -> (name: String, priceInCents: Int)
    let formatCurrency: (Int, Bool) -> String
    let getCachedImage: (String) -> UIImage?

    // Computed properties passed from parent
    let allItemsQuantityOne: Bool
    let cartHasAnyCents: Bool

    var body: some View {
        List {
            Section {
                if basket.isEmpty {
                    Text("Cart is empty").font(.subheadline)
                }
                ForEach(basket) { item in
                    let current = getCurrentProduct(item)
                    HStack(spacing: 2) {
                        // Icon column (fixed width for alignment)
                        HStack(spacing: 0) {
                            if item.isProduct, let product = savedProducts.first(where: { $0.id == item.productId }) {
                                if let photoFilename = product.photoFilename,
                                   let image = getCachedImage(photoFilename) {
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
                        Text(formatCurrency(current.priceInCents * item.quantity, cartHasAnyCents))
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
        .listStyle(.plain)
        .scrollIndicators(.visible)
    }
}
