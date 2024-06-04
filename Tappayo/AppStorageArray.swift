//  AppStorageArray.swift
//  Tappayo
//  Created by M@rkMoriarty.com

// from ChatGPT: The error message indicates that SwiftUI's AppStorage property wrapper does not directly support arrays. We need to create a custom wrapper to handle the storage and retrieval of arrays using UserDefaults.

//Here's how we can address this issue by creating a custom AppStorage compatible property wrapper for arrays:
//
//Step 1: Create the Custom Property Wrapper
//Create a new Swift file named AppStorageArray.swift inside the Tappayo folder and add the following code:

import SwiftUI

@propertyWrapper
struct AppStorageArray<T: RawRepresentable> where T.RawValue: Codable {
    let key: String
    let store: UserDefaults = .standard
    var wrappedValue: [T] {
        get {
            guard let data = store.data(forKey: key) else { return [] }
            let rawValues = (try? JSONDecoder().decode([T.RawValue].self, from: data)) ?? []
            return rawValues.compactMap { T(rawValue: $0) }
        }
        set {
            let rawValues = newValue.map { $0.rawValue }
            let data = try? JSONEncoder().encode(rawValues)
            store.set(data, forKey: key)
        }
    }

    init(wrappedValue: [T], key: String) {
        self.key = key
        self.wrappedValue = wrappedValue
    }

    var projectedValue: Binding<[T]> {
        Binding(get: { self.wrappedValue }, set: { newValue in
            let rawValues = newValue.map { $0.rawValue }
            let data = try? JSONEncoder().encode(rawValues)
            self.store.set(data, forKey: self.key)
        })
    }
}

@propertyWrapper
struct AppStorageColor {
    let key: String
    let store: UserDefaults = .standard
    var wrappedValue: Color {
        get {
            guard let data = store.data(forKey: key),
                  let uiColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: data) else {
                return Color.blue
            }
            return Color(uiColor)
        }
        set {
            let uiColor = UIColor(newValue)
            let data = try? NSKeyedArchiver.archivedData(withRootObject: uiColor, requiringSecureCoding: false)
            store.set(data, forKey: key)
        }
    }

    init(wrappedValue: Color, key: String) {
        self.key = key
        self.wrappedValue = wrappedValue
    }

    var projectedValue: Binding<Color> {
        Binding(get: { self.wrappedValue }, set: { newValue in
            let uiColor = UIColor(newValue)
            let data = try? NSKeyedArchiver.archivedData(withRootObject: uiColor, requiringSecureCoding: false)
            self.store.set(data, forKey: self.key)
        })
    }
}
