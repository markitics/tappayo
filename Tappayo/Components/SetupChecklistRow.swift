//  SetupChecklistRow.swift
//  Tappayo

import SwiftUI

struct SetupChecklistRow: View {
    let title: String
    var subtitle: String? = nil
    let isComplete: Bool
    var statusText: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        Button(action: { action?() }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .foregroundColor(.primary)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                if let statusText = statusText {
                    Text(statusText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Image(systemName: isComplete ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isComplete ? .green : .secondary)
            }
            .contentShape(Rectangle()) // Makes entire row tappable
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    Form {
        Section(header: Text("Example")) {
            SetupChecklistRow(
                title: "Sign in with Apple",
                subtitle: "Create your Tappayo account",
                isComplete: false
            )

            SetupChecklistRow(
                title: "Bluetooth",
                isComplete: true,
                statusText: "Granted"
            )

            SetupChecklistRow(
                title: "Location",
                isComplete: false,
                statusText: "Not Set"
            )
        }
    }
}
