# Swift & iOS Learning Notes

SwiftUI patterns, anti-patterns, and lessons learned during development.

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

---

## Anti-Pattern: Redundant Boolean State for Sheet Presentation

**Context:** November 2025 - Created ProductsView with BOTH `editingProduct: Product?` AND `showingProductEditor: Bool`, causing blank sheet bug on first tap.

### The Mistake
Creating redundant boolean flags alongside optional state for sheet presentation. This caused a race condition where the sheet would appear blank on first tap, then work after tapping a different item.

### Bad Pattern (causes bugs)
```swift
@State private var editingProduct: Product?
@State private var showingProductEditor = false  // <- UNNECESSARY! Creates race condition

Button(action: {
    editingProduct = product
    showingProductEditor = true  // <- Manual sync required
}) { ... }

.sheet(isPresented: $showingProductEditor) {
    if let product = editingProduct { ... }  // <- Can be nil due to timing
}
```

### Good Pattern
```swift
@State private var editingProduct: Product?  // <- Only state needed

Button(action: {
    editingProduct = product  // <- Auto-presents sheet
}) { ... }

.sheet(item: $editingProduct) { product in
    // product is guaranteed non-nil here
    // Sheet auto-presents when editingProduct set
    // Sheet auto-dismisses when editingProduct becomes nil
}
```

### Why This Matters
- Redundant state creates synchronization bugs
- `.sheet(item:)` already handles presentation automatically
- More state = more complexity = more bugs
- **User caught this pattern happening TWICE in 36 hours** - clear sign of over-engineering

**Root Cause:** Adding state "just in case" instead of using SwiftUI's built-in patterns. Always ask: "Is this state truly necessary or am I duplicating logic that the framework already handles?"

---

## Anti-Pattern: Race Conditions from Bundled State Updates

**Context:** November 2025 - Implemented toast notification feature for "Add to Cart" action. Initially had a delay with bundled state resets that created a race condition.

### The Bug
Item name would flash "Custom item 2" then immediately go blank, causing all subsequent items to have blank names in the cart.

### The Root Cause
```swift
// BAD: Delay with bundled state resets
DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
    amountInCents = 0
    draftItemName = ""  // <- Overwrites the "Custom item 2" that was just set!
}
```

The `draftItemName` was being reset to blank in a delayed closure, overwriting the "Custom item 2" value that was set via the return value.

### The Fix
```swift
// GOOD: Update state immediately, no delays
amountInCents = 0
draftItemName = nextManualItemName()
if dismissKeypadAfterAdd == "dismiss" {
    isKeypadActive = false
}
```

### Why This Matters
- **Simplicity over cleverness** - Immediate state updates are predictable and debuggable
- **Don't add delays for UX polish** - If button feedback isn't working, fix the animation, don't add timing hacks
- **Avoid race conditions** - Multiple code paths updating the same state at different times causes bugs
- **YAGNI** - The delay added no value and caused problems

**Key lesson:** User caught the bug by rapidly adding items, revealing the race condition. Then when we tried to keep the delay "for button feedback", it caused lag without even showing the swell animation properly. The simplest solution (immediate updates, no delays) was the right answer all along.

---

## @State vs @Binding - Persisting Draft Data Across Sheet Dismissals

### The Bug: Item Description Resets, But Amount Persists

**Observed Behavior:**
1. Open custom keypad sheet
2. Enter "$14.00" and type description "tennis lesson"
3. Swipe down to dismiss sheet (to check cart)
4. Reopen keypad sheet
5. **Bug**: Amount shows "$14.00" but description resets to "Custom Item 10"

### Root Cause: @State vs @Binding

**The difference:**

| Property Wrapper | Scope | Lifecycle | Use Case |
|-----------------|-------|-----------|----------|
| `@State` | Local to view | Resets when view recreates | View-specific temporary state |
| `@Binding` | Shared with parent | Persists in parent's state | Data that needs to survive view recreation |

**What was happening:**

```swift
// ContentView.swift
@State private var amountInCents: Int = 0  // <- Parent owns this

// CustomKeypadView.swift
@Binding var amountInCents: Int            // <- References parent's state (good)
@State private var itemName: String = ""  // <- Local to this view, resets on .onAppear (bad)

.onAppear {
    itemName = defaultItemName  // <- ALWAYS resets to "Custom Item 10"
}
```

**Why amountInCents persisted:**
- It's a `@Binding` -> points to ContentView's `@State`
- When sheet dismisses and reopens, CustomKeypadView recreates, but it reads the **same** value from ContentView
- Draft amount survives

