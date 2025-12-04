//  TapToPaySetupView.swift
//  Tappayo

import SwiftUI

struct TapToPaySetupView: View {
    // MARK: - State (placeholder values for now)

    @State private var isSignedIn: Bool = false
    @State private var hasViewedEducation: Bool = false
    @State private var hasAcceptedTerms: Bool = false
    @State private var bluetoothStatus: String = "Not Set"
    @State private var locationStatus: String = "Not Set"

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
                    title: "Bluetooth",
                    isComplete: bluetoothStatus == "Granted",
                    statusText: bluetoothStatus
                ) {
                    // TODO: Step 2 - Request Bluetooth permission
                }

                SetupChecklistRow(
                    title: "Location",
                    isComplete: locationStatus == "Granted",
                    statusText: locationStatus
                ) {
                    // TODO: Step 2 - Request Location permission
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
