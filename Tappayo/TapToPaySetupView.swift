//  TapToPaySetupView.swift
//  Tappayo

import SwiftUI
import CoreLocation

struct TapToPaySetupView: View {
    // MARK: - State (placeholder values for now)

    @State private var isSignedIn: Bool = false
    @State private var hasViewedEducation: Bool = false
    @State private var hasAcceptedTerms: Bool = false

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
                    subtitle: "Watch Apple's quick tutorial",
                    isComplete: hasViewedEducation
                ) {
                    // TODO: Step 4 - ProximityReaderDiscovery education
                }

                SetupChecklistRow(
                    title: "Accept Apple Terms",
                    subtitle: "Required for Tap to Pay on iPhone",
                    isComplete: hasAcceptedTerms
                ) {
                    // TODO: Step 3 - ProximityReader terms acceptance
                }
            }

            Section(header: Text("Permissions")) {
                SetupChecklistRow(
                    title: "Location",
                    isComplete: locationManager.isGranted,
                    statusText: locationManager.statusText
                ) {
                    if locationManager.authorizationStatus == .notDetermined {
                        locationManager.requestPermission()
                    }
                }
            }
        }
        .navigationTitle("Tap to Pay Setup")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        TapToPaySetupView()
    }
}
