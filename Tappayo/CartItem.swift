//  CartItem.swift
//  Tappayo
//  Created by Claude Code

import Foundation

struct CartItem: Identifiable, Hashable {
    let id: UUID
    let productId: UUID? // nil for manual entries, product.id for saved products
    let name: String // "Coffee" or "Item 1"
    let priceInCents: Int // unit price
    var quantity: Int
    let isProduct: Bool // true=saved product, false=manual entry

    var totalPrice: Int {
        priceInCents * quantity
    }

    init(id: UUID = UUID(), productId: UUID? = nil, name: String, priceInCents: Int, quantity: Int = 1, isProduct: Bool) {
        self.id = id
        self.productId = productId
        self.name = name
        self.priceInCents = priceInCents
        self.quantity = quantity
        self.isProduct = isProduct
    }
}
