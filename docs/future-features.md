# Future Features

Feature backlog and improvement ideas. Does NOT include TTP SDK/reader connectivity improvements (those are in `ttp-sdk-reader-connectivity.md`).

---

## High Value

### Transaction History
- No way to view past transactions currently
- Should save transaction records locally
- Enable export via email
- **Use case**: End-of-day reconciliation, record keeping

### Receipt Generation
- Email digital receipts to customers
- Display/print receipts
- **Note**: Email field already exists in checkout (progressive disclosure pattern)

### Offline Support
- Queue failed transactions for retry
- Better offline state handling
- **Use case**: Farmers markets with spotty connectivity

### Multi-Item Cart Improvements
- Edit cart item names (currently auto-generated "Item 1", "Item 2")
- Add item descriptions/categories
- Edit quantities instead of delete-and-re-add

---

## Medium Value

### Tip Support
- Configurable tip percentages (15%, 18%, 20%, custom)
- Custom tip amounts
- **Use case**: Service businesses, food vendors

### Tax Calculation
- Configurable tax rates (already partially implemented)
- Display tax breakdown in receipts
- Multiple tax rate support for different item categories

### Multiple Location Support
- Support for multi-location businesses
- Location switcher in settings
- Per-location settings/products

### Analytics/Reporting
- Daily sales totals
- Transaction insights
- Export reports (CSV, PDF)
- **Use case**: Business owners wanting sales overview

### Saved Baskets (Nov 2025 idea)
- Serialize/stringify basket state (all line items with names, prices, quantities)
- Store ~3 pre-saved baskets for quick loading
- When cart is empty, show option to load a saved basket
- Include stringified basket data in Stripe PaymentIntent metadata for record-keeping
- **Use cases**: Recurring orders, common product bundles, testing scenarios
- **Note**: "Save Cart" button placeholder already added to CheckoutSheet

---

## Polish

### Loading States
- Loading indicators during payment processing
- Better visual feedback for all async operations

### Success/Failure Animations
- Haptic feedback on payment success/failure
- Visual animations for payment results
- Celebratory animation on successful payment

### Onboarding
- First-run experience
- Tap to Pay setup guidance
- Feature tour for new users

### Accessibility
- VoiceOver labels throughout
- Dynamic Type support
- Color contrast validation
- Reduced motion support

---

## Prioritized Feature Action Items

### Phase 5: Feature Additions (from original roadmap)
- [ ] Implement transaction history
- [ ] Add receipt generation
- [ ] Add tip support
- [ ] Improve cart item naming/editing
- [ ] Implement saved baskets feature

---

## Developer Experience (Optional)

### SwiftUI Previews
- Add SwiftUI Previews to main views (ContentView, CheckoutSheet, SettingsView)
- Enables near-instant UI iteration in Xcode Canvas (Cmd+Option+Enter)
- Useful for quick padding/color/layout adjustments without full rebuild
- Current workflow (Cmd-R to physical device) works fine, but previews could speed up UI tweaks
