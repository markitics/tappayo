# Principles

- A person who's never heard of Stripe should be able to download this app from the App Store and make a live charge (charging a card or digital wallet in live mode) ASAP. That "time from app download to first charge" is a key differentiator of this app.
- To enable the fastest "time to first charge", we'll use progressive onboarding. That is, we'll only collect the information that's absolutely required when it's required. For example, you can probably define products without entering your name. You can even create your firt live charge without having completed the Stripe login or Stripe onboarding. You will of course need to add a bank account (or Stripe account) in order to get paid (to receive your  earnings), but you don't need to do this before creating your first live charge. "First live charge" means charging a card using Apple Tap to Pay, and seeing your earnings go up. 
- The charge can happen on the platform account, esepecially if the user hasn't yet linked a Stripe account. 
  1. If a user hasn't completed the Stripe login/onboarding, then the live charge will happen on the platform (Tappayo.com) account. Funds will show as owed to them (e.g., sales $100 minus $2 fees = Future payouts: $98"). They'll need to go through some Stripe onboarding (link an existing Stripe account, or go through Stripe Express onboarding, TBD) to claim what's owed to them. 
  2. If a user has completed the Stripe login/onobarding, we have a choice of how to set up the charge; it could happen via the platform (separate charges and transfers) or it could happen from the Connected account (I think… maybe only if we do Standard Connect). This will be decided later. 


# In-app checklist for users

**Get started in less than two minutes**

- [ ] Create app account (Sign in with Apple)
- [ ] Name your business
- [ ] Learn about 'Tap to Pay on iPhone' (watch video or swipe through screenshots)
- [ ] Accept Apple terms for 'Tap to Pay on iPhone' 
- [ ] Enable app permissions (Bluetooth and Location - both are required for Tap to Pay on iPhone)

That's it! You're now ready to:
- [ ] Make your first live charge 🙌 (any amount $0.50 up to $2.00).
(Button to trigger first TTP)

**Milestone:** You can now sell up to $100 in total. 


**Get paid**
- [ ] Describe your business (indiv vs busines; services vs physical vs other; website)
- [ ] View my earnings
- [ ] Add a bank account, or link an existing Stripe account
- [ ] Get paid 🙌

**Milestone:** You're truly in business now! You can now sell up to millions of dollars per year. 

**Optional extras: Customize your shop**
- [ ] Set tax rate (optional)
- [ ] Enable tipping (optional)
- [ ] Save products for quick checkout 
- [ ] Add team members
- [ ] Give feedback to the creators of this app



A user can complete the tasks in any sensible order. Some tasks, it doesn't matter which they do first. Other tasks depend on others having been completed. 

## Design

There are three screens when you open the app at first. If you haven't yet "set up" the app

Screen 1: A super simple screen that tells us the name of this app and super short summary of how it works. I'll probably create a video welcome here in due course.

Screen 2: The "Get started" checklist. Initially none of these boxes are ticked, and the 'Create first charge / Charge card' button is inactive. When all boxes have been ticked (all tasks complete), the 'Charge card' button becomes clickable. When clicked, it brings up a Tap to Pay screen.

Details here (scroll down to view Screen 3).

**Get started in less than two minutes**

- [ ] Create Tappayo account 
If box is not ticked, then the CTA below this line should be a "Log in or Sign up" button. At launch, we'll only offer "Sign in with Apple". At the backend, we'll use supabase.

- [ ] Name your business
If box is not ticked, the text field should be blank with a feint placeholder like "Manny's manicures". If box is ticked, the text field should be populated with the business name, but remain editable.

- [ ] Learn about 'Tap to Pay on iPhone' (watch video or swipe through screenshots)
Tapping this item (either tapping the tick-box or anywhere on the row with text) should bring up a sheet with the following words: "we'll embed the Tap to Pay video or screenshots here; we'll use Apple's official educational material".

In particular, we'll follow the guidance here: https://developer.apple.com/design/human-interface-guidelines/tap-to-pay-on-iphone 
see section:
> Educating merchants
> Some merchants may be unfamiliar with Tap to Pay on iPhone, so it’s important to give them a quick and easy way to get started.

