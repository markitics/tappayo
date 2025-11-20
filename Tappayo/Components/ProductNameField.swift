//  ProductNameField.swift
//  Tappayo
//
//  Reusable component for editing product names

import SwiftUI

struct ProductNameField: View {
    @Binding var name: String
    let label: String
    var onSubmit: (() -> Void)? = nil

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            TextField("Enter name", text: $name)
                .font(.title3)
                .textFieldStyle(.roundedBorder)
                .focused($isFocused)
                .onSubmit {
                    onSubmit?()
                }
        }
        .padding(.horizontal)
    }
}
