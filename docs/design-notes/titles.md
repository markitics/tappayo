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


