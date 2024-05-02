//// from https://docs.stripe.com/terminal/payments/connect-reader?terminal-sdk-platform=ios&reader-type=tap-to-pay&lang=python#connect-reader
//
//import StripeTerminal
//// Call `connectLocalMobileReader` with the selected reader and a connection config
//// to register to a location as set by your app.
////let connectionConfig = try LocalMobileConnectionConfigurationBuilder.init(locationId: "{{LOCATION_ID}}").build()
////Terminal.shared.connectLocalMobileReader(selectedReader, delegate: localMobileReaderDelegate, connectionConfig: connectionConfig) { reader, error in
////    if let reader = reader {
////        print("Successfully connected to reader: \(reader)")
////    } else if let error = error {
////        print("connectLocalMobileReader failed: \(error)")
////    }
////}
