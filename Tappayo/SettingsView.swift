// SettingsView old - when changes did take effect

//    SettingsView.swift

//    Either use @State private var...
//    or use AppStorage

//    To get around this error: "Cannot use mutating member on immutable value: 'self' is immutable"
//    , let's try using a @State property for the array and update the @AppStorage property whenever the array changes. This approach will help us handle the mutability correctly. Here’s how you can adjust your SettingsView.swift:
//    @State private var quickAmountsState: [Double] = []

import SwiftUI

struct SettingsView: View {
    @State private var savedProducts: [Product] = UserDefaults.standard.savedProducts
    @State var myAccentColor: Color = UserDefaults.standard.myAccentColor
    @State private var darkModePreference: String = UserDefaults.standard.darkModePreference
    @State private var showPlusMinusButtons: Bool = UserDefaults.standard.showPlusMinusButtons
    @State private var businessName: String = UserDefaults.standard.businessName
    @State private var taxRate: Double = UserDefaults.standard.taxRate
    @FocusState private var focusedField: UUID?
    
    var body: some View {
        Form {
            Section(header: Text("Business Name")) {
                TextField("Business name", text: $businessName)
            }

            Section(header: Text("Saved Products")) {
                ForEach(savedProducts.indices, id: \.self) { index in
                    VStack(alignment: .leading, spacing: 8) {
                        TextField("Product name", text: Binding(
                            get: { savedProducts[index].name },
                            set: { savedProducts[index].name = $0 }
                        ))
                        .focused($focusedField, equals: savedProducts[index].id)

                        CurrencyTextField(
                            value: Binding(
                                get: { savedProducts[index].priceInCents },
                                set: { savedProducts[index].priceInCents = $0 }
                            ),
                            placeholder: "Price",
                            font: .body
                        )
                        .multilineTextAlignment(.leading)
                    }
                    .padding(.vertical, 4)
                }
                .onDelete { indexSet in
                    savedProducts.remove(atOffsets: indexSet)
                }

                Button(action: {
                    let newProduct = Product(name: "", priceInCents: 0)
                    savedProducts.append(newProduct)
                    focusedField = newProduct.id
                }) {
                    Text("Add Product")
                }
                .foregroundColor(myAccentColor)

                Text(savedProducts.isEmpty ? "Add products with names and prices for quick checkout" : "Swipe left to delete any product")
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Section(header: Text("Pick Accent Color")) {
                ColorPicker("Pick a color", selection: $myAccentColor)
                if myAccentColor != Color(red: 0.0, green: 214.0 / 255.0, blue: 111.0 / 255.0) {
                    Button("Restore Default Color") {
                        myAccentColor = Color(red: 0.0, green: 214.0 / 255.0, blue: 111.0 / 255.0)
                    }.foregroundColor(myAccentColor)
                }
            }

            Section(header: Text("Dark Mode")) {
                Picker(darkModePreferenceHeader, selection: $darkModePreference) {
                    Text("iPhone default").tag("system")
                    Text("Dark").tag("on")
                    Text("Light").tag("off")
                }
            }

            Section(header: Text("Display Options")) {
                Toggle("Show +$1/-$1 buttons", isOn: $showPlusMinusButtons)
            }

            Section(header: Text("Tax Rate")) {
                HStack {
                    TextField("Tax %", value: $taxRate, format: .number)
                        .keyboardType(.decimalPad)
                    Text("%")
                        .foregroundColor(.secondary)
                }
                Text("Enter tax rate as percentage (0 = no tax)")
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
        .onDisappear {
            UserDefaults.standard.savedProducts = savedProducts
            UserDefaults.standard.myAccentColor = myAccentColor
            UserDefaults.standard.darkModePreference = darkModePreference
            UserDefaults.standard.showPlusMinusButtons = showPlusMinusButtons
            UserDefaults.standard.businessName = businessName
            UserDefaults.standard.taxRate = taxRate
        }
        .onAppear {
            savedProducts = UserDefaults.standard.savedProducts
            myAccentColor = UserDefaults.standard.myAccentColor
            darkModePreference = UserDefaults.standard.darkModePreference
            showPlusMinusButtons = UserDefaults.standard.showPlusMinusButtons
            businessName = UserDefaults.standard.businessName
            taxRate = UserDefaults.standard.taxRate
            applyDarkModePreference()

            // Update navigation bar appearance
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(myAccentColor)
            appearance.titleTextAttributes = [.foregroundColor: UIColor(myAccentColor)]
            appearance.largeTitleTextAttributes = [.foregroundColor: UIColor(myAccentColor)]

            UINavigationBar.appearance().standardAppearance = appearance
            UINavigationBar.appearance().compactAppearance = appearance
            UINavigationBar.appearance().scrollEdgeAppearance = appearance
            UINavigationBar.appearance().tintColor = UIColor(myAccentColor)
        }
        .onChange(of: savedProducts) { newValue in
            UserDefaults.standard.savedProducts = newValue
        }
        .onChange(of: darkModePreference) { _ in
            // Ensure accent dark mode preference, set in the Settings page, updates immediately
            UserDefaults.standard.darkModePreference = darkModePreference
            applyDarkModePreference()
        }
        .onChange(of: myAccentColor) { newValue in
            // Ensure accent color updates immediately
            UserDefaults.standard.myAccentColor = newValue
        }
        .onChange(of: showPlusMinusButtons) { newValue in
            UserDefaults.standard.showPlusMinusButtons = newValue
        }
        .onChange(of: businessName) { newValue in
            UserDefaults.standard.businessName = newValue
        }
        .onChange(of: taxRate) { newValue in
            UserDefaults.standard.taxRate = newValue
        }
    }
    
    //    private
    func applyDarkModePreference() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        guard let window = windowScene.windows.first else { return }
        switch darkModePreference {
        case "on":
            window.overrideUserInterfaceStyle = .dark
        case "off":
            window.overrideUserInterfaceStyle = .light
        default:
            window.overrideUserInterfaceStyle = .unspecified
        }
    }
    
    var darkModePreferenceHeader: String {
        switch darkModePreference {
        case "on":
            return "Dark mode on"
        case "off":
            return "Always off"
        default:
            return "System setting"
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}

