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
        Button(action: {
            // Increment quantity or add new product to cart
            if let index = basket.firstIndex(where: { $0.productId == product.id && $0.isProduct }) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    basket[index].quantity += 1
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
            }
        }) {
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
            .padding()
            // IMPORTANT: .contentShape(Rectangle()) makes the ENTIRE padded area tappable,
            // not just the visible content (icon/text). Without this, users must tap exactly
            // on the emoji or text, not the empty space. The .padding() MUST be inside the
            // Button's content (before the closing brace) for this to work. Don't "simplify"
            // this structure or move .padding() outside - it will break tap targets!
            .contentShape(Rectangle())
        }
        .buttonStyle(ProductTileButtonStyle(onPressChanged: { isPressed in
            if isPressed {
                // Touch DOWN - blue appears immediately
                if let index = basket.firstIndex(where: { $0.productId == product.id && $0.isProduct }) {
                    let itemId = basket[index].id
                    lastChangedItemId = itemId
                    isAnimatingQuantity = true
                }
            } else {
                // Touch UP (release) - start fade-out timer
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    lastChangedItemId = nil
                    isAnimatingQuantity = false
                }
            }
        }))
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
    }
}
