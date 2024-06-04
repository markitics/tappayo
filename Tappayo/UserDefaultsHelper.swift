// UserDefaultsHelper.swift
//import Foundation
//import SwiftUI
//
//extension UserDefaults {
//    var quickAmounts: [Double] {
//        get {
//            return array(forKey: UserDefaultsKeys.quickAmounts) as? [Double] ?? [0.99, 5.00, 50.00]
//        }
//        set {
//            set(newValue, forKey: UserDefaultsKeys.quickAmounts)
//        }
//    }
//
//    var accentColor: Color {
//        get {
//            if let colorData = data(forKey: UserDefaultsKeys.accentColor),
//               let uiColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: colorData) {
//                return Color(uiColor)
//            }
//            return Color.blue
//        }
//        set {
//            let uiColor = UIColor(newValue)
//            if let colorData = try? NSKeyedArchiver.archivedData(withRootObject: uiColor, requiringSecureCoding: false) {
//                set(colorData, forKey: UserDefaultsKeys.accentColor)
//            }
//        }
//    }
//
//    var darkModePreference: String {
//        get {
//            return string(forKey: UserDefaultsKeys.darkModePreference) ?? "system"
//        }
//        set {
//            set(newValue, forKey: UserDefaultsKeys.darkModePreference)
//        }
//    }
//}


import Foundation
import SwiftUI

extension UserDefaults {
    var quickAmounts: [Double] {
        get {
            guard let data = data(forKey: UserDefaultsKeys.quickAmounts.rawValue) else { return [0.99, 10.00, 50.00] }
            return (try? JSONDecoder().decode([Double].self, from: data)) ?? [0.99,5.00, 20.00]
        }
        set {
            let data = try? JSONEncoder().encode(newValue)
            set(data, forKey: UserDefaultsKeys.quickAmounts.rawValue)
        }
    }
    
    var myAccentColor: Color {
        get {
            guard let data = data(forKey: UserDefaultsKeys.myAccentColor.rawValue),
                  let uiColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: data) else {
                return Color(red: 0.0, green: 214.0 / 255.0, blue: 111.0 / 255.0)
            }
            return Color(uiColor)
        }
        set {
            let uiColor = UIColor(newValue)
            let data = try? NSKeyedArchiver.archivedData(withRootObject: uiColor, requiringSecureCoding: false)
            set(data, forKey: UserDefaultsKeys.myAccentColor.rawValue)
        }
    }
    
    var darkModePreference: String {
        get {
            return string(forKey: UserDefaultsKeys.darkModePreference.rawValue) ?? "system"
        }
        set {
            set(newValue, forKey: UserDefaultsKeys.darkModePreference.rawValue)
        }
    }
}

