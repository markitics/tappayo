# Tappayo - Claude Code Development Notes

## Project Overview

**Tappayo** is a learning-focused iOS application built to explore:
1. iOS development (SwiftUI & UIKit)
2. Stripe's Tap to Pay SDK for iPhone

The app provides a simple, streamlined interface for in-person payment processing using iPhone's built-in NFC capabilities. It's designed as a personal learning project by Mark Moriarty to understand mobile payment integration and iOS app development patterns.

## Development History

- **~April 2024**: Initial development using "vibe-coding" approach
- **November 2025**: Transitioning to Claude Code for systematic improvements. Still hard-coded to one Stripe account (Mark's).

## Tech Stack

- SwiftUI (primary UI framework)
- UIKit (specialized views like ReaderDiscoveryViewController)
- Stripe Terminal SDK (payment processing, using "Tap to Pay on iPhone")
- UserDefaults (settings persistence)

## Current Features

- Simple cart-based checkout interface
- Customizable quick-amount buttons for common prices
- Swipe-to-delete cart items
- Light/Dark mode support
- Accent color customization
- Reader discovery and connection with retry logic
- Auto-dismiss numeric keypad on outside tap
- Auto-focus on quick amount input when adding new amounts

---

## Development Guidelines

**CRITICAL - Always Use Current APIs**:
- **NEVER recommend or use deprecated APIs**
- Always check Apple Developer Documentation for deprecation warnings
- Use the latest iOS/Swift versions (iOS 26.1+ as of November 2025)
- When searching for APIs, verify they are NOT marked "Deprecated"

**Note on Commented-Out Code**: Inline comments are welcome and encouraged. Commented-out code often exists as a valuable papertrail showing earlier versions or alternative approaches.

---

## Documentation

Detailed notes are organized in the `docs/` folder:

| File | Contents |
|------|----------|
| `docs/ttp-sdk-reader-connectivity.md` | Stripe Terminal SDK, reader discovery/connection, retry logic, robustness analysis |
| `docs/design-notes.md` | Visual/UI patterns, UI quirks, "make it prettier" notes |
| `docs/shipped-features.md` | Documentation of live features (currency formatting, cart, settings) |
| `docs/future-features.md` | Feature backlog (NOT TTP stuff) - transaction history, receipts, tips, etc. |
| `docs/swift-ios-learning-notes.md` | SwiftUI patterns, anti-patterns, lessons learned |
| `docs/code-cleanup-and-tests.md` | Code hygiene, dead files, testing gaps, tech debt |

---

## Resources

- [Stripe Terminal iOS SDK Documentation](https://stripe.com/docs/terminal/sdk/ios)
- [Stripe Tap to Pay on iPhone](https://stripe.com/docs/terminal/payments/setup-reader/tap-to-pay)
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui/)

## Git
As a rule of thumb, Claude should never spontaneously commit changes to git. Better ask, "Now would be a good time to commit these changes; would you like me to do that, or will you (Mark) manually commit these changes?". The most common response Mark will type will be something like "I'll do the git commit; please propose a commit message".

If Claude does create a commit message, never include extraneous lines like the following:
"🤖 Generated with [Claude Code](https://claude.com/claude-code)
Co-Authored-By: Claude <noreply@anthropic.com>"

It's obvious from the existence of claude.md that Claude Code is helping pair-program this entire app. So let's keep the git history clean and avoid bragging about Claude's involvement in every commit.


