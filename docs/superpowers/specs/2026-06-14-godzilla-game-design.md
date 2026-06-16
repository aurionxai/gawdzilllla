# GAWDZILLLLA — Game Design Spec
**Date:** 2026-06-14 (revised 2026-06-15)
**Engine:** Love2D 11.x (Lua)
**Platforms:** Mobile Browser · Desktop Browser · Desktop Native (via love.js + Docker)
**Style:** Pixel Art / Retro (16-bit)
**Deployment:** Docker → Railway → Public URL
**Status:** Approved for implementation

---

## 1. Overview

A pixel-art kaiju fighting and city-destruction game featuring the full Godzilla monster universe plus original superhero characters. Players choose from 20 playable characters to battle each other or rampage through 50 global cities. Every city has a signature food power-up with a localized voice line, a fart aftermath system, and thousands of blood-splatting NPC humans to crush. Easter egg character Gregg wanders every stage stealing food and blaming his farts on others.

**Tagline:** *Choose your monster. Eat the city. Blame Gregg.*

---

## 2. Technical Architecture

### Engine & Stack
- **Love2D 11.x** — 2D game framework (Lua), sprite-based rendering
- **Language:** Lua throughout
- **Rendering:** Love2D SpriteBatch for GPU-efficient sprite batching; particle systems via `love.graphics.newParticleSystem` for blood/destruction/fart clouds
- **Audio:** `love.audio` — all SFX and music managed via source objects with volume groups
- **Persistence:** `love.filesystem` (local save files, JSON-encoded) for player progress
- **Web runtime:** love.js (Emscripten/WebAssembly build of Love2D core) — same Lua source runs in browser
- **Mobile input:** Touch events via love.js touch polyfill (`love.touchpressed`, `love.touchmoved`, `love.touchreleased`) wired to virtual joystick + button overlay

### Project Structure
```
godzilla-game/
├── main.lua                ← entry point, REF_W/REF_H scaling, scene dispatch
├── conf.lua                ← window config, resizable=true
├── src/
│   ├── scene_manager.lua
│   ├── scenes/             ← main_menu, character_select, city_select, vs_fight, story, survival, tournament
│   ├── fight_manager.lua
│   ├── attack_system.lua
│   ├── character.lua
│   ├── characters/         ← per-character tables (stats, sprites, unleash def)
│   ├── city.lua
│   ├── city_renderer.lua
│   ├── cities_data.lua     ← all 50 city definitions
│   ├── npc.lua
│   ├── npc_spawner.lua
│   ├── blood_pool.lua
│   ├── food_manager.lua
│   ├── food_renderer.lua
│   ├── audio_manager.lua
│   ├── hud.lua
│   ├── input.lua           ← keyboard + touch unified input layer
│   ├── controller.lua
│   ├── cpu_controller.lua
│   ├── kaiju_sprites.lua
│   ├── sprite_loader.lua
│   ├── landmark_defs.lua
│   ├── restaurant_defs.lua
│   ├── story_lore.lua
│   ├── story_state.lua
│   └── fps/                ← FPS battle subsystem
├── sprites/
│   ├── characters/
│   └── cities/
├── audio/
│   ├── powerups/           ← powerup_<city>_<lang>.mp3 (50 files)
│   ├── characters/         ← roars, voice lines, gawdzilla shout
│   ├── npcs/               ← splat_01–12.mp3, crowd_scream_01–06.mp3
│   ├── farts/              ← tier1–4 SFX, 6 types per tier
│   └── music/              ← bgm_<city>.mp3 (50 city themes)
├── docker/
│   ├── Dockerfile          ← love.js build + nginx serve
│   ├── nginx.conf          ← gzip, cache headers, CORS for audio
│   └── build.sh            ← emscripten love.js compile script
└── docs/
    └── superpowers/specs/
```

### Scene Flow
```
Main Menu → Mode Select → Character Select → City Select → BATTLE → Results + XP
```

### Build Targets
- **Web (primary):** love.js WebAssembly bundle → nginx → Docker → Railway URL
- **Desktop (dev/testing):** Native Love2D binary (`love .` from project root)
- **Mobile:** Same web build — responsive canvas auto-scales to phone viewport

---

## 3. Deployment — Docker + Railway

