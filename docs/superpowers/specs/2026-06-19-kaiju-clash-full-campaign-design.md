# Kaiju Clash — Full Campaign Design

**Date:** 2026-06-19
**Status:** Approved structure, pending spec review
**Audience:** Recreational gamers and kids 8+
**Current state:** One playable level ("Tokyo City, Level 1") — a 110-tile horizontal
side-scroller (LÖVE/HTML build, deployed on Higgsfield). Player (Lulah/Poppy) stomps
enemies, saves 8 citizens, collects food to charge a fart special. No progression,
overworld, bosses, or ending yet.

---

## 1. Goal

Turn the existing single-level vertical slice into a **finishable campaign** that an
8-year-old can complete in a few sittings, with replay hooks for recreational players.

**North star:** 15 levels, 4 distinct worlds, 4 bosses, an overworld map, and a real ending.

**Build strategy:** Lock the whole map on paper (this doc), then build incrementally
**World 1 first**. Each world is a self-contained chunk that gets its own implementation plan.

---

## 2. Campaign structure

The whole game runs on one rhythm. Every world = **4 beats**:
*introduce a mechanic → develop it → twist it → boss who tests it.*

| World | Levels | Palette / time | Signature mechanic | Boss |
|---|---|---|---|---|
| **1 · Tokyo City** | 1–4 | Bright day, blue sky | Core movement, **stomp**, chomp, save citizens, food→fart | **Riot Mecha** (prototype walker) |
| **2 · Neon Shibuya** | 5–8 | Night, neon / magenta | **Light & dark** — crosswalk timing, blackout zones lit by fart-glow, electric rails | **Giant Mecha** |
| **3 · Sunken City** | 9–12 | Teal / blue, god-rays | **Swim physics** — buoyant float-jump, air-bubble oxygen timer, currents | **Mecha-Kraken** |
| **4 · Volcano Skyline** | 13–15 | Orange / red, ash sky | **Vertical climb** — rising lava, crumbling platforms, ascend instead of run right | **Rival Kaiju** (final, 3 phases) |

**Difficulty / novelty curve:** land mastery (W1) → same physics + sensory twist (W2) →
*physics changes entirely* underwater (W3, the mid-game "new game" spike) → vertical
finale that recombines everything (W4).

Total: **15 levels · 4 game-feels · 4 bosses.**

---

## 3. World detail

### World 1 — Tokyo City (Levels 1–4)
The tutorial world. Reuses and polishes the existing level.
- **L1:** Pure movement + stomp + save citizens (current level, refined).
- **L2:** Introduce food→fart special as a crowd-clear tool.
- **L3:** Twist — platforming verticality, destructible tiles, denser enemies.
- **L4 (Boss):** Riot Mecha — a walker that telegraphs stomps; player stomps its head 3×.

### World 2 — Neon Shibuya (Levels 5–8)
Night city. Mechanic: **light & dark**.
- Crosswalk timing puzzles (cross when the signal allows; traffic is a hazard).
- Blackout zones where only the player's fart-glow / neon signs reveal platforms.
- Electric rails as touch-hazards.
- **L8 (Boss):** Giant Mecha (already on roadmap).

### World 3 — Sunken City (Levels 9–12) — UNDERWATER, the centerpiece
Half-submerged, flooded Tokyo. Mechanic: **swim physics**.
- **Buoyant movement:** jump becomes a float-up; falling is a slow sink. Up/Space swims up.
- **Air bubbles:** an oxygen meter slowly drains underwater; collect rising bubbles to refill.
  Kid-readable urgency without a punishing death timer (oxygen-out = pushed to surface / lose a life slowly, not instant death — exact penalty TBD in W3 plan, default: slow HP drain).
- **Currents:** directional flows act as moving conveyors — used for traversal and puzzles.
- **New rescue flavor:** drowning citizens clinging to debris.
- **Backdrop:** sunken skyscrapers, light shafts (god-rays), schools of fish.
- **L12 (Boss):** Mecha-Kraken — tentacle-arena fight using currents and bubbles.

### World 4 — Volcano Skyline (Levels 13–15)
The finale. Mechanic: **vertical climb**.
- Camera/level ascends; rising lava is a soft "keep moving up" pressure.
- Crumbling platforms, falling debris.
- Recombines stomp + special + timing from earlier worlds.
- **L15 (Boss):** Rival Kaiju — 3-phase final fight, the emotional climax.

---

## 4. Meta layer (what makes it a game, not a toy)

- **Overworld map:** kids walk Lulah world-to-world; the visible progress spine.
- **Per-level scoring:** letter rank S/A/B/C (time + citizens + style) and a
  "saved all citizens" star. Replay hooks.
- **Character unlock:** finishing the campaign unlocks a 3rd playable kaiju.
- **Ending:** a payoff screen / short sequence after the Rival Kaiju.

---

## 5. Aesthetic direction

Push **world-level color identity** so the overworld reads as a journey and kids navigate
by palette and silhouette before they read text:

- W1 Bright day → W2 Neon night → W3 Teal underwater → W4 Orange/ash finale.

Keep the current strengths: cute-destructive kaiju, neon Tokyo, citizen-rescue heart.
Each world needs a distinct skyline silhouette and one signature backdrop "hero" element
(Tokyo Tower / Shibuya crossing / sunken skyscraper / erupting volcano).

---

## 6. Out of scope (YAGNI for now)

- Multiplayer / online.
- Level editor.
- A 5th world (only if W1–W4 land well).
- Monetization / IAP.

---

## 7. Build order (each is its own spec → plan → implementation cycle)

1. **Progression spine first** — world/level select + level loader + win/rank screen,
   so levels can be data-driven and the campaign has a skeleton.
2. **World 1 (4 levels + Riot Mecha boss)** — proves the per-world rhythm end to end.
3. **World 2 — Neon Shibuya** (light/dark mechanic).
4. **World 3 — Sunken City** (swim physics — the centerpiece; biggest new-mechanic risk).
5. **World 4 — Volcano Skyline** (vertical climb + final boss + ending).

World 1 + the progression spine is the first shippable milestone.
