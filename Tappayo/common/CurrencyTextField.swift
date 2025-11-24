//  CurrencyTextField.swift
//  Tappayo
//  Created by M@rkMoriarty.com on 6/4/24.

import SwiftUI

struct CurrencyTextField: UIViewRepresentable {
    @Binding var value: Int
    let placeholder: String
    let font: Font

    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: CurrencyTextField

        init(parent: CurrencyTextField) {
            self.parent = parent
        }

        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            let text = (textField.text ?? "") as NSString
            let newText = text.replacingCharacters(in: range, with: string)

            // Remove non-numeric characters and convert to cents
            let filtered = newText.filter { "0123456789".contains($0) }
            if let cents = Int(filtered) {
                parent.value = cents
            }

            // Update the text field with formatted value
            textField.text = parent.format(cents: parent.value)
            return false
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.placeholder = placeholder
        textField.keyboardType = .decimalPad
        textField.delegate = context.coordinator
        textField.textAlignment = .center // Center align text

        // Convert SwiftUI Font to UIFont and apply
        let uiFont = UIFont.preferredFont(from: font)
        textField.font = uiFont

        // Add a toolbar with a done button
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: textField, action: #selector(UITextField.resignFirstResponder))
        toolbar.setItems([doneButton], animated: false)
        textField.inputAccessoryView = toolbar

        return textField
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        uiView.text = format(cents: value)
        uiView.font = UIFont.preferredFont(from: font)
        uiView.textAlignment = .center // Ensure text remains centered on update
    }

    private func format(cents: Int) -> String? {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
//        formatter.currencyCode = "USD"
        formatter.currencySymbol = "$" // Remove "US"
        return formatter.string(from: NSNumber(value: Double(cents) / 100))
    }
}

extension UIFont {
    static func preferredFont(from font: Font) -> UIFont {
        switch font {
        case .largeTitle:
            return UIFont.preferredFont(forTextStyle: .largeTitle)
        case .title:
            return UIFont.preferredFont(forTextStyle: .title1)
        case .title2:
            return UIFont.preferredFont(forTextStyle: .title2)
        case .title3:
            return UIFont.preferredFont(forTextStyle: .title3)
        case .headline:
            return UIFont.preferredFont(forTextStyle: .headline)
        case .subheadline:
            return UIFont.preferredFont(forTextStyle: .subheadline)
        case .body:
            return UIFont.preferredFont(forTextStyle: .body)
        case .callout:
            return UIFont.preferredFont(forTextStyle: .callout)
        case .footnote:
            return UIFont.preferredFont(forTextStyle: .footnote)
        case .caption:
            return UIFont.preferredFont(forTextStyle: .caption1)
        case .caption2:
            return UIFont.preferredFont(forTextStyle: .caption2)
        default:
            return UIFont.preferredFont(forTextStyle: .body)
        }
    }
}
