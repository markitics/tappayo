// UserDefaultsHelper.swift
//import Foundation
//import SwiftUI

import Foundation
import SwiftUI
import UIKit

extension UserDefaults {
    var quickAmounts: [Int] {
        get {
            guard let data = data(forKey: UserDefaultsKeys.quickAmounts.rawValue) else { return [99, 1200, 4000] }
            return (try? JSONDecoder().decode([Int].self, from: data)) ?? [99, 1000, 5000]
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

    var showPlusMinusButtons: Bool {
        get {
            return bool(forKey: UserDefaultsKeys.showPlusMinusButtons.rawValue)
        }
        set {
            set(newValue, forKey: UserDefaultsKeys.showPlusMinusButtons.rawValue)
        }
    }

    var businessName: String {
        get {
            return string(forKey: UserDefaultsKeys.businessName.rawValue) ?? "Tappayo"
        }
        set {
            set(newValue, forKey: UserDefaultsKeys.businessName.rawValue)
        }
    }
}

