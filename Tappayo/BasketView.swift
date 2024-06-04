//  BasketView.swift
//  Tappayo
//  Created by M@rkMoriarty.com

import SwiftUI

struct BasketView: View {
    @Binding var basket: [Double]
    let readerDiscoveryController: ReaderDiscoveryViewController
    @State private var navigateToCheckout = false
    
    var totalAmount: Double {
        basket.reduce(0, +)
    }
    
    var body: some View {
        VStack {
            List {
                ForEach(basket.indices, id: \.self) { index in
                    HStack {
                        Text("Item \(index + 1)")
                        Spacer()
                        Text("$\(String(format: "%.2f", basket[index]))")
                    }
                }
                .onDelete(perform: deleteItem)
            }
            
            Text("Total: $\(String(format: "%.2f", totalAmount))")
                .font(.largeTitle)
                .padding()
            
            // Navigate to Checkout
            NavigationLink(destination: CheckoutView(amount: totalAmount, readerDiscoveryController: readerDiscoveryController), isActive: $navigateToCheckout) {
                EmptyView()
            }
            
            Button("Proceed to Checkout") {
                navigateToCheckout = true
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            .padding(.bottom, 20)
            
            Spacer()
        }
        .padding()
    }
    
    private func deleteItem(at offsets: IndexSet) {
        basket.remove(atOffsets: offsets)
    }
}

struct BasketView_Previews: PreviewProvider {
    static var previews: some View {
        BasketView(basket: .constant([1.00, 1.99, 5.00]), readerDiscoveryController: ReaderDiscoveryViewController())
    }
}