### love.js Build
love.js compiles Love2D's C core to WebAssembly via Emscripten. All Lua source + assets are packaged into a `.love` file that runs client-side in the browser. No server-side game logic required.

Build output:
```
dist/
├── index.html      ← shell template with canvas
├── love.js         ← Emscripten JS loader
├── love.wasm       ← compiled Love2D core
└── game.love       ← zipped Lua source + assets
```

### Dockerfile
```dockerfile
FROM emscripten/emsdk:3.1.50 AS builder
WORKDIR /build
COPY . .
RUN ./docker/build.sh          # outputs to dist/

FROM nginx:alpine AS runtime
COPY --from=builder /build/dist /usr/share/nginx/html
COPY docker/nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
```

Two-stage build: heavy Emscripten toolchain stays in builder layer only; runtime image is lean nginx (~25MB).

### nginx.conf
- Gzip compression for `.js`, `.wasm`, `.love` files
- `Cache-Control: max-age=31536000, immutable` for hashed assets
- `Cross-Origin-Opener-Policy: same-origin` + `Cross-Origin-Embedder-Policy: require-corp` (required for SharedArrayBuffer / audio worklets)
- Fallback to `index.html` for SPA routing

### Railway Deployment
- Push repo to GitHub → Railway watches the branch
- Railway detects Dockerfile → builds + deploys automatically
- Railway assigns URL: `gawdzilllla.up.railway.app` (or custom domain)
- Environment variable `PORT` auto-injected by Railway; nginx listens on `$PORT`
- Asset size target: < 100MB total (WASM + `.love` bundle); Railway free tier handles this

### Local Dev
```bash
# Play natively (fast iteration, no build step)
love .

# Build + preview Docker locally
docker build -t gawdzilllla . && docker run -p 8080:80 gawdzilllla

# Push → Railway auto-deploys
git push origin main
```

---

## 4. Mobile-Friendly Design

### Canvas Scaling (already implemented in main.lua)
```lua
local REF_W, REF_H = 480, 270   -- 16:9 logical resolution
-- scale = min(screen_w / REF_W, screen_h / REF_H)
-- letterbox centered, pixel-perfect
```

### Touch Input Layer
The `src/input.lua` module abstracts keyboard ↔ touch so fight logic never sees raw events.

**Virtual controls (mobile HUD overlay):**
- **Left side:** D-pad / floating joystick (thumb zone, bottom-left 40% of screen)
- **Right side:** 4 circular buttons — LIGHT, HEAVY, SPECIAL, UNLEASH (bottom-right 40%)
- **Center bottom:** visible only in story mode — destruction score ticker

Touch zone detection via `love.touchpressed`/`love.touchmoved`:
```lua
-- Joystick: track touch ID, compute dx/dy from anchor, normalize to [-1, 1]
-- Buttons: fixed rect hit-test per button
```

Dual-thumb support — Love2D tracks multiple touches by ID; P1 left thumb + P1 right thumb work simultaneously with no conflict.

### Performance Targets (Mobile Browser)
| Target | Desktop | Mobile Browser |
|--------|---------|---------------|
| Frame rate | 60 fps | 30–60 fps |
| NPC pool | 200 active | 100 active |
| Particle cap | 500 | 250 |
| Texture res | Full | Full (pixel art is small) |
| Audio | All channels | All channels (Web Audio API) |

### Audio on Mobile
Web browsers gate audio until first user gesture. The love.js shell handles this: a tap-to-start overlay appears before the Love2D `love.load()` runs, unlocking the Web Audio context. After that, all `love.audio` calls work normally.

---

## 5. Playable Characters

### Starter Roster (Free — 6 kaiju)
Godzilla (Classic), King Kong, Mothra, Rodan, King Ghidorah, MechaGodzilla

### Unlockable Kaiju (IAP or Battle Pass)
Biollante, Destoroyah, Gigan, SpaceGodzilla, Hedorah (Smog Monster), Anguirus

### Original Superhero Characters (IAP)
All are smaller than kaiju but power meter abilities scale up dramatically:

