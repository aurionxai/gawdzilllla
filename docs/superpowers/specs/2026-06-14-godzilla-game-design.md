# GAWDZILLLLA — Game Design Spec
**Date:** 2026-06-14  
**Engine:** Unity 2D (Built-in Sprite Animator)  
**Platforms:** iOS · Android · WebGL (browser, mobile-first)  
**Style:** Pixel Art / Retro (16-bit)  
**Status:** Approved for implementation

---

## 1. Overview

A pixel-art kaiju fighting and city-destruction game featuring the full Godzilla monster universe plus original superhero characters. Players choose from 20 playable characters to battle each other or rampage through 50 global cities. Every city has a signature food power-up with a localized voice line, a fart aftermath system, and thousands of blood-splatting NPC humans to crush. Easter egg character Gregg wanders every stage stealing food and blaming his farts on others.

**Tagline:** *Choose your monster. Eat the city. Blame Gregg.*

---

## 2. Technical Architecture

### Engine & Stack
- **Unity 2D** — Universal Render Pipeline (URP), built-in Sprite Animator
- **Language:** C# throughout
- **Rendering:** GPU sprite batching, particle systems for blood/destruction/fart clouds
- **Audio:** Unity Audio Mixer — all SFX and music managed through mixer channels
- **Persistence:** Unity PlayerPrefs (local) + Unity Cloud Save (cross-device progress)
- **IAP:** Unity IAP SDK — auto-routes to App Store (Apple Pay) on iOS, Google Play on Android, Stripe on WebGL
- **Analytics:** Unity Analytics for funnel tracking, session length, IAP conversion

### Project Structure
```
Assets/
├── Characters/         ← sprites, animators, prefabs per kaiju/hero
│   ├── Kaiju/
│   ├── Heroes/
│   └── Easter/         ← Gregg
├── Cities/             ← tilemap stages + destructible building prefabs
├── NPCs/               ← human, tank, helicopter prefabs + splat particles
├── PowerUps/           ← food power-up prefabs + breakout scene prefabs
├── UI/                 ← health bar, power meter, menus, store, battle pass
├── Audio/
│   ├── PowerUps/       ← powerup_<city>_<lang>.mp3 (50 files)
│   ├── Characters/     ← roars, voice lines, gawdzilla shout
│   ├── NPCs/           ← splat_01–12.mp3, crowd_scream_01–06.mp3
│   ├── Farts/          ← tier1–4 SFX, 6 types per tier
│   └── Music/          ← bgm_<city>.mp3 (50 city themes)
└── Scripts/
    ├── Combat/         ← FightManager, AttackSystem, HitDetection
    ├── Characters/     ← CharacterBase, KaijuController, HeroController, GreggController
    ├── City/           ← DestructionSystem, NPCSpawner, BloodSplatPool, BuildingCollapse
    ├── PowerUps/       ← PowerUpManager, BreakoutScenePlayer, FartSystem
    ├── GameModes/      ← StoryMode, VSMode, SurvivalMode, TournamentMode
    ├── Audio/          ← AudioManager, LocalizedAudioPlayer, FartSFXPicker
    └── Monetization/   ← IAPManager, BattlePassManager, ShopManager, SaveData
```

### Scene Flow
```
Main Menu → Mode Select → Character Select → City Select → BATTLE → Results + XP
```

### Build Targets
- iOS (Xcode, Metal renderer)
- Android (Gradle, Vulkan/OpenGL ES3)
- WebGL (mobile-first responsive, Chrome/Safari)

---

## 3. Playable Characters

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

## 4. City Stages (50 Cities)

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

## 5. Food Power-Up System

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

## 6. Fart Power System

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
- **Fondure (Zurich):** Enemy frozen in solidifying cheese 5 sec. Slowest cloud, highest DPS.
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

## 7. Combat System

### Controls (Mobile)
- **Left thumb:** Virtual joystick — movement + dodge (swipe)
- **Right thumb:** 4 buttons
  - 👊 LIGHT ATTACK — fast, low damage, chains to 3-hit combo, +5% power
  - 💥 HEAVY ATTACK — slow, high damage, brief stun, +15% power
  - 🌀 SPECIAL — character signature move, costs 25% power
  - ☢️ UNLEASH — ultimate, requires full power meter, cinematic 3-sec animation

### Power Meter — Fill Sources
| Action | Power Gain |
|--------|-----------|
| Hit enemy | +5% |
| Destroy building | +8% |
| Splat NPC | +2% |
| Food power-up | +25% |
| Combo x5+ | +3%/hit |

### Dodge System
- Swipe left/right to dodge
- Brief invincibility frames
- Perfect dodge (< 0.3s before impact) → COUNTER state, next attack 2x damage

### Grab & Throw
Hold HEAVY near enemy → grab → swipe to throw into buildings → building collapses → bonus NPC splats + destruction score

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

## 8. Game Modes

### VS Mode
- 1v1 fighter — human vs CPU or local 2-player (same device)
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
- Global leaderboard by score
- Difficulty scales per wave

### Tournament Mode
- Single-elimination bracket vs CPU
- Win to unlock lore + characters
- Tied to Battle Pass seasonal tournaments

