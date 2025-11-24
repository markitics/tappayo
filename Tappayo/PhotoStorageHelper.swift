//  PhotoStorageHelper.swift
//  Tappayo
//  Created by Claude Code

import UIKit

struct PhotoStorageHelper {
    // Get the directory for storing product photos
    static var photosDirectory: URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let photosPath = documentsPath.appendingPathComponent("ProductPhotos")

        // Create directory if it doesn't exist
        if !FileManager.default.fileExists(atPath: photosPath.path) {
            try? FileManager.default.createDirectory(at: photosPath, withIntermediateDirectories: true)
        }

        return photosPath
    }

    // Save a photo and return the filename
    static func savePhoto(_ image: UIImage) -> String? {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            return nil
        }

        let filename = "\(UUID().uuidString).jpg"
        let fileURL = photosDirectory.appendingPathComponent(filename)

        do {
            try imageData.write(to: fileURL)
            return filename
        } catch {
            print("Error saving photo: \(error)")
            return nil
        }
    }

    // Load a photo from filename
    static func loadPhoto(_ filename: String) -> UIImage? {
        let fileURL = photosDirectory.appendingPathComponent(filename)
        guard let imageData = try? Data(contentsOf: fileURL) else {
            return nil
        }
        return UIImage(data: imageData)
    }

    // Delete a photo file
    static func deletePhoto(_ filename: String) {
        let fileURL = photosDirectory.appendingPathComponent(filename)
        try? FileManager.default.removeItem(at: fileURL)
    }
}
