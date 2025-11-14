//    ContentView.swift

import SwiftUI

//extension NumberFormatter // no, define in separate file in utils/ folder

struct ContentView: View {
    @State private var amountInCents: Int = 0
    @State private var basket: [Int] = []
    @State private var connectionStatus = "Not connected"
    
//    Don't just use @State, because we want the Settings changes to take effect immediately; not just after app is re-launched
//    @State private var quickAmounts: [Double] = UserDefaults.standard.quickAmounts
    @State private var quickAmounts: [Int] = UserDefaults.standard.quickAmounts // .map { Int($0 * 100) }
    @State private var myAccentColor: Color = UserDefaults.standard.myAccentColor
    @State private var darkModePreference: String = UserDefaults.standard.darkModePreference
    @State private var showPlusMinusButtons: Bool = UserDefaults.standard.showPlusMinusButtons
    @State private var businessName: String = UserDefaults.standard.businessName
    // actually, this failed because we ran into "immutable" errors for quickActions and accentColor
//    @AppStorageArray(key: "quickAmounts") private var quickAmounts: [Double] = [0.99, 1.00, 5.00, 10.00, 20.00]
//    @AppStorageColor(key: "accentColor") private var accentColor: Color = Color(red: 0.0, green: 214.0 / 255.0, blue: 111.0 / 255.0)
//    @AppStorage("darkModePreference") private var darkModePreference: String = "system"

    let readerDiscoveryController = ReaderDiscoveryViewController()
   
    var totalAmountInCents: Int {
       basket.reduce(0, +)
    }
    
    var formattedTotalAmount: String {
        if totalAmountInCents % 100 == 0 {
            return String(format: "%.0f", Double(totalAmountInCents) / 100.0)
        } else {
            return String(format: "%.2f", Double(totalAmountInCents) / 100.0)
        }
    }

    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    if showPlusMinusButtons {
                        Spacer()

                        Button(action: {
                            if amountInCents > 99 {
                                amountInCents -= 100
                            }
                        }) {
                            Text("-$1")
                        }
                        .padding(4)
                        .foregroundColor(Color.red)
                        .buttonStyle(.bordered)
                        .cornerRadius(8)
                    }

                    Spacer()

                    CurrencyTextField(value: $amountInCents, placeholder: "Enter amount", font: .largeTitle)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .frame(height: 50) // Limit the height
                        .multilineTextAlignment(.center)

                    Spacer()

                    if showPlusMinusButtons {
                        Button(action: {
                            amountInCents += 100
                        }) {
                            Text("+$1")
                        }
                        .padding(4)
                        .foregroundColor(.green)
                        .buttonStyle(.bordered)
                        .cornerRadius(8)

                        Spacer()
                    }
                }
                .padding(.bottom, 12)

                if amountInCents > 0 {
                    HStack {
                        Button(action: {
                            basket.append(amountInCents)
                            amountInCents = 0
                        }) {
                            Text("Add to Cart")
                                .fontWeight(.medium)
                        }
                        .padding()
                        .background(.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)

                        Button(action: {
                            amountInCents = 0
                        }) {
                            Text("Cancel").font(.callout)
                                .fontWeight(.medium)
                        }
                        .padding()
                        .foregroundColor(.red)
                        .cornerRadius(8)
                        .buttonStyle(.bordered)
                    }
                    .padding([.bottom], 10)
                }

                HStack {
                    Text("Quick add items")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.leading)
                        .padding(.top, 8)
                    Spacer()
                }

                let columns = [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ]

                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(quickAmounts.filter({ $0 > 0 }), id: \.self) { quickAmount in
                        Button(action: {
                            basket.append(quickAmount)
                        }) {
                            Text("$\(String(format: "%.2f", Double(quickAmount) / 100.0))")
                                .frame(maxWidth: .infinity)
                        }
                        .padding()
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }
                .padding([.leading, .trailing])
                .padding([.top], 4)
                .padding([.bottom], 14)

                if !basket.isEmpty {
                    Divider()
                    HStack {
                        Text("Cart").font(.headline)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.leading)
                            .padding(.bottom, 6)
                            .padding(.top, 16)
                        Spacer()
                    }
                }

                List {
                    if basket.isEmpty {
                        Text("Cart is empty").font(.subheadline)
                            .foregroundColor(Color(.systemGray2))
                    }
                    ForEach(basket.indices, id: \.self) { index in
                        HStack {
                            Text("Item \(index + 1)")
                            Spacer()
//                            Text("$\(String(format: "%.2f",  basket[index]))") was when we had USD
                            Text("$\(String(format: "%.2f", Double(basket[index]) / 100.0))") // Format to display correctly
                        }
                    }
                    .onDelete(perform: deleteItem)
                    if !basket.isEmpty {
                        HStack {
                            Spacer()
                            Text("Swipe any item left to delete")
                                .font(.caption2)
                                .foregroundColor(Color.gray)
                                .multilineTextAlignment(.center)
                            Spacer()
                        }
                    }
                }
//                .frame(maxHeight: 400) // Adjust height to ensure visibility
                
                Spacer()

                if totalAmountInCents > 49 && amountInCents == 0 {
                    Button(action: {
                        do {
                            try readerDiscoveryController.checkoutAction(amount: totalAmountInCents)
                        } catch {
                            print("Error occurred: \(error)")
                        }
                    }) {
                        HStack{
//                            wave.3.right.circle.fill or wave.3.right.circle
                            Image(systemName: "wave.3.right.circle.fill")
                            Text("Charge card $\(formattedTotalAmount)").font(.title2)
                            .fontWeight(/*@START_MENU_TOKEN@*/.medium/*@END_MENU_TOKEN@*/)
                        }
                    }
                    .padding()
                    .background(.blue) // or accentColor
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .disabled(totalAmountInCents == 0)
                } else if totalAmountInCents > 0 && totalAmountInCents <= 49 {
                    Text("Total amount must be > $0.49. Add more items to cart.")
                        .font(.caption)
                        .foregroundColor(.red)
                }

                Text(connectionStatus)
                    .font(.caption) // Add this line to make the text smaller
                    .foregroundColor(.gray)
                    .padding(.top, 10)
            }
            .padding()
            .onAppear {
                readerDiscoveryController.updateConnectionStatus = { status in
                    self.connectionStatus = status
                }
                readerDiscoveryController.viewDidLoad()
                
                // next lines so the changes we make in settings are reflected immediately, without needing to restart the app
                quickAmounts = UserDefaults.standard.quickAmounts // .map { Int($0 * 100) }
                myAccentColor = UserDefaults.standard.myAccentColor
                darkModePreference = UserDefaults.standard.darkModePreference
                showPlusMinusButtons = UserDefaults.standard.showPlusMinusButtons
                businessName = UserDefaults.standard.businessName
                applyDarkModePreference()
            }
            .navigationTitle(businessName)
            .navigationBarItems(trailing: NavigationLink(destination: SettingsView()) {
                Text("Settings").foregroundColor(myAccentColor)
            })
            .background( // this is to dismiss the keyboard when the user taps outside the text field
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
            )
        }
    }
    
    private func deleteItem(at offsets: IndexSet) {
        basket.remove(atOffsets: offsets)
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
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