| Character | Archetype | Signature Power |
|-----------|-----------|-----------------|
| Titan | Superman | Laser vision + flight |
| Ironclad | Iron Man | Repulsor blast + missile swarm |
| Webslinger | Spider-Man | Web nets + acrobatic combo |
| Thunderstrike | Thor | Lightning hammer + storm call |
| Shadowfist | Batman | Gadgets + MechaGodzilla hack |
| Pyroknight | Original flame | Meteor crash + magma eruption |
| Psywave | Jean Grey | Telekinesis slam + mind prison |
| Deepguard | Aquaman | Trident slam + tsunami wave |

### Easter Egg: GREGG
- Spawns randomly (1-in-500 chance per stage)
- Dark hair, full beard, navy baseball cap (Nike logo), light blue polo, khaki pants, white Nike shoes with orange swoosh, brown briefcase
- **Invincible** — cannot be killed, bounces off kaiju stomps, brushes off polo and keeps walking
- **Steals food power-ups** — runs toward them and eats them before the player
- **Farts** after eating, then immediately blames the nearest character/NPC/tank/building
- **Blame priority:** nearest kaiju by name → nearest hero → nearest NPC → nearest tank → the city itself
- Despawns before player can corner him
- Unlocks **"Found Gregg"** achievement → Gregg NPC skin replaces 10% of background crowd permanently

**Gregg Idle Animations:** phone check, food eating (zero urgency), finger-point claiming credit, shrug after being stepped on, coffee sip, briefcase open/close revealing nothing

---

## 6. City Stages (50 Cities)

### Asia Pacific (14)
| City | Food Power-Up | Language Voice Line | Fart Tier |
|------|--------------|-------------------|-----------|
| Tokyo | 🍢 Yakitori | やきとり！パワーアップ！ (JP) | 1 |
| Osaka | 🐙 Takoyaki | たこやき！うまいで！ (Kansai JP) | 4 — Octopus Anomaly |
| Kyoto | 🍣 Sushi | お寿司！いただきます！ (JP) | 1 |
| Seoul | 🥩 Korean BBQ | 삼겹살! 먹자! (KR) | 4 — Screen-Wide Event |
| Shanghai | 🥟 Soup Dumplings | 小笼包！太好吃了！(ZH) | 2 |
| Beijing | 🦆 Peking Duck | 北京烤鸭！(ZH) | 2 |
| Hong Kong | 🍜 Wonton Noodles | 雲吞麵！好正！(Cantonese) | 1 |
| Bangkok | 🌶️ Pad Thai | ผัดไทย! เผ็ดมาก! (TH) | 3 |
| Mumbai | 🍛 Butter Chicken | बटर चिकन! वाह! (HI) | 3 |
| Delhi | 🫓 Naan + Tandoor | (HI) | 4 — Tandoor Blast |
| Singapore | 🦀 Chili Crab | Chili Crab! Shiok lah! (Singlish) | 3 |
| Kuala Lumpur | 🍲 Laksa | (MS) | 2 |
| Sydney | 🥩 Shrimp on Barbie | Shrimp on the barbie, mate! (AU-EN) | 1 |
| Auckland | 🥧 Pavlova | (EN-NZ) | 1 |

### Europe (16)
| City | Food Power-Up | Language Voice Line | Fart Tier |
|------|--------------|-------------------|-----------|
| Paris | 🥐 Croissant | Croissant! Magnifique! (FR) | 1 |
| Rome | 🍕 Pizza | PIZZA! Mamma mia! (IT) | 2 |
| Naples | 🍝 Pasta | Spaghetti! Incredibile! (IT-Neapolitan) | 2 |
| Madrid | 🥘 Paella | ¡Paella! ¡Olé! (ES-Castilian) | 2 |
| Munich | 🥨 Schnitzel | SCHNITZEL! Ja, genau! (DE-Bavarian) | 2 |
| Berlin | 🌭 Currywurst | Currywurst! Wunderbar! (DE) | 2 |
| London | 🐟 Fish & Chips | Fish and chips! Brilliant! (EN-Cockney) | 1 |
| Amsterdam | 🧇 Stroopwafel | (NL) | 2 |
| Lisbon | 🐟 Bacalhau | (PT) | 1 |
| Athens | 🥙 Gyros | Γύρος! Ωραίο! (EL) | 2 |
| Stockholm | 🐟 Gravlax | (SV) | 1 |
| Brussels | 🍟 Belgian Frites | (FR-BE / NL-BE) | 2 |
| Zurich | 🫕 Fondue | (DE-CH) | 4 — Dairy Disaster |
| Prague | 🍖 Svíčková | (CS) | 2 |
| Warsaw | 🥟 Pierogi | (PL) — 3-burst bounce | 3 |
| Moscow | 🍲 Borscht | Борщ! Очень хорошо! (RU) | 3 |

