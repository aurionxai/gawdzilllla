# Kaiju Clash → Apple App Store — Approval Plan

**Path chosen:** Capacitor wrapper (reuse the web game) · **Kids Category** · **Free, no IAP at launch** ·
Apple Developer account **not yet enrolled**.

**Today:** 2026-06-28. Note: uploads to App Store Connect now **must** be built with **Xcode 26+ / SDK 26+**
(in effect since 2026-04-28) — non-negotiable.

The work splits into: (A) make the web game genuinely playable & self-contained on an iPhone, (B) wrap it
natively with enough native value to clear "it's just a website," (C) satisfy the strict **Kids Category /
COPPA** rules, (D) privacy paperwork, (E) store assets, (F) build/submit. Enrollment (Phase 0) runs in
parallel and should start immediately because it can be the long pole.

---

## Phase 0 — Apple Developer Program enrollment  *(USER, start NOW — can take days–weeks)*
- [ ] Decide **Individual** vs **Organization** account. Org (recommended for the "Kaiju Kids" brand) shows
      a company name as seller and is needed if others join — but requires a **D-U-N-S number** (free, can
      take days to obtain/verify) and legal-entity info.
- [ ] Enroll at developer.apple.com ($99/yr). Have payment + (for Org) D-U-N-S + legal entity ready.
- [ ] Accept the latest Program License Agreement and **Paid/Free Apps agreements** in App Store Connect.
- **Blocker:** nothing can be submitted until this clears. The D-U-N-S step is why this is Phase 0.

## Phase 1 — Make the game iOS-playable & self-contained  ✅ COMPLETE (code) — device-tuning at TestFlight
- [x] **On-screen touch controls (CRITICAL).** ~Done (BUILD 45): `drawTouchControls`/`touchInBtn` give
      ◀ ▶ + ▲ jump/RISE + ▼ duck/DIVE + 💨 ATK, wired through the action helpers (`isMoveL/isJump/isDuck/
      isFart`), context labels (swim vs land), portrait rotate hint, and menu/overworld tap-nav. **Remaining:**
      real on-device tuning (button size/placement, multi-touch, not overlapping the bottom-right HUD).
- [x] **Fully offline.** ~Done (BUILD 47): audited — head has **no CDN/web-fonts/analytics**, all
      sound/sprite/bg load via relative `_av()` paths (bundled), and the leaderboard/quiz API no-ops offline
      (try/catch). The game runs with no network.
- [x] **Remove web-only behaviors / "remote content"** (Guideline 2.5.2 / 4.2). ~Done (BUILD 47): added
      **`IS_NATIVE`** (true only in the Capacitor shell). The **version.txt stale-page auto-reload is gated to
      web** (`!IS_NATIVE`) — verified: web fetches it, native does NOT. No remote `<script>`, no eval of
      fetched code; everything ships in the bundle. **ONE codebase → web (kaijukids.co) + native app diverge
      only at this runtime flag.**
- [ ] **Viewport / safe areas / notch.** Letterbox the 640×360 canvas cleanly, respect safe-area insets, lock
      orientation (landscape recommended for a side-scroller), disable text-selection/zoom/callouts.
- [ ] **iOS audio.** Web Audio already has the iOS unlock dance — re-verify inside WKWebView and with the
      hardware mute switch.

## Phase 2 — Capacitor native wrapper + native value  ✅ SCAFFOLDED (CLAUDE) — USER runs `cap add ios` on the Mac
- [x] **Scaffold built** in `kaiju-clash-app/` (BUILD 48): `package.json` (Capacitor **8.x** + ios/splash/
      status-bar/haptics/app + @capacitor/assets, installed & locked), `capacitor.config.json`
      (appId `co.kaijukids.game`, appName "Kaiju Kids", webDir `www`, `iosScheme:"capacitor"` → drives
      `IS_NATIVE`), `scripts/sync-www.mjs` (bundles the game runtime into `www/`), `.gitignore`,
      `BUILD-IOS.md` (step-by-step), and **app `icon.png` 1024 + `splash.png` 2732** generated from the hero
      art. Capacitor CLI 8.4.1 verified reading the config.
