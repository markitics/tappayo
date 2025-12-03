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
