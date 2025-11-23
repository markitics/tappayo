//  ProductIconPicker.swift
//  Tappayo
//
//  Reusable component for editing product icons (emoji or photo)

import SwiftUI
import ElegantEmojiPicker

struct ProductIconPicker: View {
    @Binding var product: Product
    @Binding var savedProducts: [Product]

    @State private var showingIconPicker = false
    @State private var showingCamera = false
    @State private var showingPhotoLibrary = false
    @State private var selectedImage: UIImage?
    @State private var showingEmojiPicker = false
    @State private var selectedEmojiFromPicker: Emoji?

    var body: some View {
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
            selectedEmoji: $selectedEmojiFromPicker
        )
        .onChange(of: selectedEmojiFromPicker) { newEmoji in
            if let emoji = newEmoji {
                handleEmojiSelection(emoji.emoji)
                selectedEmojiFromPicker = nil
            }
        }
    }

    private func handleImageSelection(_ image: UIImage?) {
        guard let image = image,
              let productIndex = savedProducts.firstIndex(where: { $0.id == product.id }) else {
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
        guard let productIndex = savedProducts.firstIndex(where: { $0.id == product.id }) else {
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
