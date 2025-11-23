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

    @Environment(\.colorScheme) var colorScheme

    // Helper functions passed from parent
    let getCurrentProduct: (CartItem) -> (name: String, priceInCents: Int)
    let formatCurrency: (Int, Bool) -> String
    let getCachedImage: (String) -> UIImage?

    // Computed properties passed from parent
    let allItemsQuantityOne: Bool
    let cartHasAnyCents: Bool

    var body: some View {
        ZStack(alignment: .bottom) {
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
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
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
                                .fontWeight(lastChangedItemId == item.id && isAnimatingQuantity ? .bold : .regular)
                                .foregroundColor(.secondary)
                                .frame(minWidth: 40, alignment: .trailing)
                        }

                        // Total price (right-aligned, monospace, live price)
                        Text(formatCurrency(current.priceInCents * item.quantity, cartHasAnyCents))
                            .font(.system(.body, design: .monospaced))
                            .frame(width: 110, alignment: .trailing)
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 16) // padding inside each row, prevent text touching left/right edges
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                lastChangedItemId == item.id && isAnimatingQuantity
                                    ? Color.blue.opacity(colorScheme == .dark ? 0.25 : 0.15)  // more visible on dark background
                                    : Color.clear
                            )
                    )
//                    .padding(.horizontal, 0)
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
                // Note: Previously had showSwipeHelper parameter to hide this in CheckoutSheet,
                // but removed to reduce type-checker complexity. Now always shown.
                if !basket.isEmpty {
                    Text(basket.count == 1 ? "👆 Swipe row right to add, or left to remove" : "Swipe any row right to add, or left to add or remove")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
        }
        .scrollIndicators(.visible) // this is supposed to make scroll indicators always visible (if cart is too tall to view all at once), but it's not working for me (Nov 25)
        .modifier(FlashScrollIndicatorsModifier())

            // Gradient fade overlay at bottom (always shown for smooth grey-to-white transition)
            VStack {
                Spacer()
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(.systemBackground).opacity(0),
                        Color(.systemBackground).opacity(0.7),
                        Color(.systemBackground)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 80)
                .allowsHitTesting(false)
            }
        }
//        .border(Color.red, width: 3) // for debugging only
    }
}

// ViewModifier to apply scrollIndicatorsFlash only on iOS 17+
struct FlashScrollIndicatorsModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content.scrollIndicatorsFlash(onAppear: true)
        } else {
            content
        }
    }
}
