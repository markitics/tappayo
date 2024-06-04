import SwiftUI

struct SettingsView: View {
    @State private var quickAmounts: [Double] = UserDefaults.standard.quickAmounts
    @State private var accentColor: Color = UserDefaults.standard.accentColor

    var body: some View {
        Form {
            Section(header: Text("Quick Amounts")) {
                ForEach(quickAmounts.indices, id: \.self) { index in
                    TextField("Quick Amount \(index + 1)", value: $quickAmounts[index], formatter: NumberFormatter())
                        .keyboardType(.decimalPad)
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
            }
        }
        .navigationBarTitle("Settings")
        .onDisappear {
            UserDefaults.standard.quickAmounts = quickAmounts
            UserDefaults.standard.accentColor = accentColor
        }
    }
}
