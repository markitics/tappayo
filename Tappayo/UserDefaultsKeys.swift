//  UserDefaultsKeys.swift
//  Tappayo
//  Created by M@rkMoriarty.com

import Foundation

enum UserDefaultsKeys: String {
    case quickAmounts
    case savedProducts
    case myAccentColor
    case darkModePreference
    case businessName
    case taxRate
    case taxRateBasisPoints
    case taxEnabled
    case tippingEnabled
    case dismissKeypadAfterAdd
    case inputMode  // "cents" or "dollars"

    // Tap to Pay setup
    case appleUserId
    case whenViewedTTPEducation  // timestamp (Date)
}

