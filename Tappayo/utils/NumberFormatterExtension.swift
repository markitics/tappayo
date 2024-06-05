//
//  utils:NumberFormatterExtension.swift
//  Tappayo
//
//  Created by M@rkMoriarty.com on 6/4/24.
//

import Foundation

extension NumberFormatter {
    static var currency: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.currencyCode = "USD" // Hardcoding USD
        //        formatter.locale = Locale.current shows € for Mark
        formatter.minimum = 0
        formatter.maximum = 99999999.99
        formatter.multiplier = 0.01 // To format integers as currency
        return formatter
    }
}