### Americas (13)
| City | Food Power-Up | Language Voice Line | Fart Tier |
|------|--------------|-------------------|-----------|
| New York | 🍔 Burger | BURGER! Oh yeah baby! (EN-NYC) | 2 |
| Mexico City | 🌮 Tacos al Pastor | ¡Tacos al pastor! ¡Ándale! (ES-MX) | 3 — Silent But Deadly |
| New Orleans | 🦞 Crawfish Étouffée | (EN-Southern) | 2 |
| San Francisco | 🦀 Sourdough + Clam Chowder | (EN) | 1 — fog/stealth |
| Miami | 🍋 Cuban Sandwich | (ES-CU / EN) | 2 |
| Los Angeles | 🌯 Cali Burrito | (EN / ES) | 2 — cannonball |
| Toronto | 🍁 Poutine | (EN-CA) — says "sorry" | 2 |
| Montreal | 🥯 Smoked Meat Bagel | (FR-CA / EN-CA) | 2 |
| Rio de Janeiro | 🥩 Churrasco | Churrasco! Caramba! (PT-BR) | 3 |
| Lima | 🍋 Ceviche | (ES-PE) | 2 — acid burst |
| Buenos Aires | 🥩 Asado | (ES-AR) | 3 |
| Bogotá | 🍲 Ajiaco | (ES-CO) | 3 — 3-consecutive |
| Havana | 🍹 Mojito | (ES-CU) | 1 — vision blur |

### Middle East & Africa (7)
| City | Food Power-Up | Language Voice Line | Fart Tier |
|------|--------------|-------------------|-----------|
| Dubai | 🦪 Shawarma | شاورما! يلا! (AR-Gulf) | 2 |
| Istanbul | 🍢 Döner Kebab | Döner! Afiyet olsun! (TR) | 2 |
| Cairo | 🫓 Koshary | (AR-EG) | 3 — speed burst |
| Lagos | 🍲 Jollof Rice | Jollof Rice! E don do! (Pidgin) | 2 — confetti fart |
| Nairobi | 🥩 Nyama Choma | (SW) | 3 — beast mode |
| Johannesburg | 🍖 Braai | (EN-ZA / AF) | 3 |
| Marrakech | 🫕 Tagine | (AR-MA / FR) | 2 |

### Each City Also Has:
- Unique pixel art tilemap with iconic landmarks
- City-specific BGM (genre matches culture — jazz, J-pop, opera, cumbia, afrobeats, etc.)
- Day / Night variants (same city, different lighting + NPC density)
- 3 "funny variant" voice lines per power-up (random 30% chance)

---

## 7. Food Power-Up System

### Breakout Scene Flow
1. Kaiju steps on glowing food icon in the street
2. 2-second pixel cutscene: kaiju at iconic local food stall/restaurant
3. Native-language voice line fires + subtitle shows (native script + English translation)
4. Power effect activates + optional fart aftermath

### Power-Up Effect Types
| Effect | Description |
|--------|-------------|
| DAMAGE BOOST | +50% damage for 15 sec |
| HEAL | Restore 25% HP |
| ARMOR SHELL | 50% damage resist |
| SPEED SURGE | 2x movement for 10 sec |
| RAGE MODE | Full power meter instantly |
| STEALTH | Invisible for 5 sec |
| MEGA SPECIAL | Unlock ultimate move |
| NPC FRENZY | 2x splat score for 30 sec |

---

## 8. Fart Power System

Every food power-up has a chance to trigger a signature fart attack after the breakout scene. Cuisine determines tier.

