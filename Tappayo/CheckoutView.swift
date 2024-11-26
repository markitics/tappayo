//  CheckoutView.swift
//  Tappayo
//  Created by M@rkMoriarty.com

//import Foundation
import SwiftUI

struct CheckoutView: View {
    let amount: Double
    let readerDiscoveryController: ReaderDiscoveryViewController
    
    var body: some View {
        VStack {
            Text("Amount to be charged: $\(String(format: "%.2f", amount))")
                .font(.largeTitle)
                .padding()
            
            Spacer()
            
            Button("Tap to Pay") {
                // Proceed to checkout
                do {
                    try readerDiscoveryController.checkoutAction(amount: Int(amount))
                    print("Checkout action with amount: \(amount)")
                } catch {
                    // Handle errors here
                    print("Error occurred: \(error)")
                }
            }
            .padding()
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(10)
            .padding(.bottom, 20)
            
            Spacer()
        }
        .padding()
    }
}

struct CheckoutView_Previews: PreviewProvider {
    static var previews: some View {
        CheckoutView(amount: 10.00, readerDiscoveryController: ReaderDiscoveryViewController())
    }
}
