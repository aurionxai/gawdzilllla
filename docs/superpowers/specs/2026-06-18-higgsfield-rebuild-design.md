# GAWDZILLLLA — Higgsfield Rebuild Design Spec

**Date:** 2026-06-18
**Platform:** Higgsfield Games (via Claude Code + Higgsfield MCP)
**Approach:** Staged prompt series (Option B — 4 stages, verify before advancing)
**Status:** Approved for implementation

---

## 1. Overview

A 2.5D pixel-art first-person kaiju game rebuilt on Higgsfield Games. You play inside a hero kaiju defending cities against invading titans — clawed hands visible at screen corners, city skyline at eye level, chunky 16-bit pixel aesthetic. This is a rebuild that blends the original GAWDZILLLLA 2D fighter's content depth (city-specific food power-ups, localized audio, fart tiers, Gregg easter egg) with the FPS Defender concept (kaiju as hero, civilians as allies, titans as enemy).

**Tagline:** *Choose your kaiju. Defend the city. Blame Gregg.*

### What changes from the Love2D version
- Perspective: side-scroller → first-person 2.5D
- Role: city-destroyer → city-defender (hero kaiju)
- Platform: Love2D/Lua/Docker → Higgsfield-generated browser game with live link
- Multiplayer: local split-screen → online PvP + online co-op via Higgsfield lobbies

### What carries over
- City-specific food power-ups with localized voice lines (exact cities/foods/languages from original spec)
- Funny audio variant system (30% chance per food pickup)
- Fart tier system (Tier 1–4, cuisine-determined)
- Gregg easter egg (invincible, steals food, blames titans)
- All fart SFX types and blame voice lines
- Power meter system
- Military trust mechanic (fires at you 30 sec → becomes ally)

---

## 2. Game Identity & Aesthetic

Style brief used across all Higgsfield prompts:

> 2.5D pixel-art first-person kaiju game. Chunky 16-bit pixel art, DOOM-era sprite scaling. Camera: first-person with slight head-bob. Minimal HUD — dorsal-spine power bar (bottom center), health bar (top left). Dark navy sky, neon-lit city streets. Cities feel dense and destructible — buildings crack, civilians scatter, military tanks roll in waves.

**Character palettes:**
- GAWDZILLA: deep navy + amber + radioactive green (dorsal spines glow brighter as power fills)
- KONG: earthy brown + gold
- MOTHRA: iridescent white + violet

**Tone:** Deliberately absurd. Food power-ups trigger 2-second restaurant cinema cutscenes with native-language voice lines. Farts are a game mechanic. Gregg is invincible and steals your food. Pixel art keeps it chaotic without being grimdark.

**Genre tag for Higgsfield:** *First-person action brawler, pixel-art 2.5D, city defense, multiplayer.*

---

## 3. MVP Scope

### Playable Kaiju (3)
| Kaiju | Ranged | Melee | Special | Passive |
|-------|--------|-------|---------|---------|
| GAWDZILLA | Atomic Breath (hold to sustain, spines glow) | Claw swipe 3-hit combo | Dorsal Pulse (AoE shockwave) | Nuclear Surge — higher power = stronger breath |
| KONG | Throw Debris (rip chunk from wrecked building) | Ground Slam | Roar Shockwave (staggers titans + stuns jets) | Redirect Rubble — catches debris away from civilians |
| MOTHRA | Divine Beam (auto-targets Monarch weak spots) | Wing Buffet | Silk Bind (immobilizes titan 5 sec) | Revive Aura (slow-heals nearby civilians) |

### Cities (3)
| City | Landmark cues | Food Power-Up | Voice Line | Fart Tier |
|------|--------------|---------------|------------|-----------|
| Tokyo | Tokyo Tower silhouette, Shinjuku neon kanji signage | 🍢 Yakitori | やきとり！パワーアップ！(JP) | 1 — Polite Puff |
| New York | Times Square LED billboards, Statue of Liberty silhouette | 🍔 Burger | BURGER! Oh yeah baby! (EN-NYC) | 2 — Rumblerino |
| Seoul | Lotte Tower skyline, Han River bridge, Korean signage | 🥩 Korean BBQ | 삼겹살! 먹자! (KR) | 4 — Apocalypse |