### Fart Tiers
| Tier | Name | Example Foods | Effect |
|------|------|--------------|--------|
| 1 | The Polite Puff | Croissant, Sushi, Fish & Chips | Small cloud, NPCs sneeze, 3 sec |
| 2 | The Rumblerino | Schnitzel, Paella, Poutine, Pierogis | Buildings crack, grease slicks, 8 sec |
| 3 | The Biohazard | Pad Thai, Butter Chicken, Tacos, Borscht | 15-sec toxic fog, enemy BURN + BLIND |
| 4 | The Apocalypse Fart | Korean BBQ, Fondue, Takoyaki, Tandoor | Screen-wide events, 20+ sec, sky turns green |

### Tier 4 Special Events
- **Korean BBQ:** All NPCs immediately splat. Enemy -30% HP. Sky turns green 20 sec. Kaiju looks genuinely shocked.
- **Fondue (Zurich):** Enemy frozen in solidifying cheese 5 sec. Slowest cloud, highest DPS.
- **Takoyaki (Osaka):** Ink-black cloud blinds BOTH fighters for 10 sec. Chaotic.
- **Tandoor (Delhi):** Fart so hot it melts buildings. Creates lava tiles on ground.

### Fart SFX Types
The Trombone · The Whistle · The Cannon · The Volcano · The Drumroll · Silent But Deadly

### Gregg's Fart
Gregg farts after eating stolen food. Cloud does zero damage. He immediately points at the nearest entity and blames them with a specific voice line:
- Godzilla: *"He does this every time. Classic Godzilla."*
- Kong: *"I've been saying Kong has a problem. Nobody listens."*
- MechaGodzilla: *"Exhaust leak. It's a mech thing. Engineering issue."*
- NPC: *"That little guy right there. I saw him."*
- Tank: *"Military grade diesel. That's on the government."*
- Alone: *"...There was someone here. They left."*

Gregg then walks away confidently. He has never accepted responsibility. He never will.

---

## 9. Combat System

### Controls — Desktop (Keyboard)
- **WASD / Arrow Keys:** Movement
- **Z / J:** Light Attack
- **X / K:** Heavy Attack
- **C / L:** Special
- **V / Space:** Unleash

### Controls — Mobile (Touch)
- **Left thumb zone:** Virtual floating joystick — movement + dodge (swipe-release)
- **Right thumb zone:** 4 circular buttons (min 60px radius, thumb-friendly spacing)
  - 👊 LIGHT — fast, low damage, chains to 3-hit combo, +5% power
  - 💥 HEAVY — slow, high damage, brief stun, +15% power
  - 🌀 SPECIAL — character signature move, costs 25% power
  - ☢️ UNLEASH — ultimate, requires full power meter, cinematic 3-sec animation (button glows + pulses when ready)

### input.lua Unified Layer
```lua
-- input.lua exports: isDown(action), wasPressed(action), axis()
-- Maps keyboard keys AND touch zones to the same action names
-- Fight logic only calls input.isDown("light"), never sees raw keys or touches
```

### Power Meter — Fill Sources
| Action | Power Gain |
|--------|-----------|
| Hit enemy | +5% |
| Destroy building | +8% |
| Splat NPC | +2% |
| Food power-up | +25% |
| Combo x5+ | +3%/hit |

### Dodge System
- Swipe left/right (touch) or tap direction key twice (keyboard) to dodge
- Brief invincibility frames
- Perfect dodge (< 0.3s before impact) → COUNTER state, next attack 2x damage

### Grab & Throw
Hold HEAVY near enemy → grab → swipe/hold direction → throw into buildings → building collapses → bonus NPC splats + destruction score

### Unleash Moves (Per Character)
| Character | Unleash Name | Effect |
|-----------|-------------|--------|
| Godzilla | Nuclear Pulse | Full-screen atomic explosion, everything within 3 blocks vaporized |
| Kong | Primal Rage | Picks up building, uses as bat, horizontal sweep |
| Mothra | Divine Wings | Rainbow beam, stuns all 5 sec, heals self 30% |
| Ghidorah | Triple Gravity Beam | 3 simultaneous lightning blasts, widest AoE |
| MechaGodzilla | Full Weapons Hot | All missiles + proton scream, says "EXTERMINATE" |
| Titan | Orbital Laser | Cinematic top-down camera cut, beam from orbit |
| Gregg | The Sandwich | Sits down, eats sandwich, heals self only, zero damage. Says "good team effort." |

---

## 10. Game Modes

