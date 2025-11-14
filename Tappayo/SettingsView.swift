// SettingsView old - when changes did take effect

//    SettingsView.swift

//    Either use @State private var...
//    or use AppStorage

//    To get around this error: "Cannot use mutating member on immutable value: 'self' is immutable"
//    , let's try using a @State property for the array and update the @AppStorage property whenever the array changes. This approach will help us handle the mutability correctly. Here’s how you can adjust your SettingsView.swift:
//    @State private var quickAmountsState: [Double] = []

import SwiftUI

struct SettingsView: View {
    @State private var quickAmounts: [Int] = UserDefaults.standard.quickAmounts
    @State var myAccentColor: Color = UserDefaults.standard.myAccentColor
    @State private var darkModePreference: String = UserDefaults.standard.darkModePreference
    @FocusState private var focusedIndex: Int?
    
    var body: some View {
        Form {
            Section(header: Text("Quick Amounts")) {
                ForEach(quickAmounts.indices, id: \.self) { index in
                    HStack {
                        CurrencyTextField(value: $quickAmounts[index], placeholder: "Quick amount \(index + 1)", font: .body)
                            .multilineTextAlignment(.leading)
                            .focused($focusedIndex, equals: index)
                            // .keyboardType(.decimalPad) -> defined in CurrencyTextField.swift
                    }
                }
                .onDelete { indexSet in
                    quickAmounts.remove(atOffsets: indexSet)
                }
                
                Button(action: {
                    quickAmounts.append(0)
                    focusedIndex = quickAmounts.count - 1
                }) {
                    Text("Add Quick Amount")
                }
                .foregroundColor(myAccentColor)
                
                Text(quickAmounts.isEmpty ? "Add a shortcut for any common amounts" : "Swipe left to delete any quick amount")
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

            Section {
                NavigationLink(destination: AboutView()) {
                    Text("About")
                }
            }
        }
        .navigationTitle("Settings")
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

