# 16-Bit Sprite Upgrade — Design Spec

**Date:** 2026-06-19
**Status:** Approved

---

## Goal

Replace all four procedurally-drawn characters in KAIJU CHOMP with SNES-style pre-rendered pixel art sprites, matching the Donkey Kong Country (right-panel) aesthetic: multi-shade color depth, dithered gradients, dark pixel outlines.

---

## Style Formula

Every sprite generation embeds this formula verbatim for cross-character consistency:

> *SNES pre-rendered pixel art, 16-bit, Donkey Kong Country style, transparent background, single character centered, rich multi-shade color depth with dithered gradients, dark pixel outline, game sprite, no background, no shadow*

### Per-character palettes

| Character | Primary | Secondary | Accent |
|---|---|---|---|
| Doza (kaiju) | Deep navy/teal scales | Cream belly | Glowing green dorsal spines |
| Kong (gorilla) | Dark brown fur | Tan chest | Black face, warm highlights |
| Soldier | Olive drab uniform | Tan skin | Black boots/helmet |
| Tank | Steel grey hull | Dark treads | Rust accent |

---

## Sprite Manifest

### Kaijus — full walk cycle

| Key | Frames | Size |
|---|---|---|
| `doza_walk_1..4` | 4-frame walk cycle | 48×64 px |
| `doza_idle` | 1 frame | 48×64 px |
| `doza_jump` | 1 frame | 48×64 px |
| `doza_eat_1..2` | 2 frames (mouth open/chomp) | 48×64 px |
| `doza_fart_1..2` | 2 frames (spines glow, butt cloud) | 48×64 px |
| `kong_walk_1..4` | 4-frame walk cycle | 48×64 px |
| `kong_idle` | 1 frame | 48×64 px |
| `kong_jump` | 1 frame | 48×64 px |
| `kong_eat_1..2` | 2 frames | 48×64 px |
| `kong_fart_1..2` | 2 frames | 48×64 px |

**Subtotal: 20 sprites**

### Enemies — key poses only

| Key | Frames | Size |
|---|---|---|
| `soldier_walk` | 1 frame | 32×48 px |
| `soldier_stun` | 1 frame | 32×48 px |
| `soldier_dead` | 1 frame | 32×48 px |
| `tank_idle` | 1 frame | 40×40 px |
| `tank_stun` | 1 frame | 40×40 px |
| `tank_dead` | 1 frame | 40×40 px |

**Subtotal: 6 sprites**

**Grand total: 26 sprite generations** via Higgsfield `generate_image` (nano_banana_pro, transparent PNG).

All sprites face right. Left-facing handled in code via `ctx.scale(-1, 1)` around the draw call.

---

## Code Architecture

Three targeted changes to `index.html`. Physics, collision, audio, HUD, level data — untouched.

### 1. `SPRITES` constant

```js
const SPRITES = {
  doza_idle: "https://...",
  doza_walk_1: "https://...",
  // ... all 26 entries
};
```

Flat object, state-key → CDN URL. Structured for skin-swappability: swapping a skin is a data change, not a code change.

### 2. `loadSprites()`

Called once at startup before the game loop begins. `Promise.all` over all 26 entries; each creates an `HTMLImageElement` and resolves on `onload`. While loading, canvas renders a simple loading screen (black background, "LOADING… N/26" progress text in the game font). On completion, the game loop starts normally.

### 3. Replaced draw functions

`drawDoza`, `drawKong`, `drawSoldier`, `drawTank` each become thin sprite dispatchers:

```js
function drawDoza(x, y, pl, tick) {
  const key = spriteKey('doza', pl, tick);   // picks walk_1..4, idle, jump, etc.
  const img = loadedSprites[key];
  const W = 48, H = 64;
  ctx.save();
  if (pl.dir < 0) { ctx.scale(-1, 1); x = -x - W; }  // flip for left
  ctx.drawImage(img, ~~x, ~~y, W, H);
  ctx.restore();
}
```

Walk cycle advances via `Math.floor(tick / 8) % 4`. Hitbox dimensions remain identical to current values so no physics changes.

---

## Future: AI-Generated Skins (Phase 2)

The character select screen will allow users to generate their own custom skins via AI (Higgsfield). A user provides a text prompt (e.g. "Doza but on fire, lava armor") and the game generates a replacement sprite set in the same SNES style formula. Generated skin URLs replace the defaults in `SPRITES` for that session.

The flat `SPRITES` constant is the designed extension point for this — no code changes needed to swap skins, only data.

> **Note:** Character select screen UI redesign accompanies the skins feature in Phase 2.

---

## Out of Scope (This Phase)

- Skin selection UI
- Skin persistence across sessions
- More than 26 sprite generations
- Changes to physics, audio, HUD, or level data
