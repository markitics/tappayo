//  Product.swift
//  Tappayo

import Foundation

struct Product: Codable, Hashable, Identifiable {
    let id: UUID
    var name: String
    var priceInCents: Int
    var emoji: String?
    var photoFilename: String?

    init(id: UUID = UUID(), name: String, priceInCents: Int, emoji: String? = nil, photoFilename: String? = nil) {
        self.id = id
        self.name = name
        self.priceInCents = priceInCents
        self.emoji = emoji
        self.photoFilename = photoFilename
    }

    // Helper to get display image: photo takes priority over emoji
    var hasImage: Bool {
        photoFilename != nil || emoji != nil
    }
}
