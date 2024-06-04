import SwiftUI

struct ContentView: View {
    @State private var amount: Double = 0.00
    @State private var basket: [Double] = []
    @State private var connectionStatus = "Not connected"
    
//    Don't just use @State, because we want the Settings changes to take effect immediately; not just after app is re-launched
    @State private var quickAmounts: [Double] = UserDefaults.standard.quickAmounts
    @State private var myAccentColor: Color = UserDefaults.standard.myAccentColor
    @State private var darkModePreference: String = UserDefaults.standard.darkModePreference
    // actually, this failed because we ran into "immutable" errors for quickActions and accentColor
//    @AppStorageArray(key: "quickAmounts") private var quickAmounts: [Double] = [0.99, 1.00, 5.00, 10.00, 20.00]
//    @AppStorageColor(key: "accentColor") private var accentColor: Color = Color(red: 0.0, green: 214.0 / 255.0, blue: 111.0 / 255.0)
//    @AppStorage("darkModePreference") private var darkModePreference: String = "system"

    let readerDiscoveryController = ReaderDiscoveryViewController()
    
    var totalAmount: Double {
        basket.reduce(0, +)
    }
    
    var formattedTotalAmount: String {
        if totalAmount.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", totalAmount)
        } else {
            return String(format: "%.2f", totalAmount)
        }
    }

    var body: some View {
        NavigationView {
            VStack {
                HStack{
                    Text("Add item")
                        .font(.headline)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.leading)
                        .padding(.top, 8)
                    Spacer()
                }
                
                HStack {
                    Spacer()
                    
                    Button(action: {
                        if amount > 0 {
                            amount -= 1.00
                        }
                    }) {
                        Text("-$1")
                    }
                    .padding(4)
//                        .background(Color.red)
                    .foregroundColor(Color.red)
//                        .border(/*@START_MENU_TOKEN@*/Color.black/*@END_MENU_TOKEN@*/)
                    .buttonStyle(.bordered)
//                        .buttonStyle(.borderedProminent)
//                        .font(.red)
                    .cornerRadius(8)
                    
                    Spacer()
                    
                    Text("$\(String(format: "%.2f", amount))")
                        .font(.largeTitle)
                    
                    Spacer()
                    
                    Button(action: {
                        amount += 1.00
                    }) {
                        Text("+$1")
                    }
                    .padding(4)
//                        .background(Color.green)
//                        .foregroundColor(.white)
                    .foregroundColor(.green)
                    .buttonStyle(.bordered)
                    .cornerRadius(8)
                    
                    Spacer()
                }
                
//              .padding()
                
                HStack {
                    ForEach(quickAmounts.filter({ $0 > 0 }), id: \.self) { quickAmount in
                        Button(action: {
                            amount = quickAmount
                        }) {
                            Text("$\(String(format: "%.2f", quickAmount))")
                        }
                        .padding()
//                        .background(myAccentColor)
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }
                .padding([.leading, .trailing])
                .padding([.top], 4)
                .padding([.bottom], 14)
                
                if amount > 0 {
                
                    HStack{
                        Button(action: {
                            basket.append(amount)
                            amount = 0.00
                        }) {
                            Text("Add to Cart")
                                .fontWeight(.medium)
                        }
                        .padding()
                        .background(.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        
//                        Spacer()
                        
                        Button(action: {
                            amount = 0.00
                        }) {
                            Text("Cancel").font(.callout)
                                .fontWeight(.medium)
                        }
                        .padding()
//                        .background(.blue)
                        .foregroundColor(.red)
                        .cornerRadius(8)
                        .buttonStyle(.bordered)
                    }.padding([.bottom], 10)
                    
                } else {
                    Spacer().frame(height: 34) // Maintain space when button is hidden
                    if(!basket.isEmpty){
                        Divider()
                        HStack{
                            Text("Cart").font(.headline)
        //                            .foregroundColor(Color.white)
                                .fontWeight(.bold)
                                .multilineTextAlignment(.leading)
                                .padding(.bottom, 6)
                                .padding(.top, 16)
                            Spacer()
                        }
                    }
                }

                List {
                    if(basket.isEmpty){
                        Text("Cart is empty").font(.subheadline).foregroundColor(Color.gray)
                    }
                    ForEach(basket.indices, id: \.self) { index in
                        HStack {
                            Text("Item \(index + 1)")
                            Spacer()
                            Text("$\(String(format: "%.2f", basket[index]))")
                        }
                    }
                    .onDelete(perform: deleteItem)
                    if(!basket.isEmpty){
                        HStack{
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
                Spacer()

                if totalAmount > 0 && !(amount > 0) {
//                    TODO Text("Total amount: \(totalAmount)")
//                    TODO Text("Total amount (cents): \(totalAmount)")
                    Button(action: {
                        do {
                            try readerDiscoveryController.checkoutAction(amount: Int(totalAmount * 100)) // TODO maybe just convert totalAmount to an integer number of cents
                        } catch {
                            print("Error occurred: \(error)")
                        }
                    }) {
                        HStack{
//                            wave.3.right.circle.fill or wave.3.right.circle
                            Image(systemName: "wave.3.right.circle.fill")
//                            Text("\(Image(systemName: "wave.3.right.circle")) Charge Card $\(formattedTotalAmount)")
                            Text("Charge card $\(formattedTotalAmount)").font(.title2).fontWeight(/*@START_MENU_TOKEN@*/.medium/*@END_MENU_TOKEN@*/)
                        }
                        
                    }
                    .padding()
                    .background(.blue) // or accentColor
                    .foregroundColor(.white)
                    .cornerRadius(8)

                    .disabled(totalAmount == 0)
                }
                
                
                Text(connectionStatus)
                    .font(.caption) // Add this line to make the text smaller
                    .foregroundColor(.gray)
                    .padding(.top, 10)
                
//                Spacer()
            }
            .padding()
            .onAppear {
                readerDiscoveryController.updateConnectionStatus = { status in
                    self.connectionStatus = status
                }
                readerDiscoveryController.viewDidLoad()
                
                // next four lines so the changes we make in settings are reflected immediately, without needing to restart the app
                quickAmounts = UserDefaults.standard.quickAmounts
                myAccentColor = UserDefaults.standard.myAccentColor
                darkModePreference = UserDefaults.standard.darkModePreference
                applyDarkModePreference()
            }
//            Since we are using UserDefaults and updating the state variables on onAppear and onDisappear in SettingsView.swift, these onChange handlers are not necessary in ContentView.swift.
//            .onChange(of: darkModePreference) { _ in
//                // Ensure accent dark mode preference, set in the Settings page, updates immediately
//                applyDarkModePreference()
//            }
//            .onChange(of: accentColor) { _ in
//                // Ensure accent color updates immediately
//                if let contentView = UIApplication.shared.windows.first?.rootViewController as? UIHostingController<ContentView> {
//                    contentView.rootView.accentColor = accentColor
//                }
//            }
//            .onChange(of: quickAmounts) { _ in
//                // Ensure quick amounts updates immediately
//                if let contentView = UIApplication.shared.windows.first?.rootViewController as? UIHostingController<ContentView> {
//                    contentView.rootView.quickAmounts = quickAmounts
//                }
//            }
            .navigationBarTitle("Tappayo")
//            .foregroundColor(accentColor)
            .navigationBarItems(trailing: NavigationLink(destination: SettingsView()) {
                Text("Settings").foregroundColor(myAccentColor)
            })
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
