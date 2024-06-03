//
//  ContentView.swift
//  Tappayo
//
//  Created by M@rkMoriarty.com on 4/16/24.
//

import SwiftUI

struct ContentView: View {
    @State var counter = 1
    @State private var connectionStatus = "Not connected"
    
    let readerDiscoveryController = ReaderDiscoveryViewController()
    
    var body: some View {
        
        
        VStack {
            TerminalConnectionView(connectionStatus: $connectionStatus)
            // Button in SwiftUI that calls the discoverReadersAction method
            Button("Discover Readers") {
                // Since discoverReadersAction is a throwing function, it needs to be called within a do-catch block
                do {
                    try readerDiscoveryController.discoverReadersAction()
                    print("in ContentView, tried discoverReadersAction")
                } catch {
                    // Handle errors here
                    print("Error occurred: \(error)")
                }
            }
            .padding()

            Spacer()
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundColor(.accentColor)
            Text("Hello, world!").padding()
            Spacer()
            
            
            Text("Clicked ^[\(counter) times](inflect: true)").padding()
            HStack
            {
                Button("minus") {
                    print("clicked -1")
                    counter -= 1
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
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


