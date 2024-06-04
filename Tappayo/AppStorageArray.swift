//  AppStorageArray.swift
//  Tappayo
//  Created by M@rkMoriarty.com

// from ChatGPT: The error message indicates that SwiftUI's AppStorage property wrapper does not directly support arrays. We need to create a custom wrapper to handle the storage and retrieval of arrays using UserDefaults.

//Here's how we can address this issue by creating a custom AppStorage compatible property wrapper for arrays:
//
//Step 1: Create the Custom Property Wrapper
//Create a new Swift file named AppStorageArray.swift inside the Tappayo folder and add the following code:

//This file is no longer needed if we don't use @AppStorage; we're using UserDefaults instead
//
//
//import SwiftUI
//
//@propertyWrapper
//struct AppStorageArray<T: Codable> {
//    private let key: String
//    private let store: UserDefaults = .standard
//
//    var wrappedValue: [T] {
//        get {
//            guard let data = store.data(forKey: key) else { return [] }
//            return (try? JSONDecoder().decode([T].self, from: data)) ?? []
//        }
//        set {
//            let data = try? JSONEncoder().encode(newValue)
//            store.set(data, forKey: key)
//        }
//    }
//
//    init(wrappedValue: [T], key: String) {
//        self.key = key
//        self.wrappedValue = wrappedValue
//    }
//
//    var projectedValue: Binding<[T]> {
//        Binding(get: { self.wrappedValue }, set: { newValue in
//            let data = try? JSONEncoder().encode(newValue)
//            store.set(data, forKey: self.key)
//        })
//    }
//}
//
//@propertyWrapper
//struct AppStorageColor {
//    private let key: String
//    private let store: UserDefaults = .standard
//
//    var wrappedValue: Color {
//        get {
//            guard let data = store.data(forKey: key),
//                  let uiColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: data) else {
//                return Color.blue
//            }
//            return Color(uiColor)
//        }
//        set {
//            let uiColor = UIColor(newValue)
//            let data = try? NSKeyedArchiver.archivedData(withRootObject: uiColor, requiringSecureCoding: false)
//            store.set(data, forKey: key)
//        }
//    }
//
//    init(wrappedValue: Color, key: String) {
//        self.key = key
//        self.wrappedValue = wrappedValue
//    }
//
//    var projectedValue: Binding<Color> {
//        Binding(get: { self.wrappedValue }, set: { newValue in
//            let uiColor = UIColor(newValue)
//            let data = try? NSKeyedArchiver.archivedData(withRootObject: uiColor, requiringSecureCoding: false)
//            store.set(data, forKey: self.key)
//        })
//    }
//}
//
//
////import SwiftUI
////
////@propertyWrapper
////struct AppStorageArray {
////    let key: String
////    let store: UserDefaults = .standard
////    var wrappedValue: [Double] {
////        get {
////            guard let data = store.data(forKey: key) else { return [] }
////            return (try? JSONDecoder().decode([Double].self, from: data)) ?? []
////        }
////        set {
////            let data = try? JSONEncoder().encode(newValue)
////            store.set(data, forKey: key)
////        }
////    }
////
////    init(wrappedValue: [Double], key: String) {
////        self.key = key
////        self.wrappedValue = wrappedValue
////    }
////
////    var projectedValue: Binding<[Double]> {
////        Binding(get: { self.wrappedValue }, set: { newValue in
////            let data = try? JSONEncoder().encode(newValue)
////            self.store.set(data, forKey: self.key)
////        })
////    }
////}
////
////@propertyWrapper
////struct AppStorageColor {
////    let key: String
////    let store: UserDefaults = .standard
////    var wrappedValue: Color {
////        get {
////            guard let data = store.data(forKey: key),
////                  let uiColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: data) else {
////                return Color.blue
////            }
////            return Color(uiColor)
////        }
////        set {
////            let uiColor = UIColor(newValue)
////            let data = try? NSKeyedArchiver.archivedData(withRootObject: uiColor, requiringSecureCoding: false)
////            store.set(data, forKey: key)
////        }
////    }
////
////    init(wrappedValue: Color, key: String) {
////        self.key = key
////        self.wrappedValue = wrappedValue
////    }
////
////    var projectedValue: Binding<Color> {
////        Binding(get: { self.wrappedValue }, set: { newValue in
////            let uiColor = UIColor(newValue)
////            let data = try? NSKeyedArchiver.archivedData(withRootObject: uiColor, requiringSecureCoding: false)
////            self.store.set(data, forKey: self.key)
////        })
////    }
////}
