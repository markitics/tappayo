# Code Cleanup & Tests

Code hygiene notes, technical debt, and testing gaps. Users won't notice these - they're internal quality improvements.

---

## Critical Bugs (Non-TTP)

### FatalError in Production Code (APIClient.swift:22)
**Issue**: Using `fatalError()` will crash the app if the URL is invalid.

**Current Code**:
```swift
guard let url = URL(string: "https://awesound.com/api/next/ttp/get-connection-token") else {
    fatalError("Invalid backend URL")  // App crashes!
}
```

**Fix**: Return error through completion handler instead of crashing.

### Navigation Bar Color Bug (SettingsView.swift:86-88)
**Issue**: Setting both background AND text to the same accent color makes title text invisible.

**Current Code**:
```swift
appearance.backgroundColor = UIColor(accentColor)  // background = accent
appearance.titleTextAttributes = [.foregroundColor: UIColor(accentColor)]  // text = accent too!
```

**Fix**: Either remove background color setting, or use contrasting text color.

---

## Code Cleanup Needed

### Dead/Unused Files (Some removed Nov 2025)
- [x] `AppStorageArray.swift` (142 lines, entirely commented out) - REMOVED
- [ ] `UserDefaultsKeys.swift` (commented out)
- [x] `BasketView.swift` (superseded by ContentView cart functionality) - REMOVED
- [x] `CheckoutView.swift` (superseded by ContentView checkout) - REMOVED
- [ ] `TerminalConnectionView.swift` (defined but never used)

### Commented-Out Code
- ReaderDiscoveryViewController.swift lines 13-16 (accent color code)
- ContentView.swift lines 126, 135, 147, 182, 248
- Multiple entire files as noted above

### Duplicated Code
- `applyDarkModePreference()` function exists identically in:
  - ContentView.swift (lines 249-260)
  - SettingsView.swift (lines 110-121)
- Should be extracted to shared utility or view modifier

---

## Configuration Issues

### Hardcoded Values
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

---

## Code Quality Issues

### Excessive Print Statements
- 20+ `print()` statements throughout ReaderDiscoveryViewController
- Should use proper logging (OSLog) with appropriate log levels
- Print statements don't appear in production builds

### Force Try Usage (ReaderDiscoveryViewController.swift:28)
```swift
let config = try! LocalMobileDiscoveryConfigurationBuilder().build()
```
- Will crash if build fails
- Should use proper error handling with do-catch

### Missing Input Validation
- No maximum amount validation for cart items
- Quick amounts can be set to 0 (filtered in UI but could cause confusion)
- No validation for negative amounts

### Inconsistent Formatting
- `if(!basket.isEmpty)` should be `if !basket.isEmpty` (ContentView.swift:143)
- Mixed comment styles throughout

---

## Testing Gaps

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

---

## Technical Debt

### Architecture
- Mixed SwiftUI/UIKit (ReaderDiscoveryViewController is UIKit while rest is SwiftUI)
- No centralized state management
- Consider migrating to pure SwiftUI or proper coordinator pattern

### Error Handling
- Inconsistent patterns (completion blocks, throws, print statements)
- No unified error handling strategy

### Logging
- No proper logging infrastructure, just print statements
- Should implement OSLog throughout

---

## Prioritized Cleanup Action Items

### Phase 1: Critical Fixes (Do First)
- [ ] Replace fatalError with proper error handling
- [ ] Fix navigation bar color bug

### Phase 2: Code Cleanup
- [x] Remove all dead/unused files (Nov 2025: Removed BasketView.swift, CheckoutView.swift, AppStorageArray.swift)
- [x] Consolidate currency formatting (Nov 2025: Unified 8 duplicate formatters into single implementation)
- [ ] Remove commented-out code
- [ ] Extract duplicated dark mode logic
- [ ] Replace print() with OSLog

### Phase 3: Configuration & Validation
- [ ] Make location ID configurable
- [ ] Make API endpoint configurable
- [ ] Add input validation for amounts
- [ ] Convert magic numbers to named constants

### Phase 4: Testing
- [ ] Add unit tests for cart calculations
- [ ] Add unit tests for settings persistence
- [ ] Add integration tests for payment flow
- [ ] Add tests for retry logic

### Phase 6: Developer Experience (Optional)
- [ ] Add SwiftUI Previews to main views (ContentView, CheckoutSheet, SettingsView)
