//  ItemEditorView.swift
//  Tappayo
//
//  Sheet view for editing cart items (name, quantity, delete)

import SwiftUI

struct ItemEditorView: View {
    let item: CartItem
    let basketIndex: Int
    @Binding var basket: [CartItem]
    @Binding var savedProducts: [Product]
    let formatAmount: (Int, Bool) -> String

    @Environment(\.dismiss) private var dismiss
    @State private var editedName: String = ""
    @State private var editedPriceInCents: Int
    @State private var currentQuantity: Int
    @FocusState private var isNameFieldFocused: Bool
    @FocusState private var isPriceFieldFocused: Bool

    // Icon editing state
    @State private var showingIconPicker = false
    @State private var showingCamera = false
    @State private var showingPhotoLibrary = false
    @State private var selectedImage: UIImage?
    @State private var showingEmojiPicker = false

    init(item: CartItem, basketIndex: Int, basket: Binding<[CartItem]>, savedProducts: Binding<[Product]>, formatAmount: @escaping (Int, Bool) -> String) {
        self.item = item
        self.basketIndex = basketIndex
        self._basket = basket
        self._savedProducts = savedProducts
        self.formatAmount = formatAmount

        // Initialize quantity from current item
        _currentQuantity = State(initialValue: item.quantity)

        // Initialize price from current item
        _editedPriceInCents = State(initialValue: item.priceInCents)

        // Initialize name from current item
        if item.isProduct, let productId = item.productId {
            if let product = savedProducts.wrappedValue.first(where: { $0.id == productId }) {
                _editedName = State(initialValue: product.name)
            } else {
                _editedName = State(initialValue: item.name)
            }
        } else {
            _editedName = State(initialValue: item.name)
        }
    }

