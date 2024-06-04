import SwiftUI

struct SettingsView: View {
    @State private var quickAmounts: [Double] = UserDefaults.standard.quickAmounts
    @State private var accentColor: Color = UserDefaults.standard.accentColor

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
            }
            
            Section(header: Text("Pick Accent Color")) {
                ColorPicker("Pick a color", selection: $accentColor)
                Button("Restore default color") {
                    accentColor = Color(red: 0.0, green: 214.0 / 255.0, blue: 111.0 / 255.0)
                }
            }
        }
        .navigationBarTitle("Settings")
        .onDisappear {
            UserDefaults.standard.quickAmounts = quickAmounts
            UserDefaults.standard.accentColor = accentColor
        }
        .onChange(of: quickAmounts) { newValue in
            UserDefaults.standard.quickAmounts = newValue
        }
        .onChange(of: accentColor) { newValue in
            UserDefaults.standard.accentColor = newValue
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
