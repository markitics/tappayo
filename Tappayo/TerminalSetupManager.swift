//import Foundation
//import StripeTerminal
//
//class TerminalSetupManager: NSObject, ObservableObject, LocalMobileReaderDelegate {
//    @Published var isReady = false
//    @Published var errorMessage: String?
//
//    override init() {
//        super.init()
//        initializeStripeTerminal()
//    }
//
//    private func initializeStripeTerminal() {
//        Terminal.setTokenProvider(APIClient.shared)
//    }
//
//    func connectToLocalMobileReader() {
//        let locationId = "tml_FiL1wsrslNB1EQ"  // Your actual Location ID
//        do {
//            let config = try LocalMobileConnectionConfigurationBuilder(locationId: locationId).build()
//            Terminal.shared.discoverReaders(config, delegate: self) { error in
//                DispatchQueue.main.async {
//                    if let error = error {
//                        self.errorMessage = error.localizedDescription
//                        print("Failed to connect: \(error)")
//                    } else {
//                        self.isReady = true
//                        print("Connected to reader")
//                    }
//                }
//            }
//        } catch {
//            self.errorMessage = "Configuration failed with error: \(error)"
//            print(self.errorMessage ?? "Unknown error")
//        }
//    }
//
//    // MARK: LocalMobileReaderDelegate Methods
//    func terminal(_ terminal: Terminal, didChangeConnectionStatus status: ConnectionStatus) {
//        print("Connection status changed: \(status)")
//    }
//
//    func terminal(_ terminal: Terminal, didReportUnexpectedReaderDisconnect reader: Reader) {
//        print("Reader disconnected unexpectedly.")
//    }
//
//    func terminal(_ terminal: Terminal, didReportReaderEvent event: ReaderEvent, info: [AnyHashable : Any]?) {
//        print("Reader event reported: \(event)")
//    }
//}
