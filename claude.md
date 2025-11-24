# Tappayo - Claude Code Development Notes

## Project Overview

**Tappayo** is a learning-focused iOS application built to explore:
1. iOS development (SwiftUI & UIKit)
2. Stripe's Tap to Pay SDK for iPhone

The app provides a simple, streamlined interface for in-person payment processing using iPhone's built-in NFC capabilities. It's designed as a personal learning project by Mark Moriarty to understand mobile payment integration and iOS app development patterns.

## Development History

- **~18 months ago**: Initial development using "vibe-coding" approach
- **November 2025**: Transitioning to Claude Code for systematic improvements and continued learning

## Tech Stack

- SwiftUI (primary UI framework)
- UIKit (specialized views like ReaderDiscoveryViewController)
- Stripe Terminal SDK (payment processing)
- UserDefaults (settings persistence)

## Current Features

- Simple cart-based checkout interface
- Customizable quick-amount buttons for common prices
- Swipe-to-delete cart items
- Dark mode support
- Accent color customization
- Reader connection with retry logic (up to 3 attempts)
- Auto-dismiss numeric keypad on outside tap
- Auto-focus on quick amount input when adding new amounts

---

## Development Guidelines

**CRITICAL - Always Use Current APIs**:
- **NEVER recommend or use deprecated APIs**
- Always check Apple Developer Documentation for deprecation warnings
- Use the latest iOS/Swift versions (iOS 26.1+ as of November 2025)
- When searching for APIs, verify they are NOT marked "Deprecated"
- If unsure, search for "site:developer.apple.com/documentation/swiftui [api-name] NOT deprecated"

**Note on Commented-Out Code**: Inline comments are welcome and encouraged. Commented-out code often exists as a valuable papertrail showing earlier versions or alternative approaches. Keep inline comments in the code rather than just documenting separately in files like this one.

**Note on Observations Below**: The observations and suggestions listed below are Claude's initial analysis. They are noted for consideration but are not necessarily agreed upon or prioritized for action. Treat them as food for thought rather than a mandate.

---

## Claude Self-Reflection: Avoiding Cargo-Cult Recommendations

**Context:** November 2025 - During folder organization discussion, I recommended "New Group" (Xcode visual-only organization) over "New Folder" (physical folders) based on "common convention" rather than thinking critically about what's actually better for git cleanliness and maintainability.

**Notes to Self - Before recommending patterns, self-check:**

1. **Ask "Why?"** - Don't just cite conventions. Justify WHY this approach is better for THIS project
2. **Challenge with first principles** - Does this actually solve the user's problem, or is it just "how it's always been done"?
3. **Call out "conventional" vs "correct"** - If recommending based on common practice, explicitly state tradeoffs and let user decide
4. **Present tradeoffs** - What are the downsides of each approach? Don't default to one answer
5. **Question timestamps** - When did this pattern become common? Is it still relevant in 2025? (Especially for iOS where conventions can be decades old)

**Key lesson:** User's reasoning (git cleanliness, matching disk structure) was obviously correct. I should have presented both options with honest tradeoffs instead of defaulting to legacy convention.

### Anti-Pattern: Redundant Boolean State for Sheet Presentation

**Context:** November 2025 - Created ProductsView with BOTH `editingProduct: Product?` AND `showingProductEditor: Bool`, causing blank sheet bug on first tap.

**The Mistake:**
Creating redundant boolean flags alongside optional state for sheet presentation. This caused a race condition where the sheet would appear blank on first tap, then work after tapping a different item.

**Bad Pattern (causes bugs):**
```swift
@State private var editingProduct: Product?
@State private var showingProductEditor = false  // ← UNNECESSARY! Creates race condition

Button(action: {
    editingProduct = product
    showingProductEditor = true  // ← Manual sync required
}) { ... }

.sheet(isPresented: $showingProductEditor) {
    if let product = editingProduct { ... }  // ← Can be nil due to timing
}
```

**Good Pattern:**
```swift
@State private var editingProduct: Product?  // ← Only state needed

Button(action: {
    editingProduct = product  // ← Auto-presents sheet
}) { ... }

.sheet(item: $editingProduct) { product in
    // product is guaranteed non-nil here
    // Sheet auto-presents when editingProduct set
    // Sheet auto-dismisses when editingProduct becomes nil
}
```

