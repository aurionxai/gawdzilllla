# World 3 → Underwater Swim Caves — design

**Goal:** Turn World 3's three explorable levels into buoyancy-swim cave levels with a strong
*dive-deep / surge-up* rhythm. Boss arena (W3L4) stays a solid-floor stomp fight.

## Mechanic — buoyancy swim (`level.swim`)
In `updatePlayer`, when `s.level.swim`:
- Hold ⬆ (jump action) → upward thrust, `vy → max(-3.6, vy-0.55)`.
- Idle → slow drift down, `vy → min(vy+0.10, 1.8)` (never a fall).
- Hold ⬇ (duck action) → sink faster (full vertical control).
- Resting on sand floor still sets `onGround`. Spikes (`^` = sea urchin) still damage.
- Skip the "fell below map = death" check (caves are fully enclosed).
- `*` updraft stays as an express up-current; bubble visuals unchanged.

## Terrain look
`T_SOLID` gets a warm **sand** palette + pebble/shell speckles + faint depth-blue overlay when
`level.swim`, as a third branch beside `neon`. Tiles remain ctx-drawn (art bar covers
creatures/heroes, not terrain).

## Levels (gems on the main swim path, bot-reachable; corridors ≥3 tiles open)
- **W3L1 Sunken Streets** — wide sinuous horizontal cavern; channel plunges to deep basins and
  rises through chimneys ~3 times. Intro-gentle (corridor ~5–6 tiles tall). 2 gems at dive bottoms.
- **W3L2 Coral Ruins** — open-water chambers linked by short tunnels; sharper vertical swings.
- **W3L3 Kelp Tower** — tall vertical shaft you swim **up** (safe now — swim makes vertical
  navigable, the thing `*` couldn't do).
- **W3L4 Mecha-Kraken** — unchanged solid-floor arena (tuned stomp fight; deliberate exception).

The big vertical range = taller levels (LH ~20–30 rows); the camera's vertical follow handles it.

## Bot (`playtest.js`)
`level.swim` branch: hold `ArrowUp` while target is above, release / `ArrowDown` to descend, bob up
on wall-ahead. Beeline-x + vertical-thrust through wide gentle corridors.

## Authoring
Generate ROWS from a **centerline map** (col → desired channel-center row) carved through solid
sand via a scratchpad script; paste static string arrays into `index.html`. Matches the
heightmap-authoring philosophy.

## Verify
`node loadtest.js` → `node --test test/progression.test.js test/controls.test.js` →
`node playtest.js` (must WIN all swim levels). Bump `BUILD` + `version.txt`. No `ASSET_VER` bump
(sand is ctx-drawn; no asset URLs change).
