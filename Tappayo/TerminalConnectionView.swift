//// TerminalConnectionView.swift
//import SwiftUI
//
//struct TerminalConnectionView: View {
//    @ObservedObject var setupManager = TerminalSetupManager()
//
//    var body: some View {
//        VStack {
//            if setupManager.isReady {
//                Text("Reader is ready for transactions.")
//            } else {
//                Text("Reader not connected.")
//                if let errorMessage = setupManager.errorMessage {
//                    Text("Error: \(errorMessage)").foregroundColor(.red)
//                }
//                Button("Connect Reader") {
//                    setupManager.connectToLocalMobileReader()
//                }
//            }
//        }
//        .onAppear {
//            setupManager.connectToLocalMobileReader() // Attempt to connect automatically when the view appears
//        }
//    }
//}
