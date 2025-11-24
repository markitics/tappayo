//  PercentageTextField.swift
//  Tappayo
//  Created by M@rkMoriarty.com

import SwiftUI

struct PercentageTextField: UIViewRepresentable {
    @Binding var value: Int  // Stored as basis points (1000 = 10.00%)
    let placeholder: String
    let font: Font

    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: PercentageTextField

        init(parent: PercentageTextField) {
            self.parent = parent
        }

        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            let text = (textField.text ?? "") as NSString
            let newText = text.replacingCharacters(in: range, with: string)

            // Remove non-numeric characters and convert to basis points
            let filtered = newText.filter { "0123456789".contains($0) }
            if let basisPoints = Int(filtered) {
                // Cap at 50000 basis points (500.00%)
                parent.value = min(basisPoints, 50000)
            }

            // Update the text field with formatted value
            textField.text = parent.format(basisPoints: parent.value)
            return false
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.placeholder = placeholder
        textField.keyboardType = .numberPad
        textField.delegate = context.coordinator
        textField.textAlignment = .left

        // No border - let parent view handle styling
        textField.borderStyle = .none

        // Convert SwiftUI Font to UIFont and apply
        let uiFont = UIFont.preferredFont(from: font)
        textField.font = uiFont

        // Add a toolbar with a done button
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let doneButton = UIBarButtonItem(barButtonSystemItem: .save, target: textField, action: #selector(UITextField.resignFirstResponder))
        toolbar.setItems([doneButton], animated: false)
        textField.inputAccessoryView = toolbar

        return textField
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        uiView.text = format(basisPoints: value)
        uiView.font = UIFont.preferredFont(from: font)
        uiView.textAlignment = .left
    }

    private func format(basisPoints: Int) -> String? {
        let percentage = Double(basisPoints) / 100.0
        return String(format: "%.2f", percentage)
    }
}
