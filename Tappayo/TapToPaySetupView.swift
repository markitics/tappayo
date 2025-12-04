//  TapToPaySetupView.swift
//  Tappayo

import SwiftUI
import CoreLocation
import ProximityReader

struct TapToPaySetupView: View {
    // MARK: - State

    @State private var isSignedIn: Bool = false
    @State private var hasViewedEducation: Bool = UserDefaults.standard.whenViewedTTPEducation != nil
    @State private var hasAcceptedTerms: Bool = false
    @State private var showLocationDeniedAlert: Bool = false
    @State private var showEducationError: Bool = false
    @State private var educationErrorMessage: String = ""
    @State private var showEducationFallback: Bool = false

    // MARK: - Permission Managers

    @StateObject private var locationManager = LocationPermissionManager()

    var body: some View {
        Form {
            Section(header: Text("Account")) {
                SetupChecklistRow(
                    title: "Sign in with Apple",
                    subtitle: "Create your Tappayo account",
                    isComplete: isSignedIn
                ) {
                    // TODO: Step 5 - Sign in with Apple
                }
            }

            Section(header: Text("Tap to Pay")) {
                SetupChecklistRow(
                    title: "Learn about Tap to Pay",
                    subtitle: hasViewedEducation ? "Tap to view again" : "Watch Apple's quick tutorial",
                    isComplete: hasViewedEducation
                ) {
                    presentEducation()
                }

                // TODO: clean up code if we don't use hasAcceptedTerms after all.
                //
                SetupChecklistRow(
                    title: "Accept Apple Terms",
                    subtitle: "Required for Tap to Pay on iPhone",
                    isComplete: hasAcceptedTerms
                ) {
                    // TODO: Step 4 - ProximityReader terms acceptance
                }
            }

            Section(header: Text("Permissions")) {
                SetupChecklistRow(
                    title: "Location",
                    isComplete: locationManager.isGranted,
                    statusText: locationManager.statusText
                ) {
                    switch locationManager.authorizationStatus {
                    case .notDetermined:
                        locationManager.requestPermission()
                    case .denied, .restricted:
                        showLocationDeniedAlert = true
                    default:
                        break
                    }
                }
            }

            // MARK: DEBUG - Restart Onboarding
            Section(header: Text("Debug")) {
                Button {
                    UserDefaults.standard.hasCompletedInitialOnboarding = false
                } label: {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Restart Onboarding")
                    }
                }
            }
        }
        .navigationTitle("Tap to Pay Setup")
        .navigationBarTitleDisplayMode(.inline)
        // MARK: DEBUG - Remove this before shipping
        .onAppear {
            UserDefaults.standard.whenViewedTTPEducation = nil
            hasViewedEducation = false
        }
        // END DEBUG
        .alert("Location access", isPresented: $showLocationDeniedAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("To authorize payments with Tap to Pay on iPhone, and help with fraud prevention: set \"Location\" to \"While Using the App\".")
        }
        .alert("Education unavailable", isPresented: $showEducationError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(educationErrorMessage)
        }
        .alert("Tap to Pay on iPhone", isPresented: $showEducationFallback) {
            Button("Learn more") {
                if let url = URL(string: "https://developer.apple.com/tap-to-pay/how-to-accept-payments/") {
                    UIApplication.shared.open(url)
                    // not https://www.apple.com/business/tap-to-pay-on-iphone/
                }
                UserDefaults.standard.whenViewedTTPEducation = Date()
                hasViewedEducation = true
            }
            Button("OK", role: .cancel) {
                UserDefaults.standard.whenViewedTTPEducation = Date()
                hasViewedEducation = true
            }
        } message: {
            Text("It's easy to accept contactless payments using just your iPhone. Enter the purchase amount, press the blue \"Pay $XX\" button, and present your iPhone to your customer. \nCustomers can can pay with a physical debit or credit card, Apple Pay, or other digital wallets, including Android. \n\nFor best results, update your iPhone under Settings → General → Software Update")
        }
    }

    // MARK: - Education Flow

    private func presentEducation() {
        if #available(iOS 18, *) {
            presentEducationiOS18()
            // debugging only, force fallback
//            showEducationFallback = true
        } else {
            // iOS 17 fallback: show alert with link to Apple's website
            showEducationFallback = true
        }
    }

    @available(iOS 18, *)
    private func presentEducationiOS18() {
        Task {
            do {
                // Get the root view controller to present from
                guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                      let viewController = windowScene.windows.first?.rootViewController else {
                    await MainActor.run {
                        educationErrorMessage = "Unable to present education screen."
                        showEducationError = true
                    }
                    return
                }

                // Find the topmost presented view controller
                var topController = viewController
                while let presented = topController.presentedViewController {
                    topController = presented
                }

                let discovery = ProximityReaderDiscovery()
                let content = try await discovery.content(for: .payment(.howToTap))
                try await discovery.presentContent(content, from: topController)

                // Mark as viewed with timestamp
                await MainActor.run {
                    UserDefaults.standard.whenViewedTTPEducation = Date()
                    hasViewedEducation = true
                }
            } catch {
                await MainActor.run {
                    educationErrorMessage = "Could not show education: \(error.localizedDescription)"
                    showEducationError = true
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        TapToPaySetupView()
    }
}
