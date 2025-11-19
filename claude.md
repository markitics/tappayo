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
- [ ] Remove all dead/unused files
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

---

## Learning Notes

This section can be used to document insights and learnings as development continues:

- *To be added as development progresses...*

---

## Resources

- [Stripe Terminal iOS SDK Documentation](https://stripe.com/docs/terminal/sdk/ios)
- [Stripe Tap to Pay on iPhone](https://stripe.com/docs/terminal/payments/setup-reader/tap-to-pay)
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui/)
