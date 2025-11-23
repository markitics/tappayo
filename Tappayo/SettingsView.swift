import SwiftUI

struct SettingsView: View {
    @State private var businessName: String = UserDefaults.standard.businessName
    @State private var taxRate: Double = UserDefaults.standard.taxRate

    var body: some View {
        Form {
            Section(header: Text("Business")) {
                TextField("Business name", text: $businessName)
            }

            Section(header: Text("Products")) {
                NavigationLink(destination: ProductsView()) {
                    Text("Manage Products")
                }
            }

            Section(header: Text("Display")) {
                NavigationLink(destination: DisplayOptionsView()) {
                    Text("Display Options")
                }
            }

            Section(header: Text("Tax")) {
                HStack {
                    TextField("Tax %", value: $taxRate, format: .number.precision(.fractionLength(0...2)))
                        .keyboardType(.decimalPad)
                    Text("%")
                        .foregroundColor(.secondary)
                }
                Text("Enter tax rate as percentage (0 = no tax, max 2 decimals)")
                    .font(.caption)
                    .foregroundColor(.gray)
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
            taxRate = UserDefaults.standard.taxRate
        }
        .onChange(of: businessName) { _, newValue in
            UserDefaults.standard.businessName = newValue
        }
        .onChange(of: taxRate) { _, newValue in
            UserDefaults.standard.taxRate = newValue
        }
    }
}
