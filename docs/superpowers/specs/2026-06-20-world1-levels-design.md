# World 1 — Levels with Real Depth (Design)

**Date:** 2026-06-20
**Status:** Approved direction (vertical-scroll variant), pending spec review
**Builds on:** the merged progression spine (`LEVEL_BUILDERS`, `Progression.LEVELS`, overworld) and the World-1 day backdrop. Replaces the single flat `buildLevel()` strip with deep, vertically-scrolling, themed levels.

---

## 1. Goal

Turn World 1 from one flat 110-tile lane into **four deep, escalating levels** that *play* like a real platformer — layered routes (street → rooftops → sky), gaps, hazards, vertical climbs — ending in the **Riot Mecha boss**. The foreground reads as Tokyo (themed tiles), over the existing parallax day backdrop.

This spec covers the **level system** (format + camera + themed tiles + hazards) and **World 1's content** (`w1l1`–`w1l4` + boss). Worlds 2–4 reuse the same system later (their own tilemaps + mechanics).

## 2. Level format — ASCII tilemaps (variable width AND height)

Each level is authored as an array of text rows; each character is a tile. Levels may be **taller than the screen** (the source of vertical depth) and any width.

```
LEGEND
  ' ' air        '#' solid ground/building   '=' one-way rooftop platform
  'x' destructible crate    '^' spike hazard   '~' (reserved: lava, world 4)
  'o' food (random type)    's' slime  'w' whelp  't' tinbot   (enemy by letter)
  'C' citizen (random townsfolk)   'P' player spawn   'E' exit portal
```

A level is `{ id, name, rows: [ "....", ... ] }`. A parser converts `rows` into:
- a tile grid `tiles[r][c]` (air/solid/platform/destructible/hazard),
- spawn lists (food / enemies / citizens) from their letters at tile centers,
- the player spawn (`P`) and exit (`E`) positions,
- level dimensions `LW = max row length`, `LH = rows.length` (now **per-level**, not the fixed global 11).

`LEVEL_BUILDERS[id]` returns the parsed level. Authoring/editing a level = editing its text block. A tiny `parseLevel(rows)` function is the one new unit; it has one job and is unit-testable (chars → tiles + spawns).

## 3. Camera — two-axis follow + clamp

Today `cam.y` is always 0. This spec wires vertical scrolling:
- `cam` follows the player on **both axes**, each eased, then clamped to the level: `cam.x ∈ [0, LW*TS - VW]`, `cam.y ∈ [0, LH*TS - VH]`.
- **Every draw that currently subtracts `cam.x` must also subtract `cam.y`** (tiles, entities, food, citizens, fart cloud, HUD stays screen-fixed). This is the main integration cost — a mechanical sweep, but it touches several draw functions.
- The backdrop gets gentle **vertical parallax** too (drifts up slightly as you climb) so sky shows up top.
- `LH`/`LW` become per-level values read from `state.level` instead of global constants; physics/tile helpers take them as parameters (they already receive `tiles`).

## 4. Tiles & themed Tokyo rendering

- New tile type **hazard** (`T_HAZARD`): touching it damages the player (same hit path as enemy contact, with i-frames). Spikes in World 1.
- `drawTiles` upgraded so World-1 tiles look like **Tokyo**: solids as building/ledge blocks with edge highlights, one-way platforms as **rooftop slabs / neon-sign beams**, crates as wooden boxes, spikes as metal spikes — not flat colored rectangles. Tile art is procedural (drawn per tile by type + world), keeping it light; it reads against the backdrop.

## 5. The four World-1 levels (escalating arc)

| Level | Name | Feel | New thing |
|---|---|---|---|
| `w1l1` | Tokyo Streets | Intro — ground + low rooftops, teach stomp + save | gentle verticality |
| `w1l2` | Rooftop Run | Climb to the rooftops, real gaps, one-way platforms | vertical routes |
| `w1l3` | Tower Climb | Tall level, spikes, denser enemies, up-and-over | hazards + height |
| `w1l4` | Riot Mecha | Boss arena | the boss |

Each is a hand-authored tilemap. Difficulty rises via height, gap width, hazard count, enemy density. All four flip `playable: true` in `Progression.LEVELS` and unlock in sequence (the spine already supports this).

## 6. Riot Mecha boss (`w1l4`)

A large enemy with its own HP bar and a simple, readable pattern: it **telegraphs** a stomp (wind-up flash), slams (screen shake + shockwave the player must jump), then exposes a **weak point** (head/cockpit) the player stomps. Repeat; 3–4 hits to defeat. Reuses the enemy hit/stun/flash systems plus a small boss state machine (`telegraph → slam → vulnerable → defeated`). Its sprite comes from the asset pipeline (a clean Riot Mecha sheet → sliced). Victory on the boss completes World 1.

## 7. Build order (incremental, screenshot each)

1. **Level system foundation** — `parseLevel`, two-axis camera + `cam.y` render sweep, per-level `LW/LH`, hazard tile, themed Tokyo `drawTiles`; **rebuild `w1l1` as a deep tilemap**. Prove it visually (climb the rooftops). *(This is the first shippable chunk.)*
2. **`w1l2` + `w1l3`** — author the two tilemaps using the system.
3. **Riot Mecha boss** — boss state machine + sprite + `w1l4` arena.

Each chunk is its own plan → build → verify, merged before the next. Chunk 1 proves the depth.

## 8. Out of scope (here)

- Worlds 2–4 level content and their special mechanics (swim, lava-climb) — later specs reusing this system.
- Moving platforms, checkpoints mid-level, branching exits — possible later, not needed for World 1.
- A visual level editor — the ASCII format is hand-edited for now.
