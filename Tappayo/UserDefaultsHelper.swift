import Foundation
import SwiftUI

extension UserDefaults {
    var quickAmounts: [Double] {
        get {
            return array(forKey: UserDefaultsKeys.quickAmounts) as? [Double] ?? [0.99, 1.00, 5.00, 10.00, 20.00]
        }
        set {
            set(newValue, forKey: UserDefaultsKeys.quickAmounts)
        }
    }

    var accentColor: Color {
        get {
            if let colorData = data(forKey: UserDefaultsKeys.accentColor),
               let uiColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: colorData) {
                return Color(uiColor)
            }
            return Color.blue
        }
        set {
            let uiColor = UIColor(newValue)
            if let colorData = try? NSKeyedArchiver.archivedData(withRootObject: uiColor, requiringSecureCoding: false) {
                set(colorData, forKey: UserDefaultsKeys.accentColor)
            }
        }
    }
}
