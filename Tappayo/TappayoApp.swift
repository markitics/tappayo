//
//  TappayoApp.swift
//  Tappayo
//
//  Created by M@rkMoriarty.com on 4/16/24.
//

import SwiftUI
import StripeTerminal

@main
struct TappayoApp: App {
    init() {
        setupStripe()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }

    func setupStripe() {
        // Initialize Stripe Terminal with token provider
        Terminal.setTokenProvider(APIClient.shared)
    }
}
