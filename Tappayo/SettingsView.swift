import SwiftUI
import CoreLocation

struct SettingsView: View {
    @State private var businessName: String = UserDefaults.standard.businessName
    @State private var taxRateBasisPoints: Int = UserDefaults.standard.taxRateBasisPoints
    @State private var taxEnabled: Bool = UserDefaults.standard.taxEnabled
    @State private var tippingEnabled: Bool = UserDefaults.standard.tippingEnabled

    // Track TTP setup completion
    @State private var ttpSetupComplete: Bool = false

    var body: some View {
        Form {
            Section(header: Text("Business name")) {
                TextField("Business name", text: $businessName)
            }

            Section(header: Text("Tap to Pay")) {
                NavigationLink(destination: TapToPaySetupView()) {
                    HStack {
                        Text("Set up Tap to Pay on iPhone")
                        Spacer()
                        if !ttpSetupComplete {
                            // Red notification badge
                            Circle()
                                .fill(.red)
                                .frame(width: 10, height: 10)
                        }
                    }
                }
            }

            Section(header: Text("Products")) {
                NavigationLink(destination: ProductsView()) {
                    Text("Manage Products")
                }
            }

            Section(header: Text("Display")) {
                NavigationLink(destination: DisplayOptionsView()) {
                    Text("Display options")
                }
            }

            Section(header: Text("Tax")) {
                Toggle("Add tax", isOn: $taxEnabled)

                if taxEnabled {
                    PercentageTaxField(value: $taxRateBasisPoints)
                }
            }

            Section(header: Text("Tips")) {
                Toggle("Enable tipping", isOn: $tippingEnabled)
            }

            Section {
                NavigationLink(destination: AboutView()) {
                    Text("About")
                }
            }
        }
        .scrollContentBackground(.hidden)
        .sheetGradientBackground()
        .navigationTitle("Tappayo Settings")
        .onAppear {
            businessName = UserDefaults.standard.businessName
            taxRateBasisPoints = UserDefaults.standard.taxRateBasisPoints
            taxEnabled = UserDefaults.standard.taxEnabled
            tippingEnabled = UserDefaults.standard.tippingEnabled
            ttpSetupComplete = checkTTPSetupComplete()
        }
        .onChange(of: businessName) { _, newValue in
            UserDefaults.standard.businessName = newValue
        }
        .onChange(of: taxRateBasisPoints) { _, newValue in
            UserDefaults.standard.taxRateBasisPoints = newValue
        }
        .onChange(of: taxEnabled) { _, newValue in
            UserDefaults.standard.taxEnabled = newValue
        }
        .onChange(of: tippingEnabled) { _, newValue in
            UserDefaults.standard.tippingEnabled = newValue
        }
    }

    // MARK: - TTP Setup Check

    private func checkTTPSetupComplete() -> Bool {
        // Check each setup item
        let educationViewed = UserDefaults.standard.whenViewedTTPEducation != nil
        let locationGranted = CLLocationManager().authorizationStatus == .authorizedWhenInUse ||
                              CLLocationManager().authorizationStatus == .authorizedAlways

        // TODO: Add these checks when implemented
        // let isSignedIn = UserDefaults.standard.appleUserId != nil
        // let termsAccepted = check ProximityReader terms status

        // For now, only check what's implemented
        return educationViewed && locationGranted
    }
}
