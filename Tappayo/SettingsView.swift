import SwiftUI

struct SettingsView: View {
    @State private var businessName: String = UserDefaults.standard.businessName
    @State private var taxRateBasisPoints: Int = UserDefaults.standard.taxRateBasisPoints
    @State private var taxEnabled: Bool = UserDefaults.standard.taxEnabled
    @State private var tippingEnabled: Bool = UserDefaults.standard.tippingEnabled

    var body: some View {
        Form {
            Section(header: Text("Business name")) {
                TextField("Business name", text: $businessName)
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

            Section(header: Text("Tip")) {
                Toggle("Enable tipping", isOn: $tippingEnabled)
            }

            Section {
                NavigationLink(destination: AboutView()) {
                    Text("About")
                }
            }
        }
        .navigationTitle("Tappayo Settings")
        .onAppear {
            businessName = UserDefaults.standard.businessName
            taxRateBasisPoints = UserDefaults.standard.taxRateBasisPoints
            taxEnabled = UserDefaults.standard.taxEnabled
            tippingEnabled = UserDefaults.standard.tippingEnabled
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
}
