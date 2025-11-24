//  ProductPriceField.swift
//  Tappayo
//
//  Reusable component for editing product prices

import SwiftUI

struct ProductPriceField: View {
    @Binding var priceInCents: Int

    @FocusState private var isFocused: Bool
    @Environment(\.colorScheme) var colorScheme

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
            .frame(height: 50)
            .padding(.horizontal, 16)
            .background(
                // Light mode: white frosted glass like keypad buttons
                // Dark mode: medium-dark grey for visibility
                Group {
                    if colorScheme == .light {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.white.opacity(0.9))
                            .shadow(color: Color.gray.opacity(0.15), radius: 8, y: 4)
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray5))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
                            )
                    }
                }
            )
            .focused($isFocused)
        }
        .padding(.horizontal)
    }
}
