//
//  ContentView.swift
//  Tappayo
//
//  Created by M@rkMoriarty.com on 4/16/24.
//

import SwiftUI

struct ContentView: View {
    @State var counter = 1
    
    var body: some View {
        VStack {
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
                    print("clicked")
                    counter -= 1
                }
                Button("plus") {
                    print("clicked")
                    counter += 1
                }
            }
            
            Spacer()
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
