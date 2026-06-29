# Kaiju Kids — App Store Connect privacy answers (must match manifest + policy)

These are the answers to enter in **App Store Connect → your app → App Privacy**, plus related fields.
They must stay consistent with `kaiju-clash-app/ios-template/PrivacyInfo.xcprivacy` and
`kaiju-clash/privacy.html`. Apple cross-checks all three plus actual network behavior; mismatches are a
top rejection cause.

## Privacy Policy URL
`https://kaijukids.co/kaiju-clash/privacy.html`  (set in App Store Connect → App Information →
Privacy Policy; also surface it in-app behind the parental gate — see "in-app access" below).

## App Privacy questionnaire

**"Do you or your third-party partners collect data from this app?"** → **Yes**
(the optional leaderboard sends a generated handle + scores to our own server).

Add exactly these **two data types**, both: **Linked to the user = Yes**, **Used for tracking = No**,
**Purpose = App Functionality** only.

| Data type (App Store Connect) | Maps to manifest | What it is | Linked | Tracking | Purpose |
|---|---|---|---|---|---|
| **Identifiers → User ID** | `NSPrivacyCollectedDataTypeUserID` | the randomly-generated nickname + the play-account id / friend code | Yes | No | App Functionality |
| **Usage Data → Product Interaction** (or "Other Usage Data") | `NSPrivacyCollectedDataTypeOtherUsageData` | best level times + Japanese-word mastery points | Yes | No | App Functionality |

**Do NOT add:** Name, Email, Phone, Physical Address, Precise/Coarse Location, Photos, Contacts,
Browsing/Search History, Device ID/advertising identifiers, Purchases, Health, Sensitive Info. None are
collected.

> Note on "Linked = Yes": the data is tied to the **pseudonymous play account**, not to a real-world
> identity (no name/email is ever collected). We declare Linked = Yes as the conservative, consistent
> choice across manifest + label. If legal counsel prefers "Not Linked" (since there's no real identity),
> change it in **both** the label and the manifest so they still match.

**App Tracking Transparency:** Not used. We do not track across apps/sites, so **do not** add the ATT
prompt or `NSUserTrackingUsageDescription` (an unnecessary ATT prompt is itself a rejection).

## Kids Category specifics (App Information)
- **Kids Category = Yes**, age band **6–8** (or 9–11) to match the 8+ audience.
- Confirm in the questionnaire: **no third-party advertising**, **no third-party analytics**, data
  collection limited to the above and behind a **parental gate**.
- **Age Rating:** answer the content questionnaire honestly — cartoon "stomp" action, no realistic
  violence / scary / mature content → expect **4+** (or 9+). No unrestricted web access (the app is a
  bundled game, the only outbound link is the parental-gated privacy policy).

## In-app access to the policy (required)
The privacy policy must be reachable **inside** the app, not only in App Store Connect. Options
(pick one; the parental gate `_parentGate` is already built and reusable):
1. A small **"Privacy / Parents"** button on the title or Leaderboards screen that, behind the parental
   gate, opens `privacy.html` (bundle it into `www/` or open via `@capacitor/browser`).
2. Render the policy text as an in-game screen.
(Status: **TODO** — quick wire-up; the gate component exists.)

## Consistency checklist before submitting (blocking)
- [ ] `PrivacyInfo.xcprivacy` added to the App target; `NSPrivacyTracking=false`, the two data types,
      UserDefaults `CA92.1`.
- [ ] App Store Connect labels = the two rows above, Linked=Yes, Tracking=No, App Functionality.
- [ ] `privacy.html` live at the URL above and reachable in-app.
- [ ] Xcode → Product → Archive → **Generate Privacy Report**: confirm no extra required-reason API is
      flagged that isn't declared (add any to the manifest).
- [ ] Run the live app with a network sniffer: the ONLY outbound host is the leaderboard API
      (`kaiju-api-production.up.railway.app`). No analytics/ad/tracking domains.
- [ ] **Purge test rows** from the Railway leaderboard DB so no real-ish legacy names appear publicly.
