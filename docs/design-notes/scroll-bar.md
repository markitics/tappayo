### Scroll Indicator Flash Not Visible

**Context**: Added `.scrollIndicatorsFlash(onAppear: true)` to CartListView (via FlashScrollIndicatorsModifier) to help users discover scrollable content when the cart has many items.

**Issue**: The flash is not visible on Mark's device (iPhone 17 Pro Max, iOS 26.1), despite being officially supported on iOS 17+.

**Current Status**: Code remains in place as it may work for other users or future iOS versions. The gradient fade overlay at the bottom of the list (80pt height) serves as the primary visual indicator that more content is available, and this is working correctly.

**File**: `CartListView.swift:149` and `FlashScrollIndicatorsModifier` (lines 172-181)


