//    SettingsView.swift

//    No, not @State private var...
//    @State private var quickAmounts: [Double] = UserDefaults.standard.quickAmounts
//    @State private var accentColor: Color = UserDefaults.standard.accentColor
//    @State private var darkModePreference: String = UserDefaults.standard.darkModePreference
    
//    ...instead, let's use AppStorage, so hopefully the Settings changes will take place immediately    


//    To get around this error: "Cannot use mutating member on immutable value: 'self' is immutable"
//    , let's try using a @State property for the array and update the @AppStorage property whenever the array changes. This approach will help us handle the mutability correctly. Here’s how you can adjust your SettingsView.swift:
//    @State private var quickAmountsState: [Double] = []

import SwiftUI

struct SettingsView: View {
//    @State private var quickAmounts: [Double] = UserDefaults.standard.quickAmounts
    @State private var quickAmounts: [Int] = UserDefaults.standard.quickAmounts//.map { Int($0 * 100) }
    @State var myAccentColor: Color = UserDefaults.standard.myAccentColor
    @State private var darkModePreference: String = UserDefaults.standard.darkModePreference
    @State private var isHappy: Bool = true
    
//    let currencyFormatter: NumberFormatter = {
//        let formatter = NumberFormatter()
//        formatter.numberStyle = .currency
//        formatter.minimumFractionDigits = 2
//        formatter.maximumFractionDigits = 2
//        // not formatter.locale = Locale.current
//        formatter.currencyCode = "USD" // Hardcoding USD
//        formatter.multiplier = 0.01 // To format integers as currency
//        return formatter
//    }()

    var body: some View {
        Form {
            Section(header: Text("Quick Amounts")) {
                ForEach(quickAmounts.indices, id: \.self) { index in
                    HStack {
//                            Text("$")
                        CurrencyTextField(value: $quickAmounts[index], placeholder: "Quick amount \(index + 1)", font: .body)
                            .multilineTextAlignment(.leading)
//                        .keyboardType(.decimalPad) -> defined in CurrencyTextField.swift
                    }
                }
                .onDelete { indexSet in
                    quickAmounts.remove(atOffsets: indexSet)
                }
                
                Button(action: {
                    quickAmounts.append(0)
                }) {
                    Text("Add Quick Amount")
                }
                .foregroundColor(myAccentColor)
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
//                .pickerStyle(SegmentedPickerStyle())
            }

            Section(header: Text("Mood")) {
                Toggle(isOn: $isHappy) {
                    Text(isHappy ? "Happy" : "Sad")
                }
            }

            // New About Section
            Section {
                NavigationLink(destination: AboutView()) {
                    Text("About")
                }
            }
        }
        .navigationTitle("Settings")
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
