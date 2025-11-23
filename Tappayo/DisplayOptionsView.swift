//  DisplayOptionsView.swift
//  Tappayo
//
//  Dedicated screen for display and appearance settings

import SwiftUI

struct DisplayOptionsView: View {
    @State private var myAccentColor: Color = UserDefaults.standard.myAccentColor
    @State private var darkModePreference: String = UserDefaults.standard.darkModePreference
    @State private var inputMode: String = UserDefaults.standard.inputMode
    @State private var dismissKeypadAfterAdd: String = UserDefaults.standard.dismissKeypadAfterAdd

    var body: some View {
        Form {
            Section(header: Text("Accent Color")) {
                ColorPicker("Pick a color", selection: $myAccentColor)
                if myAccentColor != Color(red: 0.0, green: 214.0 / 255.0, blue: 111.0 / 255.0) {
                    Button("Restore Default Color") {
                        myAccentColor = Color(red: 0.0, green: 214.0 / 255.0, blue: 111.0 / 255.0)
                    }
                    .foregroundColor(myAccentColor)
                }
            }

            Section(header: Text("Dark Mode")) {
                Picker(darkModePreferenceHeader, selection: $darkModePreference) {
                    Text("iPhone default").tag("system")
                    Text("Dark").tag("on")
                    Text("Light").tag("off")
                }
            }

            Section(header: Text("Input Mode")) {
                Picker(inputModeHeader, selection: $inputMode) {
                    Text("I'll type cents, like $5.99 or $5.00").tag("cents")
                    Text("Only whole numbers, like $5, $50").tag("dollars")
                }
            }

            Section(header: Text("Keypad Behavior")) {
                Picker(keypadBehaviorHeader, selection: $dismissKeypadAfterAdd) {
                    Text("Dismiss keypad after adding a manual price").tag("dismiss")
                    Text("Quickly adding multiple custom items").tag("stay")
                }
            }
        }
        .navigationTitle("Display Options")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            myAccentColor = UserDefaults.standard.myAccentColor
            darkModePreference = UserDefaults.standard.darkModePreference
            inputMode = UserDefaults.standard.inputMode
            dismissKeypadAfterAdd = UserDefaults.standard.dismissKeypadAfterAdd
            applyDarkModePreference()
        }
        .onChange(of: myAccentColor) { _, newValue in
            UserDefaults.standard.myAccentColor = newValue
        }
        .onChange(of: darkModePreference) { _, _ in
            UserDefaults.standard.darkModePreference = darkModePreference
            applyDarkModePreference()
        }
        .onChange(of: inputMode) { _, newValue in
            UserDefaults.standard.inputMode = newValue
        }
        .onChange(of: dismissKeypadAfterAdd) { _, newValue in
            UserDefaults.standard.dismissKeypadAfterAdd = newValue
        }
    }

    private func applyDarkModePreference() {
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

    private var darkModePreferenceHeader: String {
        switch darkModePreference {
        case "on":
            return "Dark mode on"
        case "off":
            return "Always off"
        default:
            return "System setting"
        }
    }

    private var inputModeHeader: String {
        switch inputMode {
        case "dollars":
            return "Only whole numbers"
        default:
            return "Input mode"
        }
    }

    private var keypadBehaviorHeader: String {
        switch dismissKeypadAfterAdd {
        case "stay":
            return "Stay in keypad mode"
        default:
            return "Dismiss keypad after adding to cart"
        }
    }
}