### Future: Online PvP (Phase 2)
- Real-time 1v1 matchmaking
- Unity Gaming Services (UGS) Relay + Lobby
- Rank system: Lizard → Monster → Kaiju → GAWDZILLLLA rank

---

## 9. HUD Layout

### VS Mode HUD
- **Top bar:** P1 health bar (left, green) + P2 health bar (right, red) + round timer (center)
- **Below health bars:** Power meter for each player (yellow fills left→right / right→left)
- **Bottom bar:** Virtual joystick (left) + 4 attack buttons (right) + destruction dollar counter (center)
- UNLEASH button glows red + pulses when power meter is full

### Story/Smash Mode HUD
- Destruction Score replaces opponent health bar
- Military wave countdown at top
- City Destruction % progress bar
- NPC Splat combo counter (floating text)

---

## 10. Audio System

### Localized Power-Up Voice Lines
- 50 MP3 files named `powerup_<city>_<lang>.mp3`
- Each triggers on food power-up breakout scene
- Subtitle system: native script + English translation, 2-second display
- Supports CJK, Arabic (RTL), Devanagari, Latin fonts
- 3 funny variant lines per city (30% random trigger chance)
- Generated via ElevenLabs TTS at launch; swappable via audio upload portal

### Character Audio
- `godzilla_gawdzilla.mp3` — the iconic shout, triggers on Unleash
- All 20 characters have: roar, hit grunt, unleash shout, taunt x3
- Superheroes have spoken English lines ("FOR EARTH!", "KAIJU PROTOCOL INITIATED", etc.)
- Gregg has 20+ blame voice lines + idle quips

### NPC Audio
- 12 randomized splat SFX (picks random on each crush, never repeats twice in a row)
- 6 crowd scream variants for mass-splat events

### Fart Audio
- 4 tiers × 6 SFX types = 24 fart sound files
- Pitch-shifted per character size (kaiju = deeper)
- Gregg fart: small, sad, mid-tier. Always followed by blame line.

### City Music
- 50 city BGM tracks, genre-matched (J-pop, jazz, opera, afrobeats, cumbia, etc.)
- Day/Night variants: night = slower, moodier version

### Audio Upload Portal
- In-editor tool for swapping any audio file by filename
- Live reload — no rebuild required
- Preview playback before saving

---

## 11. NPC System

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
- Unity Particle System per NPC type
- Pixel-art blood sprite sheet (4-frame burst)
- Randomized splatter direction based on stomp/hit angle
- Blood puddle decal stays on ground for 30 sec
- Mass-splat events (5+ simultaneous) trigger screen flash + combo callout

---

## 12. Monetization & Payments

### Payment Infrastructure
- **iOS:** Unity IAP → Apple App Store → Apple Pay at checkout (Apple takes 30%)
- **Android:** Unity IAP → Google Play Store → Google Pay at checkout (Google takes 15-30%)
- **WebGL:** Stripe integration for browser-based purchases
- Unity IAP SDK handles all three with one unified API

### Free Tier (Always)
- Download free
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

### Year 1 Season Calendar
| Season | Theme | New Kaiju | New Cities |
|--------|-------|----------|-----------|
| S1 | Atomic Age 🔥 | Destoroyah | Tokyo Night, Bikini Atoll |
| S2 | Deep Terror 🌊 | (ocean kaiju) | Underwater city stages |
| S3 | Space Invasion 🌌 | SpaceGodzilla | Space station stages |
| S4 | Biollante Rises 🌿 | Biollante | Vine-takeover stages |

### IAP Rules (Non-Negotiable)
- Zero pay-to-win — IAP is cosmetics, characters, sounds only
- No stat boosts, extra health, or power advantages for sale
- All characters earnable through tournament progression (slow) or IAP (fast)

---

## 13. Achievement System

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

## 14. Technical Constraints & Performance Targets

- **Target frame rate:** 60fps on iPhone 12+ / Pixel 5+, 30fps on older devices
- **APK/IPA size:** < 150MB initial download, assets streamed/downloaded post-install
- **NPC pool size:** Max 200 active NPCs on screen at once (object pooling)
- **Particle cap:** 500 active particles max (blood, fart clouds, destruction debris)
- **Building destruction:** Pre-baked collapse animations (not real-time physics) for performance
- **WebGL:** Reduced texture resolution, 30fps target, same gameplay

---

## 15. Implementation Phases

### Phase 1 — Core Game (MVP)
Unity project setup, 3 starter characters (Godzilla, Kong, Ghidorah), 1 city (Tokyo), VS mode, basic HUD, health + power meter, light/heavy/special attacks, Unleash moves, basic NPCs with blood splat

### Phase 2 — Content Expansion
All 20 characters, all 50 cities, food power-up + breakout scene system, fart system, localized audio, story/smash mode, survival mode

### Phase 3 — Polish + Easter Eggs
Gregg easter egg character, achievement system, full audio library (ElevenLabs generated), tournament mode, particle polish

### Phase 4 — Monetization
Unity IAP integration, battle pass system, in-game shop, Stripe for WebGL, save/restore purchases

### Phase 5 — Launch
App Store + Google Play submission, WebGL deploy, analytics, soft launch, bug fixes

### Phase 6 — Online PvP (Post-Launch)
Unity Gaming Services integration, matchmaking, ranked mode

---

*Spec written by Thomas + Claude. Game design approved 2026-06-14.*
