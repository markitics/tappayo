import UIKit
import StripeTerminal

class ReaderDiscoveryViewController: UIViewController, DiscoveryDelegate, LocalMobileReaderDelegate {

    var discoverCancelable: Cancelable?
    var updateConnectionStatus: ((String) -> Void)?
    var isConnected = false
    var isDiscovering = false

    override func viewDidLoad() {
        super.viewDidLoad()
        discoverAndConnectReader()
    }
    
    func discoverAndConnectReader() {
        guard !isDiscovering else { return } // Prevent multiple discoveries
        guard !isConnected else {
            // Skip discovery if already connected (e.g., we click into Settings page, and then come back to main ConentView, triggering viewDidLoad again, but we've remained Connected the whole time
            self.updateConnectionStatus?("Ready for Tap to Pay on iPhone")
            return
        }
        isDiscovering = true
        let config = try! LocalMobileDiscoveryConfigurationBuilder().build()
        updateConnectionStatus?("Discovering readers...")
        self.discoverCancelable = Terminal.shared.discoverReaders(config, delegate: self) { error in
            self.isDiscovering = false
            if let error = error {
                print("discoverReaders failed: \(error)")
                self.updateConnectionStatus?("Discover readers failed: \(error.localizedDescription)")
            } else {
                print("discoverReaders succeeded")
                self.updateConnectionStatus?("Discover readers succeeded")
            }
        }
    }
    
    func connectToReader(reader: Reader) {
        do {
            let connectionConfig = try LocalMobileConnectionConfigurationBuilder(locationId: "tml_FhUnQwoWdFn95V")
                .setAutoReconnectOnUnexpectedDisconnect(true)
                .build()
            updateConnectionStatus?("Connecting to reader...")
            Terminal.shared.connectLocalMobileReader(reader, delegate: self, connectionConfig: connectionConfig) { reader, error in
                if let reader = reader {
                    print("Successfully connected to reader: \(reader)")
                    self.isConnected = true
                    self.updateConnectionStatus?("Ready for Tap to Pay on iPhone")
                    
                } else if let error = error {
                    print("connectLocalMobileReader failed: \(error)")
                    self.updateConnectionStatus?("Connect reader failed: \(error.localizedDescription)")
                }
            }
        } catch {
            print("Failed to create connection configuration: \(error)")
            updateConnectionStatus?("Failed to create connection configuration: \(error.localizedDescription)")
        }
    }

    func checkoutAction(amount: Int) throws {
        guard !isDiscovering else {
            updateConnectionStatus?("Discovering readers, please wait...")
            return
        }

        guard isConnected else {
            updateConnectionStatus?("Not connected to a reader. Connecting now...")
            discoverAndConnectReader()
            return
        }

        let params = try PaymentIntentParametersBuilder(amount: UInt(amount), currency: "usd") // amount is amount in cents, not dollars
            .setCaptureMethod(.automatic)
            .build()

        Terminal.shared.createPaymentIntent(params) { createResult, createError in
            if let error = createError {
                print("createPaymentIntent failed: \(error)")
                self.updateConnectionStatus?("Create payment intent failed: \(error.localizedDescription)")
            } else if let paymentIntent = createResult {
                print("createPaymentIntent succeeded")
                self.updateConnectionStatus?("Success: Created payment intent with Stripe…")

                _ = Terminal.shared.collectPaymentMethod(paymentIntent) { collectResult, collectError in
                    if let error = collectError as NSError?, (error.code == 1 || error.code == 2020) {
                        print("collectPaymentMethod was canceled: \(error)")
                        self.updateConnectionStatus?("Ready")
                    } else if let error = collectError {
                        print("collectPaymentMethod failed: \(error)")
                        self.updateConnectionStatus?("Collect payment method failed: \(error.localizedDescription)")
                    }  else if let paymentIntent = collectResult {
                        print("collectPaymentMethod succeeded")
                        self.updateConnectionStatus?("Collect payment method succeeded")
                        // ... Confirm the payment
                        // https://docs.stripe.com/terminal/payments/collect-card-payment?terminal-sdk-platform=ios#confirm-payment
                        Terminal.shared.confirmPaymentIntent(paymentIntent) { confirmResult, confirmError in
                            if let error = confirmError {
                                print("confirmPaymentIntent failed: \(error)")
                                self.updateConnectionStatus?("Confirm payment intent failed: \(error.localizedDescription)")
                            } else if confirmResult != nil {
                                print("confirmPaymentIntent succeeded")
                                self.updateConnectionStatus?("Confirm payment intent succeeded")
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: DiscoveryDelegate
    func terminal(_ terminal: Terminal, didUpdateDiscoveredReaders readers: [Reader]) {
        if let firstReader = readers.first {
            print("didUpdateDiscoveredReaders / connectReader")
            connectToReader(reader: firstReader)
        }
    }

    // MARK: LocalMobileReaderDelegate
    func localMobileReader(_ reader: Reader, didStartInstallingUpdate update: ReaderSoftwareUpdate, cancelable: Cancelable?) {
        print("Update starting on reader: \(update.description)")
        updateConnectionStatus?("Update starting on reader")
    }

    func localMobileReader(_ reader: Reader, didReportReaderSoftwareUpdateProgress progress: Float) {
        print("Update progress: \(progress * 100)%")
        updateConnectionStatus?("Update progress: \(Int(progress * 100))%")
    }

    func localMobileReader(_ reader: Reader, didFinishInstallingUpdate update: ReaderSoftwareUpdate?, error: Error?) {
        if let update = update {
            print("Update finished: \(update.description)")
            updateConnectionStatus?("Update finished: \(update.description)")
        } else if let error = error {
            print("Update failed: \(error.localizedDescription)")
            updateConnectionStatus?("Update failed: \(error.localizedDescription)")
        }
    }

    func localMobileReader(_ reader: Reader, didRequestReaderDisplayMessage displayMessage: ReaderDisplayMessage) {
        print("Display message: \(displayMessage)")
    }

    func localMobileReader(_ reader: Reader, didRequestReaderInput inputOptions: ReaderInputOptions) {
        print("Input requested: \(inputOptions)")
    }
}
