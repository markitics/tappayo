//
//  APIClient.swift
// per https://docs.stripe.com/terminal/payments/setup-integration?terminal-sdk-platform=ios&terminal-ios-sdk-installation-method=swift-package-manager&lang=python#connection-token-client-side
//  Tappayo
//

import Foundation

import StripeTerminal

// Example API client class for communicating with your backend
class APIClient: ConnectionTokenProvider {

    // For simplicity, this example class is a singleton
    static let shared = APIClient()

    // Fetches a ConnectionToken from your backend
    func fetchConnectionToken(_ completion: @escaping ConnectionTokenCompletionBlock) {
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        guard let url = URL(string: "https://awesound.com/api/next/ttp/get-connection-token") else {
            fatalError("Invalid backend URL")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let task = session.dataTask(with: request) { (data, response, error) in
            if let data = data {
                do {
                    // Warning: casting using `as? [String: String]` looks simpler, but isn't safe:
                    let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                    if let secret = json?["secret"] as? String {
                        completion(secret, nil)
                    }
                    else {
                        let error = NSError(domain: "com.markmoriarty.ios.tappayo",
                                            code: 2000,
                                            userInfo: [NSLocalizedDescriptionKey: "Missing `secret` in ConnectionToken JSON response"])
                        completion(nil, error)
                    }
                }
                catch {
                    completion(nil, error)
                }
            }
            else {
                let error = NSError(domain: "com.markmoriarty.ios.tappayo",
                                    code: 1000,
                                    userInfo: [NSLocalizedDescriptionKey: "No data in response from ConnectionToken endpoint"])
                completion(nil, error)
            }
        }
        task.resume()
    }
}
