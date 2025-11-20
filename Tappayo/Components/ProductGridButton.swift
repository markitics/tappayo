//  ProductGridButton.swift
//  Tappayo
//
//  Product button for the main shop grid

import SwiftUI

struct ProductGridButton: View {
    let product: Product
    let quantityInCart: Int
    let productIconSize: CGFloat
    @Binding var basket: [CartItem]
    @Binding var lastChangedItemId: UUID?
    @Binding var isAnimatingQuantity: Bool
    let getCachedImage: (String) -> UIImage?
    let formatCurrency: (Int, Bool) -> String

    var body: some View {
        Button(action: {}) {
            VStack(spacing: 4) {
                // Show photo or emoji
                if let photoFilename = product.photoFilename,
                   let image = getCachedImage(photoFilename) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: productIconSize, height: productIconSize)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                } else if let emoji = product.emoji {
                    Text(emoji)
                        .font(.system(size: productIconSize - 4))
                        .frame(width: productIconSize, height: productIconSize)
                } else {
                    // Show placeholder for products without emoji/image
                    Image(systemName: "camera.circle")
                        .font(.system(size: productIconSize - 10))
                        .foregroundColor(.gray)
                        .frame(width: productIconSize, height: productIconSize)
                }

                Text(product.name)
                    .font(.caption)
                    .lineLimit(1)
                Text(formatCurrency(product.priceInCents, false))
                    .font(.body)
                    .fontWeight(.medium)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, minHeight: 90)
            .background(Color.red.opacity(0.4))  // DEBUG: Shows content frame
            .padding()
            .background(Color.green.opacity(0.4))  // DEBUG: Shows padded area (should be tappable)
            .contentShape(Rectangle())
        }
        .background(Color.blue.opacity(0.4))  // DEBUG: Shows button boundary
        .foregroundColor(.primary)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(quantityInCart > 0 ? Color.blue : Color.gray,  lineWidth: quantityInCart > 0 ? 3 : 1)
        )
        .overlay(alignment: .topLeading) {
            // Quantity badge in top-left corner
            if quantityInCart > 0 {
                Text("\(quantityInCart)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.blue)
                            .frame(minWidth: 22, minHeight: 22)
                    )
                    .offset(x: -2, y: -2)
            }
        }
        .onLongPressGesture(minimumDuration: 0.0, pressing: { isPressing in
            // On touch down: immediately start blue animation
            if isPressing {
                if let index = basket.firstIndex(where: { $0.productId == product.id && $0.isProduct }) {
                    let itemId = basket[index].id
                    lastChangedItemId = itemId
                    isAnimatingQuantity = true
                } else {
                    // For new items, we'll set animation state when added (on perform)
                }
            }
        }, perform: {
            // On touch release: increment quantity and start fade-out
            if let index = basket.firstIndex(where: { $0.productId == product.id && $0.isProduct }) {
                let itemId = basket[index].id
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    basket[index].quantity += 1
                }
                lastChangedItemId = itemId
                isAnimatingQuantity = true

                // Start fade-out timer
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    lastChangedItemId = nil
                    isAnimatingQuantity = false
                }
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

                // Start blue animation for newly added item
                if let index = basket.firstIndex(where: { $0.productId == product.id && $0.isProduct }) {
                    let itemId = basket[index].id
                    lastChangedItemId = itemId
                    isAnimatingQuantity = true

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        lastChangedItemId = nil
                        isAnimatingQuantity = false
                    }
                }
            }
        })
    }
}
