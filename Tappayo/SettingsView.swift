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
    @State private var quickAmounts: [Double] = UserDefaults.standard.quickAmounts
    @State var myAccentColor: Color = UserDefaults.standard.myAccentColor
    @State private var darkModePreference: String = UserDefaults.standard.darkModePreference

    let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    var body: some View {
        Form {
            Section(header: Text("Quick Amounts")) {
                ForEach(quickAmounts.indices, id: \.self) { index in
                    HStack {
                        Text("$")
                        TextField("Quick Amount \(index + 1)", value: $quickAmounts[index], formatter: numberFormatter)
                            .keyboardType(.decimalPad)
                    }
                }
                .onDelete { indexSet in
                    quickAmounts.remove(atOffsets: indexSet)
                }
                
                Button(action: {
                    quickAmounts.append(0.00)
                }) {
                    Text("Add Quick Amount")
                }
                .foregroundColor(myAccentColor)
            }

            Section(header: Text("Pick Accent Color")) {
                ColorPicker("Pick a color", selection: $myAccentColor)
                if(myAccentColor != Color(red: 0.0, green: 214.0 / 255.0, blue: 111.0 / 255.0)){
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
        }
        .navigationBarTitle("Settings")
        .onDisappear {
            UserDefaults.standard.quickAmounts = quickAmounts
            UserDefaults.standard.myAccentColor = myAccentColor
            UserDefaults.standard.darkModePreference = darkModePreference
        }
        .onAppear {
            quickAmounts = UserDefaults.standard.quickAmounts
            myAccentColor = UserDefaults.standard.myAccentColor
            darkModePreference = UserDefaults.standard.darkModePreference
            applyDarkModePreference()
        }
        .onChange(of: quickAmounts) { newValue in
               UserDefaults.standard.quickAmounts = newValue
           }
        .onChange(of: darkModePreference) { _ in
            // Ensure accent dark mode preference, set in the Settings page, updates immediately
            UserDefaults.standard.darkModePreference = darkModePreference
            applyDarkModePreference()
        }
        .onChange(of: myAccentColor) { newValue in
            // Ensure accent color updates immediately
            UserDefaults.standard.myAccentColor = newValue
            if let contentView = UIApplication.shared.windows.first?.rootViewController as? UIHostingController<SettingsView> {
                contentView.rootView.myAccentColor = myAccentColor
            }
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
