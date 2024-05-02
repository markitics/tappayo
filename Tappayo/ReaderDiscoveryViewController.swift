import UIKit
import StripeTerminal

class ReaderDiscoveryViewController: UIViewController, DiscoveryDelegate, LocalMobileReaderDelegate {

    var discoverCancelable: Cancelable?

    // Action for a "Discover Readers" button
    func discoverReadersAction() throws {
        let config = try LocalMobileDiscoveryConfigurationBuilder().build()
        self.discoverCancelable = Terminal.shared.discoverReaders(config, delegate: self) { error in
            if let error = error {
                print("discoverReaders failed: \(error)")
            } else {
                print("discoverReaders succeeded")
            }
        }
    }

    func connectReader(reader: Reader) {
        do {
            let connectionConfig = try LocalMobileConnectionConfigurationBuilder.init(locationId: "tml_FiL1wsrslNB1EQ").build()
            Terminal.shared.connectLocalMobileReader(reader, delegate: self, connectionConfig: connectionConfig) { reader, error in
                if let reader = reader {
                    print("Successfully connected to reader: \(reader)")
                } else if let error = error {
                    print("connectLocalMobileReader failed: \(error)")
                }
            }
        } catch {
            print("Failed to create connection configuration: \(error)")
        }
    }

    // MARK: DiscoveryDelegate
    func terminal(_ terminal: Terminal, didUpdateDiscoveredReaders readers: [Reader]) {
        if let firstReader = readers.first {
            connectReader(reader: firstReader)
        }
    }

    // MARK: LocalMobileReaderDelegate
    func localMobileReader(_ reader: Reader, didStartInstallingUpdate update: ReaderSoftwareUpdate, cancelable: Cancelable?) {
        // Notify user update is starting
        print("Update starting on reader: \(update.description)")
    }

    func localMobileReader(_ reader: Reader, didReportReaderSoftwareUpdateProgress progress: Float) {
        // Update UI with progress
        print("Update progress: \(progress * 100)%")
    }

    func localMobileReader(_ reader: Reader, didFinishInstallingUpdate update: ReaderSoftwareUpdate?, error: Error?) {
        if let update = update {
            print("Update finished: \(update.description)")
        } else if let error = error {
            print("Update failed: \(error.localizedDescription)")
        }
    }

    func localMobileReader(_ reader: Reader, didRequestReaderDisplayMessage displayMessage: ReaderDisplayMessage) {
        // Display reader message
        print("Display message: \(displayMessage)")
    }

    func localMobileReader(_ reader: Reader, didRequestReaderInput inputOptions: ReaderInputOptions) {
        // Handle reader input request
        print("Input requested: \(inputOptions)")
    }
}
