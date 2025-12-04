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
    @State private var hasCompletedOnboarding = UserDefaults.standard.hasCompletedInitialOnboarding

    init() {
        setupStripe()
    }

    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                ContentView()
            } else {
                WelcomeView(hasCompletedOnboarding: $hasCompletedOnboarding)
            }
        }
    }

    func setupStripe() {
        // Initialize Stripe Terminal with token provider
        Terminal.setTokenProvider(APIClient.shared)
    }
}