- [x] **Native value (Guideline 4.2):** offline play + **haptics** on stomp/level-win (`_haptic`, app-only) +
      native icon/splash + status-bar config. (Optional later: **Game Center** for the speedrun board — also
      de-risks kids-privacy vs the custom backend.)
- [ ] **USER, on the Mac:** `npm run ios:add` (= sync www + `npx cap add ios`, needs Xcode 26+ & CocoaPods)
      → `npm run icons` → `npm run ios:open`; set Team/signing, lock **Landscape** orientation, archive.
- [x] Web build (kaijukids.co) unchanged — the app re-bundles the same code via `IS_NATIVE`.

## Phase 3 — Kids Category & COPPA compliance  *(the highest rejection-risk area)*
Kids Category (Guideline 1.3 + 5.1.4) is strict. For THIS app:
- [ ] **No third-party advertising. No third-party analytics that collect data from kids.** Audit the bundle —
      remove/avoid any SDK that phones home (no Google Analytics, no ad SDKs, no Sentry-with-PII, etc.). The
      game appears to have none — keep it that way.
- [x] **Parental gate** built (`_parentGate`, `#pgov`, BUILD 46): a typed 2-digit-addition challenge (not
      multiple-choice). Currently gates **leaderboard identity creation**. **Remaining:** also put it in front
      of the privacy-policy / support links and (later) any IAP.
- [ ] **The leaderboard/quiz is the COPPA pressure point.** It collects a **username + friend code + scores**
      on your Railway backend. Mitigations:
      - [x] **Generated non-PII handle** done (BUILD 46): `_genHandle` (adjective+kaiju+number) + `#hpov`
        picker with a 🎲 reroll — **no free typing**, "never use your real name" copy. The biggest Kids-
        Category snag is closed. (Old web localStorage names persist; **purge test rows from the Railway DB
        before launch** so the live board has no real-ish names.)
      - Confirm the backend stores **no email/PII** (memory says COPPA-safe — re-verify end to end) and that
        nothing is shared with third parties.
      - **Alternative that de-risks a lot:** move the speedrun board to **Apple Game Center** (Apple handles
        identity/age) and keep the custom backend only for non-identified aggregate quiz mastery. Decide this
        explicitly — it trades dev work for fewer privacy headaches.
- [ ] **Age band:** set the Kids Category age band to **6–8** (or **9–11**) to match "8+". (Kids Category
      requires choosing 5-&-under / 6–8 / 9–11.)
- [ ] **Privacy policy** written for children's apps (what's collected, why, no third-party sharing, parental
      contact). Host it (kaijukids.co/privacy) AND surface it in-app behind the parental gate.

## Phase 4 — Privacy paperwork (must all tell the SAME story)  ✅ DRAFTED (CLAUDE) — BUILD 49
- [x] **`PrivacyInfo.xcprivacy`** drafted at `kaiju-clash-app/ios-template/PrivacyInfo.xcprivacy` — tracking
      false, two collected types (User ID, Other Usage Data; linked, app-functionality, no tracking),
      UserDefaults `CA92.1`. **USER:** add it to the Xcode App target + run Archive → Generate Privacy Report
      to catch any extra required-reason API.
- [x] **App Store privacy "nutrition label" answers** written in `docs/kaiju-clash-privacy-labels.md`
      (exact rows, Linked=Yes, Tracking=No, App Functionality) — to enter in App Store Connect.
- [x] **Kids privacy policy** at `kaiju-clash/privacy.html` → live `https://kaijukids.co/kaiju-clash/privacy.html`
      and **reachable in-app** (🔒 Privacy button on the Leaderboards screen, parental-gated). Bundled into
      the app via the www sync.
