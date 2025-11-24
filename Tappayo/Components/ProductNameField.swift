//  ProductNameField.swift
//  Tappayo
//
//  Reusable component for editing product names

import SwiftUI

struct ProductNameField: View {
    @Binding var name: String
    let label: String
    var onSubmit: (() -> Void)? = nil
    var autoSelectDefaultText: Bool = false  // Auto-select text starting with "Custom item"

    @FocusState private var isFocused: Bool
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            TextField("Enter name", text: $name)
                .font(.title3)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
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
                .onSubmit {
                    onSubmit?()
                }
                .onChange(of: isFocused) { _, newValue in
                    // Auto-select text when field gains focus if it starts with "Custom item"
                    if newValue && autoSelectDefaultText && name.starts(with: "Custom item") {
                        DispatchQueue.main.async {
                            UIApplication.shared.sendAction(#selector(UIResponder.selectAll(_:)), to: nil, from: nil, for: nil)
                        }
                    }
                }
        }
        .padding(.horizontal)
    }
}
