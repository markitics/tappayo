////
////  APPReaderViewController.swift
////  Tappayo
////
////  Created by M@rkMoriarty.com on 5/1/24.
////
//
//import Foundation
//import StripeTerminal
//import UIKit
//
//class APPReaderViewController: LocalMobileReaderDelegate {
//
//    // MARK: LocalMobileReaderDelegate
//
//    // ...
//
//    func localMobileReader(_ reader: Reader, didStartInstallingUpdate update: ReaderSoftwareUpdate, cancelable: Cancelable?) {
//        // In your app, let the user know that an update is being installed on the reader
//    }
//
//    func localMobileReader(_ reader: Reader, didReportReaderSoftwareUpdateProgress progress: Float) {
//        // The update or configuration process has reached the specified progress (0.0 to 1.0)
//        // If you are displaying a progress bar or percentage, this can be updated here
//    }
//
//    func localMobileReader(_ reader: Reader, didFinishInstallingUpdate update: ReaderSoftwareUpdate?, error: Error?) {
//        // The reader has finished installing an update
//        // If `error` is nil, it is safe to proceed and start collecting payments
//        // Otherwise, check the value of `error` for more information on what went wrong
//    }
//
//    func localMobileReader(_ reader: Reader, didRequestReaderDisplayMesage displayMessage: ReaderDisplayMessage) {
//        // This is called to request that a prompt be displayed in your app.
//        // Use Terminal.stringFromReaderDisplayMessage(:) to get a user-facing string for the prompt
//    }
//
//    func localMobilereader(_ reader: Reader, didRequestReaderInput inputOptions: ReaderInputOptions = []) {
//        // This is called when the reader begins waiting for input
//        // Use Terminal.stringFromReaderInputOptions(:) to get a user-facing string for the input options
//    }
//
//    // ...
//}
