//  PercentageTaxField.swift
//  Tappayo
//
//  Reusable component for editing tax rate as percentage (basis points)

import SwiftUI

struct PercentageTaxField: View {
    @Binding var value: Int
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tax Rate")
                .font(.subheadline)
                .foregroundColor(.secondary)

            HStack(spacing: 8) {
                PercentageTextField(
                    value: $value,
                    placeholder: "0.00",
                    font: .body
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

                Text("%")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal)
    }
}
