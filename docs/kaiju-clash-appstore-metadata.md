# Kaiju Kids — App Store listing & metadata (Phase 5)

Compliance-focused draft (accuracy, field limits, format). **Keyword ranking / ASO optimization is a
separate exercise** — these are valid, rejection-safe starting values.

## ⚠️ One brand decision for you
The in-game logo says **"KAIJU CLASH"** but the domain is **kaijukids.co**. Apple likes the store name to
match the in-app UI (Guideline 2.3.7). Pick one and align:
- **Recommended:** store name **"Kaiju Kids"** (better parent discoverability + matches the domain) — and
  add "Kaiju Kids" to the title screen, or keep "Kaiju Clash" as the game-mode title under the Kaiju Kids
  brand.
- Or: store name **"Kaiju Clash"** to match the current logo exactly (less obviously a kids/edu app).

## Text fields
| Field | Limit | Value |
|---|---|---|
| **App Name** | 30 | `Kaiju Kids: Learn Japanese` (26) |
| **Subtitle** | 30 | `Eat, grow & learn Japanese!` (27) |
| **Keywords** | 100 | `japanese,language,dinosaur,monster,child,hiragana,kana,educational,vocabulary,platformer,reading` |
| **Promotional Text** | 170 | `New: dive into the underwater Sunken City — swim, rescue snorkeling townsfolk, and learn ocean words!` |

Keyword rules applied: comma-separated, **no spaces after commas**, no words already in the name
(`kaiju`, `kids` are auto-indexed), **no trademarked terms** (no "Godzilla"/"Kong"), singular only.

## Description (no prices, no other-platform mentions)
```
Stomp, splash, and SNACK your way across the city — then dive into a sunken ocean world — in
Kaiju Kids, a friendly monster platformer that sneaks in real Japanese as you play!

Pick your kaiju — Lulah the frilled dragon or Poppy the golden ape — and:

🦖 EAT to GROW. Munch food and townsfolk-snacks to grow from a tiny hatchling all the way to a
towering Apex kaiju.
🌏 LEARN JAPANESE the fun way. Rescue townsfolk and they teach you a word; beat baddies and learn
the creature's name. Hiragana, vocabulary, and reading — picked up through play, with real spoken audio.
🌊 EXPLORE WHOLE WORLDS. Smash through Tokyo rooftops, a neon night city, and swim through the
underwater Sunken City with its coral reefs and snorkeling friends.
🎮 PLAY MINI-GAMES. Hungry Kaiju, Stomp Match, and Catch the Word turn vocabulary into quick,
replayable challenges.
🏆 RACE THE LEADERBOARDS. Beat your best level times and climb the word-mastery ranks.

Made for kids:
• No third-party ads. No tracking. No analytics.
• No real names — players pick a fun made-up nickname.
• A grown-ups-only check guards the leaderboard and any links.
• Plays fully offline.

Eat. Grow. ROAR — and こんにちは to your new favorite way to learn Japanese!
```

## Other App Store Connect fields
- **Privacy Policy URL:** `https://kaijukids.co/kaiju-clash/privacy.html`
- **Support URL:** `https://kaijukids.co`
- **Marketing URL:** `https://kaijukids.co`
- **Primary category:** Education · **Secondary:** Games (Kids Category flag set separately — see plan).
- **Age rating:** answer honestly → expect **4+**. Heads-up: the game has a mild cartoon **"fart"** attack
  (toilet humor) — common in kids content and 4+-safe, but disclose it accurately in the questionnaire.
- **App Review notes:** "Offline educational kaiju platformer for children. No login required; the optional
  leaderboard uses a randomly-generated nickname (no PII) and is gated by a grown-ups-only math check.
  Privacy policy reachable in-app via Leaderboards → 🔒 Privacy. Touch controls: ◀▶ move, ▲ jump/rise,
  ▼ duck/dive, 💨 attack."

## Screenshots (6.9-inch iPhone — mandatory primary set)
Six **2868×1320** framed captures of real gameplay are in `kaiju-clash-app/store/screenshots/`:
1. `01-title` — EAT · GROW · ROAR (character select)
2. `02-city` — Stomp through the city
3. `03-swim` — Dive into the Sunken City
4. `04-learn` — Learn Japanese as you rescue
5. `05-play` — Mini-games make words stick
6. `06-board` — Race friends on the leaderboard

Notes: actual app UI on a branded frame with captions (Apple-allowed). Regenerate anytime with
`scratchpad/storeshots.js` against a local server. **If the app ships universal (iPad too),** also supply a
**13-inch iPad** set (capture at 2064×2752 / landscape 2752×2064). Decide iPhone-only vs universal in Xcode
(target → Supported Destinations).
```
```