### VS Mode
- 1v1 fighter — human vs CPU or local 2-player (same device, split touch zones)
- Health bars, timer, 3 rounds
- Winner screen with destruction dollar value

### Story / Smash Mode
- Choose a kaiju or hero, rampage through a city
- Replace opponent health bar with **Destruction Score** (dollar value)
- NPCs: street humans, military, tanks, helicopters — all splattable
- Wave counter: tanks → jets → helicopters → boss kaiju
- **SPLAT STREAK:** stomp 5 NPCs in 2 sec → *"SQUISH x5 — GAWDZILLLLA APPROVES"* + score multiplier
- City Destruction % progress bar — hit 100% to clear stage

### Survival Mode
- Endless waves of military + enemy kaiju
- Global leaderboard by score (server-side, Railway API endpoint)
- Difficulty scales per wave

### Tournament Mode
- Single-elimination bracket vs CPU
- Win to unlock lore + characters
- Tied to Battle Pass seasonal tournaments

### Future: Online PvP (Phase 2)
- WebSocket-based real-time 1v1 matchmaking (server running on Railway, same deploy)
- Rank system: Lizard → Monster → Kaiju → GAWDZILLLLA rank

---

## 11. HUD Layout

### VS Mode HUD
- **Top bar:** P1 health bar (left, green) + P2 health bar (right, red) + round timer (center)
- **Below health bars:** Power meter for each player (yellow fills left→right / right→left)
- **Bottom bar (mobile):** Virtual joystick (left) + 4 attack buttons (right) + destruction dollar counter (center)
- UNLEASH button glows red + pulses when power meter is full
- Touch controls hidden on desktop, auto-shown on touch device detection

### Story/Smash Mode HUD
- Destruction Score replaces opponent health bar
- Military wave countdown at top
- City Destruction % progress bar
- NPC Splat combo counter (floating text)

---

## 12. Audio System

### Localized Power-Up Voice Lines
- 50 MP3 files named `powerup_<city>_<lang>.mp3`
- Each triggers on food power-up breakout scene
- Subtitle system: native script + English translation, 2-second display
- Supports CJK, Arabic (RTL), Devanagari, Latin — Love2D font loading via `love.graphics.newFont` with appropriate TTFs
- 3 funny variant lines per city (30% random trigger chance)

### Web Audio Unlock
- love.js shows tap-to-start overlay → user gesture → Web Audio context unlocked → `love.load()` runs
- All subsequent `love.audio` calls work normally; no special handling needed in Lua code

### Character Audio
- `godzilla_gawdzilla.mp3` — the iconic shout, triggers on Unleash
- All 20 characters have: roar, hit grunt, unleash shout, taunt x3
- Superheroes have spoken English lines
- Gregg has 20+ blame voice lines + idle quips

### NPC Audio
- 12 randomized splat SFX (picks random on each crush, never repeats twice in a row)
- 6 crowd scream variants for mass-splat events

### Fart Audio
- 4 tiers × 6 SFX types = 24 fart sound files
- Pitch-shifted per character size via `source:setPitch()`
- Gregg fart: small, sad, mid-tier. Always followed by blame line.

### City Music
- 50 city BGM tracks, genre-matched (J-pop, jazz, opera, afrobeats, cumbia, etc.)
- Day/Night variants: night = slower, moodier version

---

## 13. NPC System

### NPC Types
| Type | Spawn Zone | Splat Effect | Points |
|------|-----------|-------------|--------|
| Street Human | Sidewalks, plazas | Pixel blood burst + crunch SFX | $1K |
| Police Officer | Near buildings | Blue splat + whistle SFX | $2K |
| Military Soldier | Mid-stage waves | Green splat + scream | $3K |
| Tank | Ground waves | Explosion + debris | $50K |
| Helicopter | Air waves | Fireball + spinning wreckage | $100K |
| Fighter Jet | Air waves | Sonic boom + crash | $200K |

### Blood Splat System
- `love.graphics.newParticleSystem` per NPC type
- Pixel-art blood sprite sheet (4-frame burst)
- Randomized splatter direction based on stomp/hit angle
- Blood puddle decal stays on ground for 30 sec
- Mass-splat events (5+ simultaneous) trigger screen flash + combo callout

---

## 14. Monetization & Payments

