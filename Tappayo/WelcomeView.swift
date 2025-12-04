//  WelcomeView.swift
//  Tappayo

import SwiftUI

struct WelcomeView: View {
    @State private var currentPage: Int = 0
    @State private var businessName: String = ""
    @Binding var hasCompletedOnboarding: Bool

    var body: some View {
        TabView(selection: $currentPage) {
            // Page 1: Welcome
            welcomePage
                .tag(0)

            // Page 2: Business name + Get Started
            getStartedPage
                .tag(1)
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .indexViewStyle(.page(backgroundDisplayMode: .always))
    }

    // MARK: - Page 1: Welcome

    private var welcomePage: some View {
        VStack(spacing: 30) {
            Spacer()

            Image(systemName: "iphone.radiowaves.left.and.right")
                .font(.system(size: 80))
                .foregroundColor(.accentColor)

            Text("Welcome to Tappayo")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("The easiest way to accept payments.\nNo card reader needed.")
                .font(.title3)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()

            Button(action: {
                withAnimation {
                    currentPage = 1
                }
            }) {
                Text("Continue")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 60)
        }
    }

    // MARK: - Page 2: Get Started

    private var getStartedPage: some View {
        VStack(spacing: 30) {
            Spacer()

            Image(systemName: "storefront")
                .font(.system(size: 60))
                .foregroundColor(.accentColor)

            Text("What's your business called?")
                .font(.title2)
                .fontWeight(.semibold)

            TextField("e.g. Mark's Coffee Shop", text: $businessName)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal, 40)

            Text("You can change this anytime in Settings.")
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()

            Button(action: {
                // Save business name
                if !businessName.trimmingCharacters(in: .whitespaces).isEmpty {
                    UserDefaults.standard.businessName = businessName
                }
                // Mark onboarding complete
                UserDefaults.standard.hasCompletedInitialOnboarding = true
                hasCompletedOnboarding = true
            }) {
                Text("Get Started")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 60)
        }
    }
}

#Preview {
    WelcomeView(hasCompletedOnboarding: .constant(false))
}
