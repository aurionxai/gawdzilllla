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
