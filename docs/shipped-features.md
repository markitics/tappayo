# Shipped Features

Documentation for features that are live in the app.

---

## Currency Formatting (Nov 2025)

### Overview

The app uses a unified currency formatting approach with "smart decimal" logic for clean, readable prices.

### Smart Decimal Logic

**Design Goal:** Prices display in the cleanest, most natural format.

- Whole dollar amounts display clean: `$5`, `$20`, `$1,234`
- Amounts with cents show decimals: `$5.50`, `$1,234.56`
- Comma separators for readability on large amounts

### The "Farmers Market Scenario"

**All whole dollars (common at farmers markets):**
```
Grip    $3   x2    $6
Coffee             $5
Bag                $1
---------------------
Subtotal          $12
```

**Mixed pricing (consistency trumps brevity):**
```
Grip    $3.00 x2   $6.00
Coffee             $5.50  <- This item has cents
Bag                $1.00
-------------------------
Subtotal          $11.50
```

**Large amounts (commas for readability):**
```
Equipment  $1,234 x2  $2,468
Services              $3,500
-----------------------------
Total              $5,968
```

### Core Implementation (ContentView.swift)

```swift
private func formatCurrency(_ cents: Int, forceDecimals: Bool = false) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.currencySymbol = "$"
    formatter.usesGroupingSeparator = true  // <- Key addition for commas

    // Smart decimal logic: show .00 only when needed
    let shouldShowDecimals = forceDecimals || (cents % 100 != 0)
    formatter.minimumFractionDigits = shouldShowDecimals ? 2 : 0
    formatter.maximumFractionDigits = shouldShowDecimals ? 2 : 0

    return formatter.string(from: NSNumber(value: Double(cents) / 100)) ?? "$0.00"
}
```

### Context-Aware Consistency

Within a single view, all prices align for readability:
- Cart uses `cartHasAnyCents` check to force decimals if ANY item has cents
- Tax summary uses `taxSummaryHasCents` for subtotal/tax alignment
- Ensures visual consistency within a single transaction

### History

The app originally had **8 different currency formatting implementations** scattered across the codebase, causing inconsistent comma usage and duplication. Consolidated in Nov 2025 to this single approach.

---

## Cart Features

- **Add items**: Via keypad or quick-amount buttons
- **Swipe-to-delete**: Remove items from cart
- **Quantity display**: Shows "x2" etc. for duplicate items
- **Auto-dismiss keypad**: Tap outside to close numeric input
- **Auto-focus**: Quick amount input gets focus when adding new amounts

---

## Settings/Customization

- **Business name**: Displayed in navigation bar
- **Quick-amount buttons**: Customizable common prices
- **Light/Dark mode**: System or manual override
- **Accent color**: Customizable app tint
- **Product management**: Save products with emoji/photo icons

---

## Payment Flow

1. Add items to cart
2. Tap checkout button
3. Review order in checkout sheet
4. Optional: Add email for receipt
5. Tap Pay button
6. Tap to Pay interface appears (Apple's standard UI)
7. Customer taps card
8. Payment confirmed