> You can build your app’s tutorial using Apple-approved assets from the [Tap to Pay on iPhone marketing guidelines](https://developer.apple.com/tap-to-pay/marketing-guidelines/), or you can use the [ProximityReaderDiscovery](https://developer.apple.com/documentation/ProximityReader/ProximityReaderDiscovery) API to provide a pre-built merchant education experience. Apple ensures that the API is up to date and is localized for the merchant’s region.

- [ ] Accept Apple terms for 'Tap to Pay on iPhone' 
If the user has already accepted the Apple TTPOI (Tap to Pay on iPhone) terms with their Apple account, this should be ticked; pressing it again has no effect. If they have NOT already accepted the TTPOI Apple terms, then tapping this item should trigger that flow. 

See the documentation on this page: https://developer.apple.com/design/human-interface-guidelines/tap-to-pay-on-iphone
In particular, see this section:
> **Enabling Tap to Pay on iPhone**
> Before your app can enable Tap to Pay on iPhone and configure a merchant’s device, the merchant must accept the relevant terms and conditions. Use the ProximityReader API to help you get the current status and present an acceptance flow only when necessary. For developer guidance, see Adding support for Tap to Pay on iPhone to your app.
> **Help merchants accept Tap to Pay on iPhone terms and conditions before they begin interacting with their customers.** Merchants must accept the terms and conditions before you perform the initial device configuration, so it works well when they can do so before they begin a checkout or other customer-facing flow. For example, you can provide buttons that let people accept Tap to Pay on iPhone terms and conditions from within your in-app messaging or onboarding flows.

- [ ] Enable app permissions (Bluetooth and Location - both are required for Tap to Pay on iPhone)


That's it! You're now ready to:
- [ ] Make your first live charge 🙌 (any amount $0.50 up to $2.00).
(Button to trigger first TTP)

**Milestone:** You can now sell up to $100 in total.


---

# Onboarding Gate: Preventing Premature Auto-Connection

## The Problem

The Stripe Terminal SDK has a useful feature: it automatically attempts to reconnect to a previously-connected reader on app launch. For returning users, this is great—seamless, no friction.

But for **new users**, this creates a jarring experience:

1. User opens the app for the first time
2. App immediately triggers `discoverAndConnectReader()`
3. **BOOM** — Apple's scary "Tap to Pay on iPhone" terms sheet appears
4. User hasn't seen any value, any explanation, or any context
5. They feel ambushed, not welcomed

This is particularly problematic because:
- Apple's terms sheet is legally-dense and intimidating
- The user hasn't invested any time in the app yet
- They're more likely to abandon at this point
- No trust or enthusiasm has been built

## How Stripe SDK Handles Apple Account Linking

The Stripe Terminal SDK automatically handles the "Link your Apple account" flow when needed. This is a one-time step required by Apple for Tap to Pay on iPhone. The SDK:

1. Checks if the user has already accepted Apple's TTP terms
2. If not, presents Apple's system terms sheet
3. Handles the account linking transparently

This is convenient for the developer, but means we **don't control when** this sheet appears unless we gate the reader connection.

## The Solution: Gentle Onboarding Gate

We gate the auto-connection behind a boolean: `hasCompletedInitialOnboarding`

### Implementation

1. **UserDefaults flag**: `hasCompletedInitialOnboarding` (defaults to `false`)

2. **WelcomeView** (`WelcomeView.swift`) — A simple 2-page welcome flow:
   - **Page 1**: Welcome message + friendly promise ("The easiest way to accept payments. No card reader needed.")
   - **Page 2**: Business name input + "Get Started" button

3. **Gate logic**:
   - App's root view checks the flag
   - If `false` → show `WelcomeView`
   - If `true` → show `ContentView` (which triggers reader connection)

4. **On "Get Started"**:
   - Save business name (if entered)
   - Set `hasCompletedInitialOnboarding = true`
   - App transitions to main view
   - Auto-connection naturally triggers → Apple's terms sheet appears

### Why This Works

By the time the Apple terms sheet appears, the user has:
- Seen a welcoming first impression
- Understood what the app does
- Invested 30+ seconds of attention
- Made a micro-commitment (entering business name)
- Tapped "Get Started" — they're mentally ready for "next steps"

The Apple sheet now feels like a **natural progression**, not a surprise attack.

### Code Reference

```swift
// WelcomeView.swift — On "Get Started" button tap:
UserDefaults.standard.hasCompletedInitialOnboarding = true
hasCompletedOnboarding = true
```

The view uses `TabView` with `.page` style for swipeable pages, and binds to `hasCompletedOnboarding` to signal completion to the parent view.