- [x] **No ATT** — not tracking; no ATT prompt.
- [ ] **Consistency check (blocking, at submit):** manifest ↔ labels ↔ policy ↔ live network (only the
      Railway leaderboard host) must match. Checklist in `kaiju-clash-privacy-labels.md`. Also **purge test
      rows** from the Railway DB before launch.

## Phase 5 — Store assets & metadata  *(CLAUDE produces; can reuse the game's art pipeline)*
- [ ] **App icon** — full set, no transparency, no rounded corners (Apple rounds it). Generate from the kaiju art.
- [ ] **Screenshots** — **6.9-inch iPhone** set is mandatory (primary); add **13-inch iPad** set **if** the app
      runs on iPad (decide iPhone-only vs universal). Must show **real gameplay UI** (we can capture from the
      game), kid-appealing. 1–10 each.
- [ ] **App name ≤30 chars** (e.g., "Kaiju Kids: Learn Japanese"), **subtitle ≤30**, **keywords ≤100 chars**
      comma-separated no-spaces, **description** with no prices and **no "also on Android."**
- [ ] **Age rating questionnaire** → should land **4+ / 9+** (cartoon "stomp," no real violence/scary content —
      answer honestly; mild cartoon action).
- [ ] Support URL, marketing URL, privacy-policy URL, category = **Education** (Kids Category is a secondary
      flag set in App Information).
- [ ] Optional: a ≤30s **App Preview** video captured from real gameplay.

## Phase 6 — Build, TestFlight, submit, iterate  *(USER on the Mac; CLAUDE preps everything)*
- [ ] Open the `ios/` project in **Xcode 26+**, set bundle ID, signing (auto-managed with the new account),
      version/build numbers, deployment target.
- [ ] Archive (Release, zero warnings) → upload to App Store Connect.
- [ ] **TestFlight internal** — play every screen on ≥2 device sizes; verify touch controls, audio, offline,
      parental gate, leaderboard.
- [ ] Fill **App Review notes**: explain it's an offline educational kaiju game for kids, how the parental gate
      works, that the leaderboard handle is non-PII, and how to reach the quiz/mini-games. (Reviewers reject
      when they can't find/understand features — spell it out.)
- [ ] Submit for review. Expect possible Kids-Category/privacy follow-ups; respond in **Resolution Center**
      factually with a short screen-recording if needed.
- [ ] After approval, consider **phased release**.

---

## Risk register — most likely rejections for THIS app
1. **No touch controls** → 2.1 unplayable. (Phase 1 — must-fix.)
2. **"Just a website" wrapper** → 4.2. Mitigated by offline bundle + haptics/native icon/splash + Game Center.
3. **Kids privacy / COPPA on the leaderboard** → 1.3 / 5.1.4. Mitigated by non-PII handles, no third-party
   SDKs, parental gate, accurate privacy label, (optionally) Game Center.
4. **Privacy manifest ↔ nutrition label ↔ behavior mismatch** → blocking. Keep them identical.
5. **Remote-content / auto-reload** looking like post-review code change → 2.5.2. Disable web auto-reload in app.
6. **Missing parental gate** before the privacy/support links → 1.3.
7. **Screenshots not real UI / missing 6.9" set** → 2.3.

## Who does what
- **USER:** Phase 0 enrollment (now), final Xcode signing/archive/upload, App Store Connect agreements + age
  questionnaire + submit, the Kids-Category/Game-Center call.
- **CLAUDE:** touch controls, Capacitor scaffold + native value, parental gate, non-PII handle system, disable
  web-only behaviors, privacy policy + privacy manifest drafts, icon + screenshots + metadata copy.

## Suggested order of execution
Phase 0 (start immediately, parallel) → Phase 1 (touch controls first — it's the biggest unknown) → Phase 2 →
Phase 3 → Phase 4 → Phase 5 → Phase 6. Phases 1–5 are mostly things I can build now; Phase 6 needs your Mac +
the enrolled account.