### Enemy Titans (MVP)
- **King Ghidorah** — gravity beam ranged, three-head lunge melee, aerial threat
- **MUTOs** (co-op mode) — swarm tactics, EMP pulse disables power meter briefly

### Game Modes (2)
- **Solo Defender** — 1 player, protect city, defeat titan, earn S-rank
- **Online PvP** — 2 players kaiju vs kaiju, 3 rounds, health bars, any city
- **Online Co-op** — 2 players defending same city together, harder titan variant

---

## 4. Power-Up System

### Standard Power-Ups (frequent)
Drop from every 3rd titan hit or destroyed enemy structure. Instant pickup, no cutscene, glow on ground.

| Power-Up | Effect | Duration |
|----------|--------|----------|
| ⚡ Rage Surge | +50% ranged attack power | 10 sec |
| 🛡 Armor Shell | 50% damage resistance | 8 sec |
| 💨 Speed Burst | 2× movement speed | 8 sec |
| ☢️ Power Charge | Full power meter instantly | — |
| 💊 Regen | Restore 20% HP | — |

### Food Power-Ups (rare — earned by play)
Trigger: successfully evacuate a city block (move all civilians out of titan's attack path). 1–2 per city stage.

**Flow:**
1. Glowing food icon appears in evacuated zone
2. Player walks into it → 2-second pixel cinema cutscene at city's signature restaurant
3. Native-language voice line fires + subtitle (native script + English)
4. 30% chance: funny variant line fires instead
5. Power effect activates (bigger than any standard power-up)
6. After 3 seconds: fart aftermath fires per city tier

**Gregg interference:** 30% chance Gregg sprints in from off-screen and eats the food before the player reaches it. Gregg farts. Gregg blames the nearest titan. Gregg walks away.

---

## 5. City-Specific Food & Audio System

Carried over exactly from original spec. Each city has:
- 1 signature food with exact native-language voice line
- 3 funny variant voice lines (30% random trigger)
- Fart tier determined by cuisine type

### MVP City Details

**Tokyo — Yakitori**
- Primary: やきとり！パワーアップ！(JP)
- Funny variants (JP, 30% random): absurd exaggeration of how good yakitori is
- Fart Tier 1 (Polite Puff): small green cloud, Ghidorah hiccups, NPCs sneeze, 3 sec
- Power effect: Rage Surge (large)

**New York — Burger**
- Primary: BURGER! Oh yeah baby! (EN-NYC)
- Funny variants (EN-NYC, 30% random): NYC attitude, complaining the burger is too small for a kaiju
- Fart Tier 2 (Rumblerino): buildings crack, grease slick on ground, titan stumbles, 8 sec
- Power effect: Armor Shell (large) + Rage Surge

**Seoul — Korean BBQ**
- Primary: 삼겹살! 먹자! (KR)
- Funny variants (KR, 30% random): absurd BBQ enthusiasm
- Fart Tier 4 (Apocalypse): sky turns green 20 sec, nearby titan minions stagger, Gawdzilla looks genuinely shocked at himself, -30% damage to active titan
- **Defender context adjustment:** "all NPCs splat" from original spec becomes "all nearby enemy titan minions stagger and scatter" — civilians are allies and sprint to safety
- Power effect: Full meter + all stats boosted 20 sec

### Fart Tiers Reference
| Tier | Name | Effect |
|------|------|--------|
| 1 | Polite Puff | Small cloud, NPCs sneeze, titan hiccups, 3 sec |
| 2 | Rumblerino | Buildings crack, grease slick, titan stumbles, 8 sec |
| 3 | Biohazard | 15-sec toxic fog, titan BURN + BLIND |
| 4 | Apocalypse Fart | Sky turns green, titan minions stagger, 20+ sec |

### Gregg's Blame Lines (titan context)
- Ghidorah: *"That three-headed thing right there. I saw him."*
- MUTOs: *"The swarm. It's always the swarm. Nobody talks about it."*
- Generic titan: *"That big one. Exhaust leak. Engineering issue."*
- Alone: *"...There was something here. It left."*

---

## 6. Defender Mechanics

### Win Conditions (per city)
| Condition | Threshold | S-Rank requires |
|-----------|-----------|-----------------|
| Defeat the invading titan | Required | — |
| City integrity (buildings standing) | > 50% | > 80% |
| Civilian casualties | Below threshold | Zero losses |
| Speed clear | Bonus | — |

S-Rank on all three → completion screen → food power-up cinema fires as reward sequence.

### Military Trust System
- Military jets/tanks fire on you for the first 30 seconds (mistaken identity)
- Do NOT retaliate — survive their fire
- After 30 sec: trust event triggers, military switches to ally
- Allies: jets mark titan weak spots with glowing overlay, tanks provide covering fire, soldiers evacuate civilians faster

### Titan Damage States
Titans show visible diminishment as HP drops: cracked scales, limping, slower attacks, dimmer eyes. At 20% HP: FINISH window opens → signature takedown animation per kaiju:
- GAWDZILLA: full atomic breath sustained beam into titan's chest — nuclear explosion, titan disintegrates
- KONG: grabs titan's head(s), slams into city block (non-civilian zone), roar
- MOTHRA: silk-binds all titan limbs, divine beam point-blank, titan dissolves in light

---

## 7. Multiplayer

### Online PvP
- 2 players, each chooses a kaiju from the MVP roster
- 3 rounds, health bars, city-choice from any of the 3 MVP cities
- Food power-ups active for both players — first to reach it gets it
- Gregg spawns and is chaotic for both

### Online Co-op Defender
- 2 players as different kaiju defending the same city together
- Titan variant: higher HP, larger AoE attacks, additional minion waves
- Shared city integrity bar — both players' actions affect it
- If one player goes down, the other can revive them with a 5-sec animation

### Lobby
- Host shares one Higgsfield link
- Guest joins → lobby screen: choose mode (PvP or Co-op), pick kaiju, pick city
- State sync: both see same titan HP, same building damage, same Gregg position

---

## 8. MCP Setup & Execution Plan

### One-Time Setup
```bash
claude mcp add --transport http --scope user higgsfield https://mcp.higgsfield.ai/mcp
```
Opens browser OAuth → sign into Higgsfield → approve → Fable 5 game generation tools appear in Claude Code session.

### Stage Execution
Each stage is run as an MCP call from Claude Code. Verify the live Higgsfield link before advancing to the next stage.

See prompt files in `docs/superpowers/specs/higgsfield-prompts/`:
- `stage1-foundation.md` — 2.5D FPS engine + Gawdzilla + Tokyo + core combat
- `stage2-food-fart.md` — food power-up system + yakitori audio + fart tiers + standard pickups
- `stage3-full-mvp.md` — Kong + Mothra + NYC + Seoul + Gregg + all audio + S-rank screen
- `stage4-multiplayer.md` — PvP mode + co-op mode + lobby + state sync

### Verification Checkpoints
| After Stage | Check |
|-------------|-------|
| 1 | 2.5D FPS feel, Tokyo landmark recognizability, Gawdzilla combat responsiveness |
| 2 | Food pacing (rare/earned), cinema cutscene 2-sec length, Yakitori audio fires correctly |
| 3 | All 3 cities distinct, Gregg spawns + steals + blames, Tier 4 Seoul sky effect |
| 4 | Lobby link works, both modes selectable, state sync verified in co-op |

---

## 9. Out of Scope for This Build

- Cities beyond Tokyo, NYC, Seoul (full 50-city expansion = Phase 2)
- Kaiju beyond Gawdzilla, Kong, Mothra (full roster = Phase 2)
- Evolution tree / stat progression (FPS Defender spec §Evolution Tree — deferred)
- Stripe IAP / battle pass (deferred)
- Survival mode / tournament mode (deferred)
- Fart tiers 3 (Biohazard) — only Tiers 1, 2, 4 in MVP cities

---

*Spec written by Thomas + Claude. Approved 2026-06-18. Supersedes the FPS Defender spec (2026-06-15) for Higgsfield platform work; original Love2D spec (2026-06-14) remains reference for content (foods, cities, audio, Gregg).*
