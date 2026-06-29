# Kaiju Kids — iOS app build (Capacitor)

Native iOS wrapper of the `kaiju-clash` web game. **One codebase, two distributions:** the same game
runs on kaijukids.co (web) and inside this app (native). The game itself detects which it is via the
`IS_NATIVE` flag (true here, because Capacitor loads it from the `capacitor://` scheme).

## What this is
- `capacitor.config.json` — appId `co.kaijukids.game` (change if you want), appName "Kaiju Kids",
  webDir `www`.
- `scripts/sync-www.mjs` — copies the game runtime (`index.html`, `progression.js`, `levelparse.js`,
  and the `bg bosses enemies food npcs skins sounds` asset folders) from `../kaiju-clash` into `www/`.
  Re-run it whenever the game changes.
- `assets/` — drop `icon.png` (1024×1024) and `splash.png` (2732×2732) here, then `npm run icons`.
- The native `ios/` project is **generated on your Mac** (step 2 below) — it is not committed.

## Prerequisites (on a Mac)
- **Xcode 26 or later** (App Store uploads after 2026-04-28 require Xcode 26+ / SDK 26+).
- **CocoaPods** (`sudo gem install cocoapods` or `brew install cocoapods`).
- Node 18+ (you have v24).
- An **Apple Developer Program** account (for signing + submission) — enroll first; D-U-N-S can take time.

## Steps
```bash
cd kaiju-clash-app

# 1. Install Capacitor (once). If package.json has no deps yet, this adds the current major:
npm install @capacitor/core @capacitor/cli @capacitor/ios \
            @capacitor/splash-screen @capacitor/status-bar @capacitor/haptics @capacitor/app
npm install -D @capacitor/assets

# 2. Bundle the game + generate the native iOS project (first time only)
npm run ios:add        # = sync www, then `npx cap add ios`

# 3. App icon + splash (after you put icon.png/splash.png in assets/)
npm run icons

# 4. Open in Xcode
npm run ios:open
```

In Xcode:
- Set the **Team** (your Apple Developer account) under Signing & Capabilities → signing is auto-managed.
- Confirm **Bundle Identifier** = `co.kaijukids.game` (or your choice; must match App Store Connect).
- **Lock orientation to Landscape:** target → General → Deployment Info → uncheck Portrait, keep
  Landscape Left/Right (the game is a landscape side-scroller). (Or edit `UISupportedInterfaceOrientations`
  in `ios/App/App/Info.plist`.)
- **Privacy manifest:** add `ios/App/App/PrivacyInfo.xcprivacy` (Phase 4 — see the approval plan).
- Run on a simulator or a connected iPhone (▶). Then **Product → Archive** → upload to App Store Connect.

## After every game change
```bash
npm run ios:sync       # re-copies www + `npx cap sync ios`
```

## Notes
- The game runs **fully offline** here (auto-reload is disabled when `IS_NATIVE`). The online leaderboard
  works when connected and no-ops offline.
- **Haptics** fire on stomp / level-win in the native app (added in the game's `_haptic` hook) — native
  value that helps clear App Review Guideline 4.2 ("not just a website").
- Keep the web build (kaijukids.co) as the source of truth; this app just re-bundles it.
