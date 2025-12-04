# Tap to Pay SDK & Reader Connectivity

All notes related to Stripe Terminal SDK, reader discovery, connection, and Tap to Pay on iPhone functionality.

---

## Retry/Timeout Logic Robustness Analysis (Nov 2025)

**Context**: Analysis of reader discovery/connection retry logic and app lifecycle handling to identify edge cases where the app could get stuck or fail to recover.

**Current Status**: App works perfectly in normal usage scenarios. This analysis documents potential improvements for future consideration when ready to tackle robustness systematically.

### What Works Well

1. **Discovery watchdog timer** (30-second timeout) - Successfully catches stuck discovery state
2. **Discovery retry logic** - 3 retries with 2-second delay between attempts
3. **Duplicate operation prevention** - Guard statements prevent multiple simultaneous discoveries/payments
4. **Auto-reconnect configuration** - `setAutoReconnectOnUnexpectedDisconnect(true)` enabled
5. **Payment error handling** - All payment steps (create/collect/confirm) handle errors gracefully

### Known Gaps & Edge Cases

**1. Connection Phase Has No Timeout (Critical)**
- **Issue**: `Terminal.shared.connectLocalMobileReader()` has no watchdog timer
- **Current behavior**: If connection callback never fires, stuck at "Connecting to reader..." forever
- **Why**: Discovery watchdog is only cancelled on connection SUCCESS (line 70), never started for connection phase
- **Recovery**: None - user must force-quit app
- **Impact**: Low likelihood in practice, but no graceful recovery

**2. Connection Retry Logic - FIXED Nov 2025**
- **Was**: Retry code checked shadowed `reader` variable (always nil in error path)
- **Fix**: Renamed completion handler param to `connectedReader`, now uses function param `reader`
- **Lines**: ReaderDiscoveryViewController.swift:66-84
- **Current behavior**: Retries up to 3 times with 2-second delay (same as discovery)

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

### Edge Case Scenarios

**Scenario A: Airplane Mode During Connection**
1. Discovery succeeds → finds reader
2. User enables airplane mode
3. `connectToReader()` called
4. Connection attempt hangs (no network)
5. **Result**: Stuck at "Connecting to reader..." forever (no timeout on connection phase)
   - Note: Retry logic now works (Nov 2025 fix), but connection phase still lacks a watchdog timer

**Scenario B: Poor Network During Connection**
1. Discovery succeeds
2. Connection attempt fails with timeout error
3. Retry logic executes (lines 78-84)
4. **Result (after Nov 2025 fix)**: Retries up to 3 times with 2-second delay

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

### Potential Future Improvements

**When ready to tackle robustness systematically, consider:**

0. **Add simulator guards for ProximityReader** - The `ProximityReader` framework (used for TTP terms acceptance and merchant education) only works on physical devices. Consider adding `#if targetEnvironment(simulator)` guards with appropriate messaging for simulator builds. Low priority since development/testing naturally happens on device for TTP features.

1. **Add connection timeout** - Same 30-second watchdog pattern as discovery
2. ~~**Fix connection retry logic**~~ - DONE Nov 2025
3. **Add app lifecycle monitoring** - Pause operations on background, reconnect on foreground using `@Environment(\.scenePhase)`
4. **Replace `try!` with proper error handling** - Use do-catch blocks
5. **Implement reader disconnect delegate** - Detect and handle unexpected disconnections
6. **Cap total retry attempts** - Prevent infinite loops across watchdog timeouts
7. **Add reader update timeout** - Safety net for stuck update operations
8. **Optional: Network reachability monitoring** - Proactively detect and handle offline state
9. **Optional: Payment intent persistence** - Save in-flight payment IDs for recovery (likely overkill for this use case)

### Robustness Assessment

**Score: 5/10** (was 4/10, bumped after Nov 2025 retry fix)

**Strengths:**
- Works perfectly for normal usage (farmers market, retail scenarios)
- Discovery timeout protection exists and works
- Payment error handling is decent
- Stripe SDK provides good safety guarantees

**Weaknesses:**
- Connection timeout missing (critical gap, but rare in practice)
- ~~Connection retry broken~~ - Fixed Nov 2025
- No lifecycle awareness (medium issue, battery drain potential)
- Several smaller gaps that compound

**Recommendation**: Document these issues but don't fix yet. App works well for current use case. Tackle in dedicated "robustness" branch when ready for systematic improvements.

---

## Reader Retry Logic Bug (Fixed Nov 2025)

**File**: ReaderDiscoveryViewController.swift:65-72

**Issue**: The retry logic wouldn't work because `reader` was nil in the error case. The code checked `if let reader = reader` inside an error handler where reader was guaranteed to be nil.

**Original Code**:
```swift
else if let error = error {
    // ... error handling ...
    if let reader = reader {    // reader is nil here!
        self.connectToReader(reader: reader, retriesRemaining: retriesRemaining - 1)
    }
}
```

**Fix**: Renamed completion handler param to `connectedReader`, now uses function param `reader` for retry.
