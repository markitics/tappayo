//
//  ReaderDiscoveryViewController.swift
//  Tappayo
//
//  Created by M@rkMoriarty.com on 5/1/24.
//

import Foundation
import StripeTerminal

class ReaderDiscoveryViewController: UIViewController, DiscoveryDelegate {

    var discoverCancelable: Cancelable?

    // ...

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

    // ...

    // MARK: DiscoveryDelegate

    func terminal(_ terminal: Terminal, didUpdateDiscoveredReaders readers: [Reader]) {
        // In your app, display the ability to use your phone as a reader
        // Call `connectLocalMobileReader` to initiate a session with the phone
    }
}