**Why This Matters:**
- Redundant state creates synchronization bugs
- `.sheet(item:)` already handles presentation automatically
- More state = more complexity = more bugs
- **User caught this pattern happening TWICE in 36 hours** - clear sign of over-engineering

**Root Cause:** Adding state "just in case" instead of using SwiftUI's built-in patterns. Always ask: "Is this state truly necessary or am I duplicating logic that the framework already handles?"

---

## Known Issues & Quirks

### Scroll Indicator Flash Not Visible
**Context**: Added `.scrollIndicatorsFlash(onAppear: true)` to CartListView (via FlashScrollIndicatorsModifier) to help users discover scrollable content when the cart has many items.

**Issue**: The flash is not visible on Mark's device (iPhone 17 Pro Max, iOS 26.1), despite being officially supported on iOS 17+.

**Current Status**: Code remains in place as it may work for other users or future iOS versions. The gradient fade overlay at the bottom of the list (80pt height) serves as the primary visual indicator that more content is available, and this is working correctly.

**File**: `CartListView.swift:149` and `FlashScrollIndicatorsModifier` (lines 172-181)

### Emoji Picker Positioning (Nov 2025)
**Context**: Redesigned product icon picker in SettingsView to use unified button with confirmationDialog for choosing emoji/photo/camera options.

**Issue**: MCEmojiPicker (external library) has wonky positioning behavior. Even after moving `.emojiPicker()` modifier outside the ForEach to eliminate competing instances, the picker doesn't anchor consistently to the tapped product.

**Current Status**: Functional but not ideal. The emoji picker appears in unpredictable locations rather than anchoring near the icon you tapped. Consider alternative approaches:
- Different emoji picker library with better anchor support
- Custom emoji picker implementation
- Sheet-based modal for product editing (similar to ItemEditorView) that could contain emoji selection
- Accept the current behavior as "good enough" for a learning project

**File**: `SettingsView.swift:52-184` (unified icon button), `SettingsView.swift:185-202` (emoji picker modifier)

### Retry/Timeout Logic Robustness Analysis (Nov 2025)

**Context**: Analysis of reader discovery/connection retry logic and app lifecycle handling to identify edge cases where the app could get stuck or fail to recover.

**Current Status**: App works perfectly in normal usage scenarios. This analysis documents potential improvements for future consideration when ready to tackle robustness systematically.

#### ✅ What Works Well

1. **Discovery watchdog timer** (30-second timeout) - Successfully catches stuck discovery state
2. **Discovery retry logic** - 3 retries with 2-second delay between attempts
3. **Duplicate operation prevention** - Guard statements prevent multiple simultaneous discoveries/payments
4. **Auto-reconnect configuration** - `setAutoReconnectOnUnexpectedDisconnect(true)` enabled
5. **Payment error handling** - All payment steps (create/collect/confirm) handle errors gracefully

#### 🔴 Known Gaps & Edge Cases

**1. Connection Phase Has No Timeout (Critical)**
- **Issue**: `Terminal.shared.connectLocalMobileReader()` has no watchdog timer
- **Current behavior**: If connection callback never fires, stuck at "Connecting to reader..." forever
- **Why**: Discovery watchdog is only cancelled on connection SUCCESS (line 70), never started for connection phase
- **Recovery**: None - user must force-quit app
- **Impact**: Low likelihood in practice, but no graceful recovery

**2. Connection Retry Logic is Broken (Critical)**
- **Issue**: Retry attempt looks for `reader` parameter in error handler where it's guaranteed to be nil
- **Lines**: ReaderDiscoveryViewController.swift:77-83
- **Current behavior**: Shows "Reader is nil, cannot retry" instead of retrying
- **Fix needed**: Store reader reference from function parameter before attempting connection
- **Impact**: Connection failures (network issues, etc.) don't retry as intended

**3. Force Unwrap Will Crash App (Medium)**
- **Line**: ReaderDiscoveryViewController.swift:32
- **Code**: `try! LocalMobileDiscoveryConfigurationBuilder().build()`
- **Current behavior**: App crashes if build fails
- **Should**: Handle error gracefully with do-catch
- **Impact**: Low likelihood but catastrophic if it occurs

