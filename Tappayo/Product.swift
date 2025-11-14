//  Product.swift
//  Tappayo
//  Created by Claude Code

import Foundation

struct Product: Codable, Hashable, Identifiable {
    let id: UUID
    var name: String
    var priceInCents: Int

    init(id: UUID = UUID(), name: String, priceInCents: Int) {
        self.id = id
        self.name = name
        self.priceInCents = priceInCents
    }
}
