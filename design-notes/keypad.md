



Custom Keypad Implementation Plan

 1. Create Custom Keypad Component (New File: CustomKeypadView.swift)

 - Build reusable SwiftUI view with circular buttons (GoDaddy style)
 - 3-column grid: Rows for 1-9, then bottom row with conditional buttons
 - When amount = 0: Only show digits (1-9, 0 centered)
 - When amount > 0: Show "Add to Cart" (bottom-left), 0 (center), backspace (bottom-right)
 - Add to Cart button disabled when amount is 0

 2. Modify ContentView.swift

 - Add @State private var isKeypadActive: Bool = false
 - Add @State private var dismissKeypadAfterAdd: Bool =
 UserDefaults.standard.dismissKeypadAfterAdd
 - When user taps input field: set isKeypadActive = true, disable system keyboard
 - Show overlay (dimmed background) when keypad active, containing:
   - Amount input at top
   - +$1/-$1 buttons (if showPlusMinusButtons setting is true)
   - Custom keypad grid
   - Add to Cart + Cancel buttons below keypad
 - Handle button actions:
   - Digits: build up amountInCents
   - Backspace: remove last digit (divide by 10)
   - Add to Cart: add item, conditionally dismiss based on setting
   - Cancel: clear amount AND dismiss keypad

 3. Add New Setting (Modify SettingsView.swift + UserDefaultsExtension.swift)

 - New toggle: "Keep keypad open after adding to cart"
 - Store in UserDefaults as dismissKeypadAfterAdd
 - Default value: true (dismiss after add for now)

 4. Disable System Keyboard

 - Prevent iOS keyboard from appearing when input is tapped
 - Use custom gesture recognizer or modify CurrencyTextField to not invoke keyboard

 5. Visual Design

 - Overlay: semi-transparent dark background (.black.opacity(0.4))
 - Circular buttons: ~70pt diameter, dark background, white text
 - Match existing app styling (accent colors, corner radius)
 - Smooth show/hide animations

 This solves the layout shift issue and creates a clean, dedicated input experience like GoDaddy.
