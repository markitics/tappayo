// TerminalConnectionView.swift
//import Foundation
import SwiftUI

struct TerminalConnectionView: View {
//    var body: some View {
//        Text("Terminal Connection Interface")
//    }
    
    @Binding var connectionStatus: String
        
    var body: some View {
        Text(connectionStatus)
            .padding()
            .multilineTextAlignment(.center)
    }
    
}