**Why itemName reset:**
- It's `@State` -> local to CustomKeypadView
- When sheet dismisses and reopens, CustomKeypadView recreates with fresh `@State`
- `.onAppear` runs again, resetting to default "Custom Item X"
- Draft description lost

### The Fix: Make itemName a @Binding Too

**Changed:**
```swift
// ContentView.swift
@State private var amountInCents: Int = 0
@State private var draftItemName: String = ""  // <- NEW: Parent owns description too

// CustomKeypadView.swift
@Binding var amountInCents: Int
@Binding var itemName: String  // <- CHANGED from @State to @Binding

.onAppear {
    // Only set default if itemName is empty (first time)
    if itemName.isEmpty {
        itemName = defaultItemName
    }
}
```

**Reset logic moved to ContentView:**
```swift
onAddToCart: { name in
    basket.append(item)
    amountInCents = 0        // Reset amount
    draftItemName = ""       // Reset description
    // Both clear after successful add
}

onCancel: {
    amountInCents = 0        // Reset amount
    draftItemName = ""       // Reset description
    // Both clear on cancel
}
```

### When to Use Each Pattern

**Use @State when:**
- Data is purely local to the view
- Data doesn't need to survive view recreation
- Example: Toggle states, temporary UI state, loading indicators

**Use @Binding when:**
- Data needs to be shared with parent
- Data should persist across view recreation (like sheet dismissals)
- Child needs to modify parent's state
- Example: Form inputs, draft data, shared state

### Key Insight: Sheet Lifecycles

When you present a sheet with `.sheet(isPresented: $bool)`:
- **Sheet appears**: View initializes, `@State` variables set to defaults, `.onAppear` runs
- **Sheet dismisses**: View may be destroyed (depending on iOS optimization)
- **Sheet reappears**: View **recreates**, `@State` resets to defaults, `.onAppear` runs again

If you want data to survive this cycle, it must live in the **parent's @State** and be passed as **@Binding**.

### Lessons Learned
- `@Binding` creates a two-way reference to parent's `@State` - changes sync both ways
- Sheet dismissal can destroy the view, resetting all `@State` properties
- Draft/form data should live in parent and be passed as `@Binding` to survive sheet lifecycle
- `.onAppear` is not a one-time initializer - it runs every time the view appears
- Use conditional logic in `.onAppear` if you only want to set defaults when truly empty

---

## Pattern: "Manager" Classes for Wrapping System Frameworks

**Context:** December 2025 - Created `LocationPermissionManager` and `BluetoothPermissionManager` to wrap CoreLocation and CoreBluetooth.

### What is a "Manager"?

"Manager" is a naming convention (not a Swift language feature) for classes that wrap and manage some specific resource or system functionality.

### Why Use Managers?

1. **Wrap system frameworks** - Encapsulate `CLLocationManager`, `CBCentralManager`, etc.
2. **Act as delegates** - Apple's APIs use the delegate pattern (callbacks). The manager receives those callbacks and translates them into `@Published` properties that SwiftUI can observe.
3. **Provide a simpler interface** - Views call `manager.requestPermission()` and read `manager.isGranted` instead of dealing with framework complexity.

### Example: Before vs After

**Without Manager (messy view):**
```swift
struct MyView: View, CLLocationManagerDelegate {
    let locationManager = CLLocationManager()
    @State var status: CLAuthorizationStatus = .notDetermined

    var body: some View { ... }

    // View has to implement delegate methods
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        status = manager.authorizationStatus
    }
}
```

**With Manager (clean separation):**
```swift
// Manager handles all the framework complexity
class LocationPermissionManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var authorizationStatus: CLAuthorizationStatus
    private let locationManager = CLLocationManager()

    func requestPermission() { locationManager.requestWhenInUseAuthorization() }
    var isGranted: Bool { ... }
}

// View stays simple
struct MyView: View {
    @StateObject var locationManager = LocationPermissionManager()

    var body: some View {
        Text(locationManager.isGranted ? "Granted" : "Not granted")
        Button("Request") { locationManager.requestPermission() }
    }
}
```

### Key Points

- **@StateObject** - Use this to create managers in views (ensures single instance lifecycle)
- **ObservableObject + @Published** - Makes state changes trigger SwiftUI updates
- **NSObject inheritance** - Required if you need to be a delegate (CLLocationManagerDelegate, etc.)
- **Other names** for similar patterns: `Service`, `Handler`, `Provider`, `Store`

### When to Create a Manager

- When a system framework uses delegates/callbacks
- When you want to share state across multiple views
- When framework setup code would clutter your view
- When you need to test the logic independently
