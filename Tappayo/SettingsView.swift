import SwiftUI

struct SettingsView: View {
    @State private var quickAmounts: [Double] = UserDefaults.standard.quickAmounts
    @State private var accentColor: Color = UserDefaults.standard.accentColor
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
//                Label("Swipe left to delete one")
//                Text("Swipe left to delete an option")
            }
            
            
            
            Section(header: Text("Pick Accent Color")) {
                ColorPicker("Pick a color", selection: $accentColor)
                Button("Restore Default Color") {
                    accentColor = Color(red: 0.0, green: 214.0 / 255.0, blue: 111.0 / 255.0)
                }
            }

            Section(header: Text("Dark Mode")) {
                Picker("Dark Mode", selection: $darkModePreference) {
                    Text("System").tag("system")
                    Text("On").tag("on")
                    Text("Off").tag("off")
                }
                .pickerStyle(SegmentedPickerStyle())
            }
        }
        .navigationBarTitle("Settings")
        .onDisappear {
            UserDefaults.standard.quickAmounts = quickAmounts
            UserDefaults.standard.accentColor = accentColor
            UserDefaults.standard.darkModePreference = darkModePreference
        }
        .onChange(of: quickAmounts) { newValue in
            UserDefaults.standard.quickAmounts = newValue
        }
        .onChange(of: accentColor) { newValue in
            UserDefaults.standard.accentColor = newValue
        }
        .onChange(of: darkModePreference) { newValue in
            UserDefaults.standard.darkModePreference = newValue
            if let contentView = UIApplication.shared.windows.first?.rootViewController as? UIHostingController<ContentView> {
                contentView.rootView.applyDarkModePreference()
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
