# Design Notes

Visual/UI patterns, UI quirks, and "make it prettier" notes. These are about appearance and feel, not functionality.

---

## Known UI Quirks

### Scroll Indicator Flash Not Visible

**Context**: Added `.scrollIndicatorsFlash(onAppear: true)` to CartListView (via FlashScrollIndicatorsModifier) to help users discover scrollable content when the cart has many items.

**Issue**: The flash is not visible on Mark's device (iPhone 17 Pro Max, iOS 26.1), despite being officially supported on iOS 17+.

**Current Status**: Code remains in place as it may work for other users or future iOS versions. The gradient fade overlay at the bottom of the list (80pt height) serves as the primary visual indicator that more content is available, and this is working correctly.

**File**: `CartListView.swift:149` and `FlashScrollIndicatorsModifier` (lines 172-181)

---

## Navigation Title vs Toolbar Items (Nov 2025)

### Problem: Business Name Truncation
The business name was displaying as "M..." despite having plenty of available space.

**Attempted Solutions:**
1. **ToolbarItem(placement: .navigationBarLeading)** - iOS aggressively truncates toolbar items
2. **navigationTitle() with large title mode** - Wasted significant vertical space

### Solution: Inline Navigation Title
```swift
.navigationTitle(businessName)
.navigationBarTitleDisplayMode(.inline)
```

**iOS Behavior Discovery:**
iOS automatically adjusts navigation title alignment based on length:
- **Short titles** (e.g., "Mark's treats"): Center-aligned
- **Long titles** (e.g., "Mark's treats and other tasty goodies"): Left-aligned

This adaptive behavior is perfect - it provides:
- Clean centered look for short names
- Maximum space utilization for long names
- No manual truncation or overflow handling needed

**Lessons Learned:**
- Prefer Apple's standard components (`.navigationTitle()`) over custom toolbar items when possible
- `.navigationBarTitleDisplayMode(.inline)` gives compact nav bar without wasted space
- iOS handles edge cases (long titles, Dynamic Island, safe areas) automatically
- Navigation titles get more space allocation than toolbar items

---

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

## Progressive Disclosure for Optional Email Field (Nov 2025)

### Problem: "Ugly" Always-Visible Email Input
The checkout sheet had an always-visible email TextField that looked awkward and cluttered the payment flow.

**Before (Always Visible):**
```
Subtotal                   $12.66

Email for receipt (optional)
[customer@example.com      ]  <- Blue placeholder text, takes up space

[Pay $12.66 button]
```

**Issues:**
- Blue placeholder text on dark backgrounds (poor contrast/aesthetics)
- Visual clutter on an already busy checkout screen
- Field takes up space even though most users don't need receipts
- Violates Apple Pay guidelines (optional fields shouldn't clutter payment sheets)
- Higher cognitive load = lower conversion rates

### Solution: Progressive Disclosure Pattern

**After (Progressive Disclosure):**
```
Subtotal                   $12.66

[envelope icon] Email me a receipt      <- Simple button

[Pay $12.66 button]
```

**When tapped:**
```
Email for receipt         Remove
[your@email.com           ]  <- Auto-focused, proper styling

[Pay $12.66 button]
```

### Implementation (CheckoutSheet.swift)

**Added state** (line 21):
```swift
@State private var showEmailField = false
```

**Progressive disclosure logic** (lines 191-237):
```swift
if !showEmailField && receiptEmail.isEmpty {
    // Button to reveal field
    Button(action: {
        showEmailField = true
        isEmailFieldFocused = true  // Auto-focus
    }) {
        HStack {
            Image(systemName: "envelope")
            Text("Email me a receipt")
        }
        .font(.subheadline)
        .foregroundColor(.blue)
    }
} else if showEmailField || !receiptEmail.isEmpty {
    // Email field with remove option
    VStack(alignment: .leading, spacing: 8) {
        HStack {
            Text("Email for receipt")
            Spacer()
            Button("Remove") {
                showEmailField = false
                receiptEmail = ""
            }
        }
        TextField("your@email.com", text: $receiptEmail)
            // ... email-specific modifiers
    }
}
```

### Behavior

**Smart auto-show logic:**
- Default: Field hidden, button visible
- Tap button -> Field appears with keyboard auto-focused
- Enter email -> Field persists across sheet dismissals (until cart cleared or payment succeeds)
- "Remove" button -> Hides field and clears email
- Payment success -> Shows "Receipt sent to [email]" confirmation

### Design Rationale

**Why Progressive Disclosure?**
1. **Industry best practice**: Used by Apple Pay, Stripe, all modern mobile payment apps
2. **Mobile-first**: Critical for small screens and in-person transactions
3. **Reduced cognitive load**: 12% lower cart abandonment with simpler forms (Baymard Institute)
4. **Perfect for use case**: Farmers markets/retail - most people don't need receipts
5. **Apple HIG compliant**: Optional fields should be collected "ahead of time or after purchase"

**User Experience:**
- Majority of users: Clean, fast checkout with no distractions
- Users wanting receipts: One tap reveals field (discovery cost is minimal)
- Email persists intelligently: If entered once, shows on reopening checkout sheet

**Result:**
- Cleaner checkout screen
- Professional, modern UI matching industry standards
- Faster checkout for majority of users
- All existing functionality preserved
- Better accessibility (less visual noise)

**Lessons Learned:**
- Progressive disclosure reduces friction without hiding functionality
- One-tap reveal is acceptable discovery cost for optional features
- Industry patterns exist for good reasons (mobile payment UX is well-studied)
- "Simple by default, detailed when needed" is the right approach for checkout flows
- Trust user feedback: "This is ugly" often indicates a real UX problem worth solving
