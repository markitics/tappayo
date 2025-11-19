# Tappayo

A simple, elegant iOS app for in-person payment processing using **Tap to Pay on iPhone**.

## About

Tappayo is a learning project exploring iOS development and Stripe's Tap to Pay SDK. It provides a streamlined interface for accepting contactless payments directly on your iPhone—no additional hardware required.

## Features

- **Quick Product Buttons**: Add your commonly-sold items with custom names, prices, and emojis
- **Manual Price Entry**: Flexible keypad for one-off amounts
- **Smart Shopping Cart**: Add multiple items, adjust quantities, edit names
- **Clean Price Display**: Automatically shows prices in the cleanest format
  - Whole dollar amounts: `$5`, `$20`, `$100`
  - Amounts with cents: `$5.50`, `$20.99`
  - Large amounts with commas: `$1,234.56`
- **Tax Calculation**: Configurable tax rate with automatic calculations
- **Tap to Pay**: Accept contactless payments using iPhone's built-in NFC
- **Customization**: Dark mode support and accent color personalization

## Smart Price Formatting

Tappayo automatically displays prices in the cleanest, most readable format:

### Farmers Market Scenario
When all items have round dollar amounts, receipts stay clean:
```
Grip    $3   ×2    $6
Coffee             $5
Bag                $1
─────────────────────
Subtotal          $12
```

### Mixed Pricing
When any item has cents, everything aligns with consistent decimals:
```
Grip    $3.00 ×2   $6.00
Coffee             $5.50
─────────────────────
Subtotal          $11.50
```

### Large Amounts
Comma separators automatically appear for readability:
```
Equipment  $1,234 ×2  $2,468
Services              $3,500
─────────────────────────────
Total              $5,968
```

This ensures your receipts are always professional and easy to read, whether you're selling coffee for $5 or equipment for $5,000.

## Requirements

- iPhone XS or newer running iOS 15.4+
- Stripe Terminal account with Tap to Pay enabled
- Physical presence in a supported region (US, UK, Australia, etc.)

## Setup

1. Clone this repository
2. Open `Tappayo.xcodeproj` in Xcode
3. Update the Stripe location ID in `ReaderDiscoveryViewController.swift`
4. Build and run on a compatible device (Tap to Pay requires physical iPhone)

## Usage

1. **Add Products**: Go to Settings to create quick-access product buttons
2. **Build Cart**: Tap products or use the keypad to add items
3. **Review Order**: Press "Review" to see the payment sheet
4. **Charge**: Tap "Charge card" and present iPhone to customer's contactless card

## Tech Stack

- **SwiftUI** for modern, declarative UI
- **UIKit** for specialized components
- **Stripe Terminal SDK** for payment processing
- **UserDefaults** for local data persistence

## Development

This is a personal learning project. The code includes:
- Clean architecture patterns
- Smart number formatting with locale support
- Thoughtful UX details (auto-dismissing keyboards, smart decimal handling, etc.)

See `claude.md` for detailed development notes and technical documentation.

## License

Personal learning project. Not intended for production use.

## Author

Mark Moriarty - Learning iOS development and payment processing through hands-on building.
