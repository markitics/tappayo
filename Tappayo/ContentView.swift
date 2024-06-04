//
//  ContentView.swift
//  Tappayo
//
//  Created by M@rkMoriarty.com
//

import SwiftUI

struct ContentView: View {
    @State var counter = 1
    @State private var connectionStatus = "Not connected"
    
    let readerDiscoveryController = ReaderDiscoveryViewController()
    
    var body: some View {
        VStack {
            TerminalConnectionView(connectionStatus: $connectionStatus)
            
            // Button in SwiftUI that calls the checkoutAction method
            Button("Charge Card") {
                // Check if already connected and proceed to checkout
                do {
                    try readerDiscoveryController.checkoutAction(amount: counter)
                    print("in ContentView, tried checkoutAction with amount: \(counter)")
                } catch {
                    // Handle errors here
                    print("Error occurred: \(error)")
                }
            }
            .padding()

            Spacer()
            Image(systemName: "globe")
                .imageScale(.large)
//                .foregroundColor(.accentColor)
            Text("Hello, world!").padding()
            Spacer()
            Text("Clicked \(counter) times").padding()
            HStack {
                Button("minus") {
                    if counter > 0 {
                        print("clicked -1")
                        counter -= 1
                    } else {
                        print("clicked -1, but min value is zero")
                    }
                }
                Button("plus") {
                    print("clicked +1")
                    counter += 1
                }
            }
            
            Spacer()
        }
        .padding()
        .onAppear {
            readerDiscoveryController.updateConnectionStatus = { status in
                self.connectionStatus = status
            }
            readerDiscoveryController.viewDidLoad() // Call viewDidLoad to initiate the reader discovery
//        ChatGPT: You are correct that viewDidLoad() is a method from UIViewController that gets called automatically when the view controller's view is loaded into memory. Normally, you do not need to call viewDidLoad() manually; it is automatically called by the system when the view controller's view is created.
//            Clarifying viewDidLoad
//            In a standard UIKit application, the view controller's lifecycle methods like viewDidLoad(), viewWillAppear(), etc., are automatically managed by the system. However, since you're integrating with SwiftUI, we need to ensure the lifecycle methods are correctly called when transitioning between SwiftUI and UIKit components.
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


