import UIKit
import StripeTerminal

class ReaderDiscoveryViewController: UIViewController, DiscoveryDelegate, LocalMobileReaderDelegate {

    var discoverCancelable: Cancelable?
    var updateConnectionStatus: ((String) -> Void)?


    // Action for a "Discover Readers" button
    func discoverReadersAction() throws {
        let config = try LocalMobileDiscoveryConfigurationBuilder().build()
        print("In discoverReadersAction()")
        updateConnectionStatus?("Discovering readers...")
        self.discoverCancelable = Terminal.shared.discoverReaders(config, delegate: self) { error in
            if let error = error {
                print("discoverReaders failed: \(error)")
                self.updateConnectionStatus?("Discover readers failed: \(error.localizedDescription)")
            } else {
                print("discoverReaders succeeded")
                self.updateConnectionStatus?("Discover readers succeeded")
            }
        }
    }

    func connectReader(reader: Reader) {
//        where the heck did I get tml_FiL1wsrslNB1EQ? chatgpt?
        do {
            let connectionConfig = try LocalMobileConnectionConfigurationBuilder.init(locationId: "tml_FhUnQwoWdFn95V").build()
            updateConnectionStatus?("Connecting to onboard reader...")
            Terminal.shared.connectLocalMobileReader(reader, delegate: self, connectionConfig: connectionConfig) { reader, error in
                if let reader = reader {
                    print("Successfully connected to reader: \(reader)")
                    self.updateConnectionStatus?("Successfully connected to reader, yep")
                    do {
                        try self.checkoutAction()
                    } catch {
                        print("Checkout failed")
                        self.updateConnectionStatus?("Checkout failed, alas")
                    }
                } else if  let error = error {
                    print("connectLocalMobileReader failed: \(error)")
                    self.updateConnectionStatus?("Connect reader failed with error: \(error.localizedDescription)")
                }
            }
        } catch {
            print("Failed to create connection configuration: \(error)")
            updateConnectionStatus?("Bah! Failed to create connection configuration: \(error.localizedDescription)")
        }
    }
    
    // Action for a "Checkout" button
        func checkoutAction() throws {
            let params = try PaymentIntentParametersBuilder(amount: 103, currency: "usd")
                .setCaptureMethod(.automatic)
                .build()
            
            Terminal.shared.createPaymentIntent(params) { createResult, createError in
                if let error = createError {
                    print("createPaymentIntent failed: \(error)")
                    self.updateConnectionStatus?("Create payment intent failed: \(error.localizedDescription)")
                }
                else if let paymentIntent = createResult {
                    print("createPaymentIntent succeeded")
                    self.updateConnectionStatus?("Create payment intent succeeded")
                    let collectCancelable = Terminal.shared.collectPaymentMethod(paymentIntent) { collectResult, collectError in
                        if let error = collectError {
                            print("collectPaymentMethod failed: \(error)")
                            self.updateConnectionStatus?("Collect payment method failed: \(error.localizedDescription)")
                        }
                        else if let paymentIntent = collectResult {
                            print("collectPaymentMethod succeeded")
                            self.updateConnectionStatus?("Collect payment method succeeded")
                            // ... Confirm the payment
                            // https://docs.stripe.com/terminal/payments/collect-card-payment?terminal-sdk-platform=ios#confirm-payment
                            
                            Terminal.shared.confirmPaymentIntent(paymentIntent) { confirmResult, confirmError in
                                      if let error = confirmError {
                                          print("confirmPaymentIntent failed: \(error)")
                                          self.updateConnectionStatus?("Confirm payment intent failed: \(error.localizedDescription)")
                                      } else if let confirmedPaymentIntent = confirmResult {
                                          print("confirmPaymentIntent succeeded")
                                          self.updateConnectionStatus?("Confirm payment intent succeeded")
                                          // Notify your backend to capture the PaymentIntent
//                                          if let stripeId = confirmedPaymentIntent.stripeId {
//                                              APIClient.shared.capturePaymentIntent(stripeId) { captureError in
//                                                  if let error = captureError {
//                                                      print("capture failed: \(error)")
//                                                  } else {
//                                                      print("capture succeeded")
//                                                  }
//                                              }
//                                          } else {
//                                              print("Payment collected offline");
//                                          }
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
