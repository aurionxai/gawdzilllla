# Kaiju Clash — project rules

Single-file vanilla-JS HTML5 Canvas game (`index.html`, **no build step**). Logic in
`levelparse.js` + `progression.js` (CommonJS + browser global, unit-tested). Levels are ASCII
tilemaps (`W1L*_ROWS`) → `buildFromRows` → `LevelParse`.

## Controls — single source of truth (do not bypass)
- ALL key bindings live in the **`CONTROLS`** map in `index.html`. NEVER write a raw
  `keys.has('KeyX')`, `justDn.has(...)`, or inline `wasDown('Key…')`/`isDown('Arrow…')` check.
  Use the action helpers: `isMoveL/isMoveR`, `isJump`, `isDuck`, `isFart`, `pressedBook`,
  `menuConfirm/menuBack/menuLeft/menuRight` (held = `_held(action)`, just-pressed = `_hit(action)`).
- Keys are **context-scoped** (gameplay vs menu). A key MAY mean different things across contexts
  (Z = fart in play, confirm in menus). **THE RULE: a key must not map to two actions within ONE
  context.** Enforced by `_ctlCheck()` (startup `console.warn`) and `test/controls.test.js` (CI).
  Add a key to a context via `_CTL_CTX`.
- When a key triggers a **scene change**, call `justDn.clear()` right after, so the new scene's
  branch doesn't re-read the same press in the same render frame (this caused the "how-to instantly
  skipped" and "B opens+closes the word book" bugs).

## Verify loop — run before saying "done"
- `node loadtest.js` — runs the page top-level with stubbed browser APIs; catches startup crashes
  `node --check` can't (e.g. a `let` used before its declaration = TDZ).
- `node --test test/progression.test.js test/controls.test.js` — 25 tests. **Not** `node --test
  test/` (the directory form mis-globs to 1 failing test).
- `node playtest.js` — headless bot plays all 4 levels (grabs word-gems, beats them), flags
  spawn/death/crash bugs. `node qa-audit.js` — static audio/sprite audit.
- Headless harness uses Playwright at `~/.npm/_npx/9833c18b2d85bc59/node_modules/playwright` with
  chromium `~/Library/Caches/ms-playwright/chromium_headless_shell-1228/.../chrome-headless-shell`;
  **WebKit** (Safari engine) at `webkit-2311/pw_run.sh` for Safari/iOS audio tests. Game globals
  (`scene`, `state`, `mkState`, `keys`, `CONTROLS`, …) are **lexical** — reference them bare in
  `page.evaluate`, not on `window`. Real gestures (`page.mouse.click`) unlock audio; synthetic
  `dispatchEvent` does not.

## Art quality bar — NON-NEGOTIABLE (see memory `kaiju-clash-art-rework`)
Every new in-world asset (heroes, creatures, NPCs, bosses, carriers, food, props that share the
screen with the heroes) must clear all three standards below. The single reference bar is
`../mockups/poppy-growth-FINAL.png` + `lulah-growth-FINAL.png` — when in doubt, hold the new art
next to those and it must look like it belongs in the same set.

- **QUALITY** — full multi-tone shading: ≥3–4 tones per material (highlight → mid → shadow) plus a
  bold dark outline, consistent top-left light source, soft rim light, real volume/anatomy, clean
  readable silhouette. **No flat single-tone fills, no smooth/anti-aliased soft edges, no gradients.**
- **STYLE** — **16-bit SNES pixel art**: crisp hard pixels, vibrant kid-friendly palette, cute
  friendly faces, side / ¾ view to match the heroes. On-model with the cast (Lulah = green body +
  pink/magenta glowing frills + red bow; Poppy = golden ape/Kong, pink flower, rosy cheeks).
- **RESOLUTION** — transparent-background PNG exported at native pixel-art res (never an
  upscaled/blurred big image). Size to the cast: **heroes/carriers ≈128 px tall** (fit a 128×128
  box), **enemies ≈96–110 px tall**, **NPCs ≈96 px tall**, width proportional. Multi-frame actions
  (idle/walk/jump, or a flap) ship as separate same-size frames.

**Pipeline:** produced ONLY via **Higgsfield `nano_banana_pro`**, importing the existing hero
sprites as on-model reference (see `../mockups/README.md`, ~2 credits/1K image). **User-driven** —
Claude writes the on-model prompt + supplies the reference sheet; the USER runs Higgsfield and drops
the PNG back.

**NEVER ship procedural / vector / flat single-tone canvas (`ctx`) drawings as FINAL art** — the
Riot-Mecha boss and the carry-crane are flagged temporary placeholders only; replace before any art
is called "done". New art lands under the right folder (`skins/`, `enemies/`, `npcs/`, `backdrops/`),
loaded via the sprite loader, drawn with `imageSmoothingEnabled=false`, and **bump `ASSET_VER`**.
When real art replaces a placeholder, DELETE the placeholder code/asset (memory
`delete-old-art-on-replace`).

## Deploy & cache (see memory `kaiju-clash-deploy`)
- Push to `main` = auto-deploy (GitHub Pages + **kaijukids.co**), ~1 min.
- **BUMP `BUILD` + `version.txt` (keep them equal) on EVERY deploy** — drives the stale-page
  auto-reload (`fetch('version.txt')` → reload if older).
- **BUMP `ASSET_VER` ONLY when an asset (sound/sprite/bg) changes** — busts just those URLs, so
  code deploys don't force re-downloading all audio.

## Audio (see memory `kaiju-clash-language-learning`)
- Everything is a real sample via `playSample(name, vol, when, force)` → `_sfxBus`; music on
  `_musicBus` which connects AFTER the compressor (so loud SFX don't pump the music). `force`
  bypasses the per-sound throttle + voice cap (word-book replays).
- iOS Safari silences Web Audio under the ring switch — a silent looping `<audio>` (`sounds/silent.mp3`)
  on first gesture keeps the session alive. `unlockAudio` runs its dance ONCE; don't move `stopMusic()`
  outside that guard (it restarted music on every keypress = the "321 re-loop").