    // Get the current product if this is a saved product
    private var currentProduct: Product? {
        guard item.isProduct, let productId = item.productId else { return nil }
        return savedProducts.first(where: { $0.id == productId })
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Product icon display (tappable to edit)
            if let product = currentProduct {
                Button(action: {
                    showingIconPicker = true
                }) {
                    VStack {
                        if let photoFilename = product.photoFilename,
                           let image = PhotoStorageHelper.loadPhoto(photoFilename) {
                            // Show photo
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        } else if let emoji = product.emoji {
                            // Show emoji
                            Text(emoji)
                                .font(.system(size: 80))
                                .frame(width: 100, height: 100)
                        } else {
                            // Show placeholder
                            Image(systemName: "camera.circle")
                                .font(.system(size: 80))
                                .foregroundColor(.gray)
                                .frame(width: 100, height: 100)
                        }
                    }
                }
                .buttonStyle(.plain)
                .padding(.bottom, 8)
            }

            // Name editing section
            VStack(alignment: .leading, spacing: 8) {
                Text(item.isProduct ? "Product Name" : "Item Name")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                TextField("Enter name", text: $editedName)
                    .font(.title3)
                    .textFieldStyle(.roundedBorder)
                    .focused($isNameFieldFocused)
                    .onSubmit {
                        saveChanges()
                    }
            }
            .padding(.horizontal)

            // Price editing section
            VStack(alignment: .leading, spacing: 8) {
                Text("Price")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                CurrencyTextField(
                    value: $editedPriceInCents,
                    placeholder: "$0.00",
                    font: .title3
                )
                .frame(height: 40)
                .focused($isPriceFieldFocused)
            }
            .padding(.horizontal)

            // Calculation row (only if quantity > 1)
            if currentQuantity > 1 {
                Text("\(formatAmount(editedPriceInCents, true)) × \(currentQuantity) = \(formatAmount(editedPriceInCents * currentQuantity, true))")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }


            // Quantity section
            VStack(spacing: 16) {
                Text("Quantity")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                HStack(spacing: 40) {
                    // Delete/Minus button
                    Button(action: {
                        if currentQuantity == 1 {
                            // Delete item
                            basket.remove(at: basketIndex)
                            dismiss()
                        } else {
                            currentQuantity -= 1
                            basket[basketIndex].quantity = currentQuantity
                        }
                    }) {
                        if currentQuantity == 1 {
                            Text("Delete")
                                .font(.headline)
                                .foregroundColor(.red)
                                .frame(width: 80)
                        } else {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 44))
                                .foregroundColor(.blue)
                        }
                    }

                    Text("\(currentQuantity)")
                        .font(.system(size: 50, weight: .semibold, design: .rounded))
                        .frame(minWidth: 70)

                    Button(action: {
                        currentQuantity += 1
                        basket[basketIndex].quantity = currentQuantity
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 44))
                            .foregroundColor(.blue)
                    }
                }
            }


            Spacer()

            // Done button (auto-save happens in .onDisappear, so just dismiss here)
            Button(action: {
                dismiss() // no saveChanges, since we get that upon .onDisappear for all modal dismisses now
            }) {
                Text("Done")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .background(Color(.systemBackground))
        .confirmationDialog("Choose Icon", isPresented: $showingIconPicker) {
            Button("Choose Emoji") {
                showingEmojiPicker = true
            }
            Button("Take Photo") {
                showingCamera = true
            }
            Button("Choose from Library") {
                showingPhotoLibrary = true
            }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $showingCamera) {
            ImagePicker(image: $selectedImage, sourceType: .camera)
        }
        .sheet(isPresented: $showingPhotoLibrary) {
            ImagePicker(image: $selectedImage, sourceType: .photoLibrary)
        }
        .onChange(of: selectedImage) { newImage in
            handleImageSelection(newImage)
        }
        .emojiPicker(
            isPresented: $showingEmojiPicker,
            selectedEmoji: Binding(
                get: {
                    currentProduct?.emoji ?? ""
                },
                set: { newEmoji in
                    handleEmojiSelection(newEmoji)
                }
            )
        )
        .onDisappear {
            // Auto-save changes when sheet is dismissed (swipe, Done button, or any dismissal method)
            // This prevents data loss if user swipes down without tapping Done
            saveChanges()
        }
    }

    private func saveChanges() {
        let nameChanged = editedName != item.name
        let priceChanged = editedPriceInCents != item.priceInCents

        guard nameChanged || priceChanged else { return }

        // If this is a saved product, update the global product library
        if item.isProduct, let productId = item.productId {
            if let productIndex = savedProducts.firstIndex(where: { $0.id == productId }) {
                if nameChanged {
                    savedProducts[productIndex].name = editedName
                }
                if priceChanged {
                    savedProducts[productIndex].priceInCents = editedPriceInCents
                }
                UserDefaults.standard.savedProducts = savedProducts
            }
        }

        // Always update the cart item (whether saved product or free-form item)
        let updatedItem = CartItem(
            id: item.id,
            productId: item.productId,
            name: editedName,
            priceInCents: editedPriceInCents,
            quantity: currentQuantity,
            isProduct: item.isProduct
        )
        basket[basketIndex] = updatedItem
    }

    private func handleImageSelection(_ image: UIImage?) {
        guard let image = image,
              item.isProduct,
              let productId = item.productId,
              let productIndex = savedProducts.firstIndex(where: { $0.id == productId }) else {
            selectedImage = nil
            return
        }

        // Save the new photo
        if let filename = PhotoStorageHelper.savePhoto(image) {
            // Delete old photo if exists
            if let oldFilename = savedProducts[productIndex].photoFilename {
                PhotoStorageHelper.deletePhoto(oldFilename)
            }
            // Set new photo and clear emoji (photo takes priority)
            savedProducts[productIndex].photoFilename = filename
            savedProducts[productIndex].emoji = nil
            UserDefaults.standard.savedProducts = savedProducts
        }

        selectedImage = nil
    }

    private func handleEmojiSelection(_ emoji: String) {
        guard item.isProduct,
              let productId = item.productId,
              let productIndex = savedProducts.firstIndex(where: { $0.id == productId }) else {
            return
        }

        // Delete old photo if exists
        if let oldFilename = savedProducts[productIndex].photoFilename {
            PhotoStorageHelper.deletePhoto(oldFilename)
        }

        // Set emoji and clear photo
        savedProducts[productIndex].emoji = emoji.isEmpty ? nil : emoji
        savedProducts[productIndex].photoFilename = nil
        UserDefaults.standard.savedProducts = savedProducts
    }
}

// MARK: - Preview Provider

struct ItemEditorView_Previews: PreviewProvider {
    static var previews: some View {
        // Sample cart item for preview
        let sampleItem = CartItem(
            name: "Sample Item",
            priceInCents: 599,
            quantity: 2,
            isProduct: false
        )

        ItemEditorView(
            item: sampleItem,
            basketIndex: 0,
            basket: .constant([sampleItem]),
            savedProducts: .constant([]),
            formatAmount: { cents, forceDecimals in
                let formatter = NumberFormatter()
                formatter.numberStyle = .currency
                formatter.currencySymbol = "$"
                return formatter.string(from: NSNumber(value: Double(cents) / 100)) ?? "$0.00"
            }
        )
    }
}
