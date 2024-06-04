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
                VStack {
                    Text("Item subtotal")
                        .font(.headline)
                        .padding(.top, 8)
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
//                        .background(accentColor)
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }
                .padding([.leading, .trailing])
                .padding([.top], 16)
//                .padding([.bottom], 0)
                
                if amount > 0 {
                    Button(action: {
                        if amount > 0 {
                            basket.append(amount)
                            amount = 0.00
                        }
                    }) {
                        Text("Add to Cart")
                    }
                    .padding()
                    .background(.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                } else {
                    Spacer().frame(height: 36) // Maintain space when button is hidden
                    if(!basket.isEmpty){
                        Text("Cart").font(.subheadline)
//                            .foregroundColor(Color.white)
                            .padding(.bottom, 0)
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

                if totalAmount > 0 {
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
                            Text("Charge card $\(formattedTotalAmount)").font(.subheadline).fontWeight(/*@START_MENU_TOKEN@*/.medium/*@END_MENU_TOKEN@*/)
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
                
                Spacer()
            }
            .padding()
            .onAppear {
                readerDiscoveryController.updateConnectionStatus = { status in
                    self.connectionStatus = status
                }
                readerDiscoveryController.viewDidLoad()
            }
            .navigationBarTitle("Tappayo")
//            .foregroundColor(accentColor)
            .navigationBarItems(trailing: NavigationLink(destination: SettingsView()) {
                Text("Settings").foregroundColor(accentColor)
            })
        }
    }
    
    private func deleteItem(at offsets: IndexSet) {
        basket.remove(atOffsets: offsets)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
