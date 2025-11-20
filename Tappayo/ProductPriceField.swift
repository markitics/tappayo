//  ProductPriceField.swift
//  Tappayo
//
//  Reusable component for editing product prices

import SwiftUI

struct ProductPriceField: View {
    @Binding var priceInCents: Int

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Price")
                .font(.subheadline)
                .foregroundColor(.secondary)
            CurrencyTextField(
                value: $priceInCents,
                placeholder: "$0.00",
                font: .title3
            )
            .frame(height: 40)
            .focused($isFocused)
        }
        .padding(.horizontal)
    }
}
