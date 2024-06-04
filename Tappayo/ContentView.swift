import SwiftUI

struct ContentView: View {
    @State private var amount: Double = 0.00
    @State private var basket: [Double] = []
    @State private var connectionStatus = "Not connected"
    
    @State private var quickAmounts: [Double] = UserDefaults.standard.quickAmounts
    @State private var accentColor: Color = UserDefaults.standard.accentColor
    
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
                Spacer()
                
                Text("Item Subtotal")
                    .font(.headline)
                    .padding(.top, 20)
                
                Text("$\(amount, specifier: "%.2f")")
                    .font(.largeTitle)
                
                HStack {
                    Button(action: {
                        amount = max(0, amount - 1.00)
                    }) {
                        Text("-$1")
                            .font(.title)
                            .padding()
                    }
                    .background(accentColor)
                    .cornerRadius(10)
                    .foregroundColor(.white)
                    
                    Button(action: {
                        amount += 1.00
                    }) {
                        Text("+$1")
                            .font(.title)
                            .padding()
                    }
                    .background(accentColor)
                    .cornerRadius(10)
                    .foregroundColor(.white)
                }
                
                HStack {
                    ForEach(quickAmounts, id: \.self) { amount in
                        Button(action: {
                            self.amount = amount
                        }) {
                            Text("$\(amount, specifier: "%.2f")")
                                .font(.title)
                                .padding()
                        }
                        .background(accentColor)
                        .cornerRadius(10)
                        .foregroundColor(.white)
                    }
                }
                
                Button(action: {
                    if amount > 0 {
                        basket.append(amount)
                        amount = 0.00
                    }
                }) {
                    Text("Add to Basket")
                        .font(.title)
                        .padding()
                }
                .background(accentColor)
                .cornerRadius(10)
                .foregroundColor(.white)
                .padding(.bottom, 20)
                
                if !basket.isEmpty {
                    BasketView(basket: $basket, readerDiscoveryController: <#ReaderDiscoveryViewController#>)
                }
                
                if totalAmount > 0 {
                    Button(action: {
                        do {
                            try readerDiscoveryController.checkoutAction(amount: Int(totalAmount))
                        } catch {
                            print("Error occurred: \(error)")
                        }
                    }) {
                        Text("Charge Card $\(formattedTotalAmount)")
                            .font(.title)
                            .padding()
                    }
                    .background(accentColor)
                    .cornerRadius(10)
                    .foregroundColor(.white)
                    .padding(.bottom, 20)
                }
                
                Spacer()
                
                Text(connectionStatus)
                    .foregroundColor(.gray)
                    .padding(.bottom, 20)
            }
            .navigationBarItems(trailing: NavigationLink(destination: SettingsView()) {
                Text("Settings")
            })
        }
    }
}
