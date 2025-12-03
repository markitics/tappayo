## Conditional UI in Checkout Sheet (Nov 2025)

**Context:** The checkout sheet adapts its UI based on cart size and tax settings to avoid showing redundant information.

### The Logic (CheckoutSheet.swift lines 132-174)

The checkout sheet conditionally shows/hides Subtotal, Tax, and Total lines based on cart state:

**Scenario 1: Single item, no tax**
```
Beer (happy hour)    $6.00

[Pay button]
```
- **No** Subtotal line (redundant - item price = subtotal)
- **No** Tax line (tax is zero)
- **No** Total line (redundant - item price = total)

**Scenario 2: Single item, with tax**
```
Beer (happy hour)    $6.00

Tax                     $0.60
Total                   $6.60

[Pay button]
```
- **No** Subtotal line (still redundant - only one item)
- **Yes** Tax line (breakdown needed)
- **Yes** Total line (needed to show item + tax)

**Scenario 3: Multiple items, no tax**
```
Beer (happy hour)    $6.00
Magic                $6.66

Subtotal               $12.66
Total                  $12.66

[Pay button]
```
- **Yes** Subtotal line (sum of multiple items)
- **No** Tax line (tax is zero)
- **Yes** Total line (even though same as subtotal, shown for consistency)

**Scenario 4: Multiple items, with tax**
```
Beer (happy hour)    $6.00
Magic                $6.66

Subtotal               $12.66
Tax                     $1.27
Total                  $13.93

[Pay button]
```
- **Yes** Subtotal line
- **Yes** Tax line
- **Yes** Total line (subtotal + tax)

### Implementation

**Subtotal conditional** (line 141):
```swift
if basket.count != 1 {
    // Show subtotal only when multiple items
}
```

**Tax conditional** (line 151):
```swift
if taxAmountInCents > 0 {
    // Show tax only when non-zero
}
```

**Total conditional** (line 162):
```swift
if basket.count != 1 || taxAmountInCents > 0 {
    // Show total only when:
    // - Multiple items, OR
    // - Tax exists (even if single item)
}
```

### Design Rationale

- **Minimize visual clutter**: Don't show lines that duplicate information already visible
- **Context-aware**: Show breakdown only when it adds value
- **Progressive disclosure**: Simple purchases stay simple, complex ones get detail

**Lessons Learned:**
- Smart conditionals improve UX by reducing cognitive load
- Consider all combinations when designing adaptive UI
- Document the logic clearly - it's not obvious without context

---