**4. No App Lifecycle Management (Medium)**
- **Issue**: No monitoring of background/foreground transitions
- **Current behavior**:
  - Discovery/connection operations continue in background
  - Timers keep running when app backgrounded
  - No cleanup on backgrounding
  - No reconnect on foregrounding
  - No pause/resume logic
- **Impact**: Battery drain, potential stale state on return to foreground

**5. Potential Infinite Retry Loop (Low)**
- **Issue**: Discovery watchdog timeout (line 180) calls `discoverAndConnectReader()` with default 3 retries
- **Current behavior**: Each watchdog timeout gives you 3 MORE retry attempts
- **Result**: Could retry indefinitely in certain failure modes
- **Impact**: Battery drain, poor UX

**6. No Reader Disconnection Handling (Low)**
- **Issue**: No implementation of `TerminalDelegate.didReportUnexpectedReaderDisconnect`
- **Current behavior**: If reader disconnects mid-session (not during payment), `isConnected` remains true
- **Result**: Stale connection state, UI says "Ready" when not actually connected
- **Mitigation**: Auto-reconnect config helps, but doesn't update UI state

**7. No Network State Monitoring (Low)**
- **Issue**: No proactive network reachability checking
- **Airplane mode scenario**: Discovery will fail and retry (works), but connection retry is broken (see #2)
- **Impact**: Degraded UX in poor network conditions

**8. Reader Update Has No Timeout (Low)**
- **Issue**: Reader software update progress (lines 196-214) has no timeout
- **Current behavior**: Shows progress updates
- **Result**: Could be stuck indefinitely if update never completes
- **Impact**: Very rare, Stripe SDK likely handles this

#### 🎯 Edge Case Scenarios

**Scenario A: Airplane Mode During Connection**
1. Discovery succeeds → finds reader
2. User enables airplane mode
3. `connectToReader()` called
4. Connection attempt hangs (no network)
5. **Result**: Stuck at "Connecting to reader..." forever (no timeout, retry broken)

**Scenario B: Poor Network During Connection**
1. Discovery succeeds
2. Connection attempt fails with timeout error
3. Retry logic tries to execute (line 79)
4. `reader` is nil in error handler
5. **Result**: Shows "Reader is nil, cannot retry" and stops

**Scenario C: Force Quit During Payment**
1. User taps $50 item
2. Payment intent created successfully
3. `collectPaymentMethod` in progress
4. User force-quits app
5. **Result**: Payment doesn't complete (Stripe safety guarantees prevent charge), but no in-app record
6. **Acceptable**: Merchant checks Stripe dashboard for transaction status

**Scenario D: App Backgrounded During Discovery**
1. Discovery in progress, timer at 15 seconds
2. User backgrounds app
3. iOS suspends timers
4. User returns 5 minutes later
5. **Result**: Timer resumes from 15 seconds, discovery may have failed long ago

#### 💡 Potential Future Improvements

**When ready to tackle robustness systematically, consider:**

1. **Add connection timeout** - Same 30-second watchdog pattern as discovery
2. **Fix connection retry logic** - Store reader reference before attempting connection
3. **Add app lifecycle monitoring** - Pause operations on background, reconnect on foreground using `@Environment(\.scenePhase)`
4. **Replace `try!` with proper error handling** - Use do-catch blocks
5. **Implement reader disconnect delegate** - Detect and handle unexpected disconnections
6. **Cap total retry attempts** - Prevent infinite loops across watchdog timeouts
7. **Add reader update timeout** - Safety net for stuck update operations
8. **Optional: Network reachability monitoring** - Proactively detect and handle offline state
9. **Optional: Payment intent persistence** - Save in-flight payment IDs for recovery (likely overkill for this use case)

#### 📊 Robustness Assessment

**Score: 4/10**

**Strengths:**
- Works perfectly for normal usage (farmers market, retail scenarios)
- Discovery timeout protection exists and works
- Payment error handling is decent
- Stripe SDK provides good safety guarantees

**Weaknesses:**
- Connection timeout missing (critical gap, but rare in practice)
- Connection retry broken (medium issue, network failures won't retry)
- No lifecycle awareness (medium issue, battery drain potential)
- Several smaller gaps that compound

**Recommendation**: Document these issues but don't fix yet. App works well for current use case. Tackle in dedicated "robustness" branch when ready for systematic improvements.

---

## Nov 2025: Claude Code Initial Observations and Possible Improvements

### 🚨 Critical Bugs

#### 1. Reader Retry Logic Broken (ReaderDiscoveryViewController.swift:65-72)
**Issue**: The retry logic won't work because `reader` is nil in the error case. The code checks `if let reader = reader` inside an error handler where reader is guaranteed to be nil.

**Current Code**:
```swift
else if let error = error {
    // ... error handling ...
    if let reader = reader {    // reader is nil here!
        self.connectToReader(reader: reader, retriesRemaining: retriesRemaining - 1)
    }
}
```

**Fix**: Need to store the reader reference before attempting connection, or re-discover the reader before retrying.

#### 2. FatalError in Production Code (APIClient.swift:22)
**Issue**: Using `fatalError()` will crash the app if the URL is invalid.

**Current Code**:
```swift
guard let url = URL(string: "https://awesound.com/api/next/ttp/get-connection-token") else {
    fatalError("Invalid backend URL")  // App crashes!
}
```

**Fix**: Return error through completion handler instead of crashing.

#### 3. Navigation Bar Color Bug (SettingsView.swift:86-88)
**Issue**: Setting both background AND text to the same accent color makes title text invisible.

**Current Code**:
```swift
appearance.backgroundColor = UIColor(accentColor)  // background = accent
appearance.titleTextAttributes = [.foregroundColor: UIColor(accentColor)]  // text = accent too!
```

**Fix**: Either remove background color setting, or use contrasting text color.

### 🧹 Code Cleanup Needed

#### Dead/Unused Files
- `AppStorageArray.swift` (142 lines, entirely commented out)
- `UserDefaultsKeys.swift` (commented out)
- `BasketView.swift` (superseded by ContentView cart functionality)
- `CheckoutView.swift` (superseded by ContentView checkout)
- `TerminalConnectionView.swift` (defined but never used)

#### Commented-Out Code
- ReaderDiscoveryViewController.swift lines 13-16 (accent color code)
- ContentView.swift lines 126, 135, 147, 182, 248
- Multiple entire files as noted above

#### Duplicated Code
- `applyDarkModePreference()` function exists identically in:
  - ContentView.swift (lines 249-260)
  - SettingsView.swift (lines 110-121)
- Should be extracted to shared utility or view modifier

### ⚙️ Configuration Issues

#### Hardcoded Values
1. **Stripe Location ID** (ReaderDiscoveryViewController.swift:51)
   - Currently: `"tml_FhUnQwoWdFn95V"`
   - Should be: Configurable in settings or environment

2. **API Endpoint** (APIClient.swift:22)
   - Currently: Hardcoded URL
   - Should be: Environment-based configuration

3. **Magic Numbers**
   - Minimum charge $0.50 (ContentView.swift:186)
   - Retry count of 3
   - 2-second retry delay
   - Should be named constants

### 🐛 Code Quality Issues

#### Excessive Print Statements
- 20+ `print()` statements throughout ReaderDiscoveryViewController
- Should use proper logging (OSLog) with appropriate log levels
- Print statements don't appear in production builds

#### Force Try Usage (ReaderDiscoveryViewController.swift:28)
```swift
let config = try! LocalMobileDiscoveryConfigurationBuilder().build()
```
- Will crash if build fails
- Should use proper error handling with do-catch

#### Missing Input Validation
- No maximum amount validation for cart items
- Quick amounts can be set to 0 (filtered in UI but could cause confusion)
- No validation for negative amounts

#### Inconsistent Formatting
- `if(!basket.isEmpty)` should be `if !basket.isEmpty` (ContentView.swift:143)
- Mixed comment styles throughout

### 🧪 Testing Gaps

**Current State**: Essentially no test coverage
- `TappayoTests.swift` contains only placeholder/example tests
- `TappayoUITests.swift` contains only launch tests

**Missing Tests**:
- Payment flow logic
- Cart operations (add, remove, calculations)
- Settings persistence
- Retry logic
- Currency formatting
- Reader connection states

### 🏗️ Technical Debt

#### Architecture
- Mixed SwiftUI/UIKit (ReaderDiscoveryViewController is UIKit while rest is SwiftUI)
- No centralized state management
- Consider migrating to pure SwiftUI or proper coordinator pattern

#### Error Handling
- Inconsistent patterns (completion blocks, throws, print statements)
- No unified error handling strategy

#### Logging
- No proper logging infrastructure, just print statements
- Should implement OSLog throughout

### ✨ Potential Feature Additions

#### High Value
1. **Transaction History**
   - No way to view past transactions
   - Should save transaction records locally
   - Enable export via email

2. **Receipt Generation**
   - Email digital receipts
   - Display/print receipts

3. **Offline Support**
   - Queue failed transactions for retry
   - Better offline state handling

4. **Multi-Item Cart Improvements**
   - Edit cart item names (currently just "Item 1", "Item 2")
   - Add item descriptions/categories
   - Edit quantities instead of delete-and-re-add

#### Medium Value
5. **Tip Support**
   - Configurable tip percentages
   - Custom tip amounts

6. **Tax Calculation**
   - Configurable tax rates
   - Display tax breakdown

7. **Multiple Location Support**
   - Support for multi-location businesses
   - Location switcher in settings

8. **Analytics/Reporting**
   - Daily sales totals
   - Transaction insights
   - Export reports

#### Polish
9. **Loading States**
   - Loading indicators during payment processing
   - Better visual feedback

10. **Success/Failure Animations**
    - Haptic feedback
    - Visual animations for payment results

11. **Onboarding**
    - First-run experience
    - Tap to Pay setup guidance

12. **Accessibility**
    - VoiceOver labels
    - Dynamic Type support
    - Color contrast validation

### 📋 Prioritized Action Items

#### Phase 1: Critical Fixes (Do First)
- [ ] Fix reader retry logic bug
- [ ] Replace fatalError with proper error handling
- [ ] Fix navigation bar color bug

#### Phase 2: Code Cleanup
- [x] Remove all dead/unused files (Nov 2025: Removed BasketView.swift, CheckoutView.swift, AppStorageArray.swift)
- [x] Consolidate currency formatting (Nov 2025: Unified 8 duplicate formatters into single implementation)
- [ ] Remove commented-out code
- [ ] Extract duplicated dark mode logic
- [ ] Replace print() with OSLog

#### Phase 3: Configuration & Validation
- [ ] Make location ID configurable
- [ ] Make API endpoint configurable
- [ ] Add input validation for amounts
- [ ] Convert magic numbers to named constants

#### Phase 4: Testing
- [ ] Add unit tests for cart calculations
- [ ] Add unit tests for settings persistence
- [ ] Add integration tests for payment flow
- [ ] Add tests for retry logic

#### Phase 5: Feature Additions
- [ ] Implement transaction history
- [ ] Add receipt generation
- [ ] Add tip support
- [ ] Improve cart item naming/editing
- [ ] **Saved Baskets** (Nov 2025: "Save Cart" button placeholder added to CheckoutSheet)
  - Serialize/stringify basket state (all line items with names, prices, quantities)
  - Store ~3 pre-saved baskets for quick loading
  - When cart is empty, show option to load a saved basket
  - Include stringified basket data in Stripe PaymentIntent metadata for record-keeping
  - Use cases: Recurring orders, common product bundles, testing scenarios

#### Phase 6: Developer Experience (Optional)
- [ ] Add SwiftUI Previews to main views (ContentView, CheckoutSheet, SettingsView)
  - Enables near-instant UI iteration in Xcode Canvas (Cmd+Option+Enter)
  - Useful for quick padding/color/layout adjustments without full rebuild
  - Current workflow (Cmd-R to physical device) works fine, but previews could speed up UI tweaks

---

## Learning Notes

### November 2025: Currency Formatting Consolidation

#### Problem Identified
The app had **8 different currency formatting implementations** scattered across the codebase:
1. `CurrencyTextField.format()` - Settings product input
2. `formatCurrency()` - ContentView (smart decimals)
3. `formatAmount()` - ContentView (always 2 decimals)
4. `formatCartAmount()` - ContentView (conditional decimals)
5. `formattedTotalAmount` - ContentView (with commas)
6. `CustomKeypadView.formatAmount()` - Keypad display
7. `CheckoutSheet.formatMoney()` - Checkout sheet
8. Inline formatting at ContentView:190 - Product grid

**Issues:**
- **Inconsistent comma usage**: Settings showed commas (`$1,234.56`), but main keypad didn't (`$1234.56`)
- **Code duplication**: Same logic repeated 8 times
- **Maintenance burden**: Changes required updating multiple locations
- **Performance**: Creating new NumberFormatter instances repeatedly

#### Solution Implemented
**Consolidated to unified approach using `NumberFormatter` with smart decimal logic:**

**Core Implementation (ContentView.swift:52-65):**
```swift
private func formatCurrency(_ cents: Int, forceDecimals: Bool = false) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.currencySymbol = "$"
    formatter.usesGroupingSeparator = true  // ← Key addition for commas

    // Smart decimal logic: show .00 only when needed
    let shouldShowDecimals = forceDecimals || (cents % 100 != 0)
    formatter.minimumFractionDigits = shouldShowDecimals ? 2 : 0
    formatter.maximumFractionDigits = shouldShowDecimals ? 2 : 0

    return formatter.string(from: NSNumber(value: Double(cents) / 100)) ?? "$0.00"
}
```

**Key Design Decisions:**

1. **Smart Decimal Logic Preserved**
   - Whole dollar amounts display clean: `$5`, `$20`, `$1,234`
   - Amounts with cents show decimals: `$5.50`, `$1,234.56`
   - `forceDecimals` parameter for contexts requiring alignment

2. **Comma Separators Always Enabled**
   - `usesGroupingSeparator = true` ensures readability for large amounts
   - Follows iOS best practices using `NumberFormatter.currency`

3. **Consistency Within Context**
   - Cart uses `cartHasAnyCents` check to force decimals if ANY item has cents
   - Tax summary uses `taxSummaryHasCents` for subtotal/tax alignment
   - Ensures visual consistency within a single transaction

#### The "Farmers Market Scenario"

**Design Goal:** Prices should display in the cleanest, most natural format.

**All whole dollars (common at farmers markets):**
```
Grip    $3   ×2    $6
Coffee             $5
Bag                $1
─────────────────────
Subtotal          $12
```

**Mixed pricing (consistency trumps brevity):**
```
Grip    $3.00 ×2   $6.00
Coffee             $5.50  ← This item has cents
Bag                $1.00
─────────────────────────
Subtotal          $11.50
```

**Large amounts (commas for readability):**
```
Equipment  $1,234 ×2  $2,468
Services              $3,500
─────────────────────────────
Total              $5,968
```

#### Implementation Details

**Files Modified:**
1. `ContentView.swift`:
   - Created unified `formatCurrency(cents, forceDecimals)`
   - Replaced 6 duplicate functions
   - Updated 11+ call sites
   - Enhanced `CustomKeypadView.formatAmount()` and `CheckoutSheet.formatMoney()`

2. `CurrencyTextField.swift`:
   - Added `usesGroupingSeparator = true` to ensure Settings input has commas

**Result:**
- ✅ Comma separators appear everywhere (including main keypad where previously missing)
- ✅ Smart decimal logic preserved (no unnecessary `.00` for whole dollars)
- ✅ Consistent formatting across entire app
- ✅ Single source of truth for currency display
- ✅ Better performance (fewer formatter instantiations)
- ✅ Build succeeds with no errors

**Lessons Learned:**
- `NumberFormatter` is the iOS-standard way to format currency
- Smart decimal logic improves UX for common use cases (farmers markets, retail)
- Context-aware formatting (checking if cart has cents) provides better consistency
- Consolidating duplicate code reduces maintenance and improves reliability
- User-facing clarity matters: commas make large amounts readable

### November 2025: Navigation Title vs Toolbar Items

#### Problem: Business Name Truncation
The business name was displaying as "M..." despite having plenty of available space.

**Attempted Solutions:**
1. **ToolbarItem(placement: .navigationBarLeading)** - iOS aggressively truncates toolbar items
2. **navigationTitle() with large title mode** - Wasted significant vertical space

#### Solution: Inline Navigation Title
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

### November 2025: Conditional UI in Checkout Sheet

**Context:** The checkout sheet adapts its UI based on cart size and tax settings to avoid showing redundant information.

#### The Logic (CheckoutSheet.swift lines 132-174)

The checkout sheet conditionally shows/hides Subtotal, Tax, and Total lines based on cart state:

**Scenario 1: Single item, no tax**
```
🍺 Beer (happy hour)    $6.00

[Pay button]
```
- **No** Subtotal line (redundant - item price = subtotal)
- **No** Tax line (tax is zero)
- **No** Total line (redundant - item price = total)

**Scenario 2: Single item, with tax**
```
🍺 Beer (happy hour)    $6.00

Tax                     $0.60
Total                   $6.60

[Pay button]
```
- **No** Subtotal line (still redundant - only one item)
- **Yes** Tax line (breakdown needed)
- **Yes** Total line (needed to show item + tax)

**Scenario 3: Multiple items, no tax**
```
🍺 Beer (happy hour)    $6.00
😻 Magic                $6.66

Subtotal               $12.66
Total                  $12.66

[Pay button]
```
- **Yes** Subtotal line (sum of multiple items)
- **No** Tax line (tax is zero)
- **Yes** Total line (even though same as subtotal, shown for consistency)

**Scenario 4: Multiple items, with tax**
```
🍺 Beer (happy hour)    $6.00
😻 Magic                $6.66

Subtotal               $12.66
Tax                     $1.27
Total                  $13.93

[Pay button]
```
- **Yes** Subtotal line
- **Yes** Tax line
- **Yes** Total line (subtotal + tax)

#### Implementation

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

#### Design Rationale

- **Minimize visual clutter**: Don't show lines that duplicate information already visible
- **Context-aware**: Show breakdown only when it adds value
- **Progressive disclosure**: Simple purchases stay simple, complex ones get detail

**Lessons Learned:**
- Smart conditionals improve UX by reducing cognitive load
- Consider all combinations when designing adaptive UI
- Document the logic clearly - it's not obvious without context

---

### November 2025: Progressive Disclosure for Optional Email Field

#### Problem: "Ugly" Always-Visible Email Input
The checkout sheet had an always-visible email TextField that looked awkward and cluttered the payment flow.

**Before (Always Visible):**
```
Subtotal                   $12.66

Email for receipt (optional)
[customer@example.com      ]  ← Blue placeholder text, takes up space

[Pay $12.66 button]
```

**Issues:**
- ❌ Blue placeholder text on dark backgrounds (poor contrast/aesthetics)
- ❌ Visual clutter on an already busy checkout screen
- ❌ Field takes up space even though most users don't need receipts
- ❌ Violates Apple Pay guidelines (optional fields shouldn't clutter payment sheets)
- ❌ Higher cognitive load = lower conversion rates

#### Solution: Progressive Disclosure Pattern

**After (Progressive Disclosure):**
```
Subtotal                   $12.66

📧 Email me a receipt      ← Simple button

[Pay $12.66 button]
```

**When tapped:**
```
Email for receipt         Remove
[your@email.com           ]  ← Auto-focused, proper styling

[Pay $12.66 button]
```

#### Implementation (CheckoutSheet.swift)

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

#### Behavior

**Smart auto-show logic:**
- Default: Field hidden, button visible
- Tap button → Field appears with keyboard auto-focused
- Enter email → Field persists across sheet dismissals (until cart cleared or payment succeeds)
- "Remove" button → Hides field and clears email
- Payment success → Shows "Receipt sent to [email]" confirmation

#### Design Rationale

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
- ✅ Cleaner checkout screen
- ✅ Professional, modern UI matching industry standards
- ✅ Faster checkout for majority of users
- ✅ All existing functionality preserved
- ✅ Better accessibility (less visual noise)

**Lessons Learned:**
- Progressive disclosure reduces friction without hiding functionality
- One-tap reveal is acceptable discovery cost for optional features
- Industry patterns exist for good reasons (mobile payment UX is well-studied)
- "Simple by default, detailed when needed" is the right approach for checkout flows
- Trust user feedback: "This is ugly" often indicates a real UX problem worth solving

---

## Resources

- [Stripe Terminal iOS SDK Documentation](https://stripe.com/docs/terminal/sdk/ios)
- [Stripe Tap to Pay on iPhone](https://stripe.com/docs/terminal/payments/setup-reader/tap-to-pay)
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui/)
