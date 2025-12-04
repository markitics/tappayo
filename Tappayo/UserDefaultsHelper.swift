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

    var savedProducts: [Product] {
        get {
            // Check if we have saved products
            if let data = data(forKey: UserDefaultsKeys.savedProducts.rawValue),
               let products = try? JSONDecoder().decode([Product].self, from: data) {
                return products
            }

            // Migration: Convert existing quickAmounts to Products
            let amounts = quickAmounts
            var products: [Product] = []
            for (index, amount) in amounts.enumerated() {
                let name = amount > 0 ? "Product \(index + 1)" : ""
                products.append(Product(name: name, priceInCents: amount))
            }

            // Save migrated products directly (don't call setter from getter)
            let data = try? JSONEncoder().encode(products)
            set(data, forKey: UserDefaultsKeys.savedProducts.rawValue)
            return products
        }
        set {
            let data = try? JSONEncoder().encode(newValue)
            set(data, forKey: UserDefaultsKeys.savedProducts.rawValue)
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

    var businessName: String {
        get {
            return string(forKey: UserDefaultsKeys.businessName.rawValue) ?? "Tappayo"
        }
        set {
            set(newValue, forKey: UserDefaultsKeys.businessName.rawValue)
        }
    }

    var taxRate: Double {
        get {
            return double(forKey: UserDefaultsKeys.taxRate.rawValue)
        }
        set {
            set(newValue, forKey: UserDefaultsKeys.taxRate.rawValue)
        }
    }

    var taxRateBasisPoints: Int {
        get {
            // Check if we have the new basis points value
            if object(forKey: UserDefaultsKeys.taxRateBasisPoints.rawValue) != nil {
                return integer(forKey: UserDefaultsKeys.taxRateBasisPoints.rawValue)
            }

            // Migration: Convert old taxRate (Double) to basis points
            let oldTaxRate = taxRate
            let basisPoints = Int(round(oldTaxRate * 100))

            // Save migrated value
            set(basisPoints, forKey: UserDefaultsKeys.taxRateBasisPoints.rawValue)
            return basisPoints
        }
        set {
            set(newValue, forKey: UserDefaultsKeys.taxRateBasisPoints.rawValue)
        }
    }

    var taxEnabled: Bool {
        get {
            return bool(forKey: UserDefaultsKeys.taxEnabled.rawValue)
        }
        set {
            set(newValue, forKey: UserDefaultsKeys.taxEnabled.rawValue)
        }
    }

    var tippingEnabled: Bool {
        get {
            return bool(forKey: UserDefaultsKeys.tippingEnabled.rawValue)
        }
        set {
            set(newValue, forKey: UserDefaultsKeys.tippingEnabled.rawValue)
        }
    }

    var dismissKeypadAfterAdd: String {
        get {
            return string(forKey: UserDefaultsKeys.dismissKeypadAfterAdd.rawValue) ?? "dismiss"
        }
        set {
            set(newValue, forKey: UserDefaultsKeys.dismissKeypadAfterAdd.rawValue)
        }
    }

    var inputMode: String {
        get {
            return string(forKey: UserDefaultsKeys.inputMode.rawValue) ?? "cents"
        }
        set {
            set(newValue, forKey: UserDefaultsKeys.inputMode.rawValue)
        }
    }

    // MARK: - Tap to Pay Setup

    var appleUserId: String? {
        get {
            return string(forKey: UserDefaultsKeys.appleUserId.rawValue)
        }
        set {
            set(newValue, forKey: UserDefaultsKeys.appleUserId.rawValue)
        }
    }

    var whenViewedTTPEducation: Date? {
        get {
            return object(forKey: UserDefaultsKeys.whenViewedTTPEducation.rawValue) as? Date
        }
        set {
            set(newValue, forKey: UserDefaultsKeys.whenViewedTTPEducation.rawValue)
        }
    }
}