### Web Payments (Stripe)
- All purchases via Stripe Checkout (browser redirect)
- Purchase webhook → Railway API endpoint → unlocks stored server-side per user session/account
- No Apple/Google cut (browser web app, not App Store)

### Free Tier (Always)
- Play free in browser — no install required
- 6 starter kaiju fully playable
- 10 cities
- All 4 game modes
- Battle Pass free track (50 levels)

### IAP Catalog
| Item | Price |
|------|-------|
| Single character unlock | $2.99 |
| All Characters bundle | $14.99 |
| Character skin | $1.99 |
| City Stage Pack (5 cities) | $1.99 |
| Fart Sound Pack (10 SFX) | $0.99 |
| Gregg Voice Pack (30 lines) | $1.99 |
| Kaiju Coins (100) | $0.99 |
| Kaiju Coins (600) | $4.99 |

### Battle Pass (10-Week Seasons)
| Tier | Price | Includes |
|------|-------|---------|
| Free Track | $0 | 50 levels of rewards via gameplay |
| Kaiju Pass | $7.99 | 100 levels + season exclusive character |
| Titan Pass | $14.99 | Kaiju Pass + 25 level skip + exclusive Gregg skin |

### IAP Rules (Non-Negotiable)
- Zero pay-to-win — IAP is cosmetics, characters, sounds only
- No stat boosts, extra health, or power advantages for sale
- All characters earnable through tournament progression (slow) or IAP (fast)

---

## 15. Achievement System

| Achievement | Trigger | Reward |
|-------------|---------|--------|
| Found Gregg | Spot Gregg on any stage | Gregg NPC skin (10% crowd replacement) |
| GAWDZILLLLA | Trigger Godzilla Unleash 10 times | Golden Godzilla skin |
| Splat King | Crush 10,000 NPCs total | Blood Crown hat cosmetic |
| Food Thief | Have Gregg steal 5 power-ups in one session | "Gregg Was Here" stamp on results screen |
| City Destroyer | 100% destroy all 50 cities | Legendary Omega Godzilla skin |
| Blame Witness | Hear every Gregg blame line | Gregg Voice Pack unlocked free |
| Fart Scientist | Trigger all 24 fart types | "The Sommelier" title |

---

## 16. Technical Constraints & Performance Targets

- **Desktop target:** 60fps, 200 NPCs, 500 particles
- **Mobile browser target:** 30–60fps, 100 NPCs, 250 particles (scaled down via device detection)
- **WASM bundle size:** < 30MB for love.js + Love2D core; game assets < 70MB (total < 100MB)
- **Building destruction:** Pre-baked collapse animations (not real-time physics) for performance
- **Object pooling:** Blood particles, NPCs, projectiles all pooled — no mid-game GC pressure
- **Audio streaming:** BGM streamed (`love.audio.newSource(path, "stream")`); SFX loaded (`"static"`)

---

## 17. Implementation Phases

### Phase 1 — Core Game (MVP) ✓ In Progress
Love2D project setup, 3 starter characters (Godzilla, Kong, Ghidorah), 1 city (Tokyo), VS mode, basic HUD, health + power meter, light/heavy/special attacks, Unleash moves, basic NPCs with blood splat, scene manager, keyboard input

### Phase 2 — Mobile Touch + Web Deploy
Touch input layer in `input.lua`, virtual joystick + buttons HUD overlay, love.js build pipeline, Dockerfile + nginx.conf, Railway deploy, public URL live

### Phase 3 — Content Expansion
All 20 characters, all 50 cities, food power-up + breakout scene system, fart system, localized audio, story/smash mode, survival mode

### Phase 4 — Polish + Easter Eggs
Gregg easter egg character, achievement system, full audio library (ElevenLabs generated), tournament mode, particle polish

### Phase 5 — Monetization
Stripe integration, battle pass system, in-game shop, purchase webhook + Railway API endpoint, save/restore purchases

### Phase 6 — Launch
Railway production deploy, custom domain, analytics, soft launch, bug fixes

### Phase 7 — Online PvP (Post-Launch)
WebSocket server on Railway, matchmaking, ranked mode

---

*Spec written by Thomas + Claude. Game design approved 2026-06-14. Revised 2026-06-15: Unity → Love2D, mobile touch controls, Docker + Railway deployment.*
