# Kaiju Clash — project rules

Single-file vanilla-JS HTML5 Canvas game (`index.html`, **no build step**). Logic in
`levelparse.js` + `progression.js` (CommonJS + browser global, unit-tested). Levels are ASCII
tilemaps (`W1L*_ROWS`/`W2L*_ROWS`) → `buildFromRows` → `LevelParse`. Tile chars: `#`solid `=`one-way
`x`destructible `^`spikes `~`**shock floor** (W2 — standable, zaps while live; `_shockState()`); spawn
chars `P E D C o g` + enemies `s w t`(W1) `n h d k p z`(W2 neon). Worlds gate via `Progression`
(world N order-1 unlocks once world N-1's last level is beaten). Bosses: `BOSS_CFG`/`mkBoss(type)` →
`<frames>_<state>` sprites in `bosses/` (riot, giant). Add a level: rows → `LEVEL_BUILDERS` +
`LEVEL_PAR` + `Progression.LEVELS` + (vocab) `WORLD_VOCAB[world]`. `playtest.js` LEVELS array.
**Level terrain must ROLL (Mario/Alex-Kidd), not be flat** — vary the ground height (stairs, plateaus,
valleys, hills) + pits/gaps; rooftop levels = buildings at varying heights with street gaps. Build
from a HEIGHTMAP (surface-row per column) → fill `#` downward; keep steps gentle and pits ≤2–3 tiles
so the playtest bot (and kids) clear them; gems/enemies sit on the local surface (`surfaceRow-1`).

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
- **GROWTH SIZES follow the sheets, not guesses** — `GROWTH_SCALE` must track the stage proportions
  in `../mockups/lulah-growth-FINAL.png` (measured 1 : 1.32 : 1.70 : 2.14 : 2.91). Baby stays under the
  ~40px city creatures; the collision box stays a fixed 44×66 at every stage (shrinking it broke the
  rooftop-gap physics) — only the SPRITE scales. Enemies render fixed-size so a grown kaiju towers.
- **RESOLUTION** — transparent-background PNG exported at native pixel-art res (never an
  upscaled/blurred big image). Size to the cast: **heroes/carriers ≈128 px tall** (fit a 128×128
  box), **enemies ≈96–110 px tall**, **NPCs ≈96 px tall**, width proportional. Multi-frame actions
  (idle/walk/jump, or a flap) ship as separate same-size frames.

**Pipeline = the Higgsfield MCP** (auth once per session: `/mcp → higgsfield`; tools are
`mcp__higgsfield__*`). Claude DRIVES it — don't hand-roll `ctx` art and don't use the REST/Cloud API.
Flow that works: `generate_image` model `nano_banana_pro` (count ≤4, plain flat bg for a clean cut) →
pick best → re-`generate_image` passing the chosen `job_id` in `medias:[{role:'image',value:JOBID}]`
for consistent extra frames → `remove_background` (media_type image) → `job_status(sync:true)` for the
transparent PNG URL → curl + `sips -z N N` into the game folder. **Credit gotcha:** Higgsfield web/MCP
credits ≠ Cloud/API credits — the MCP uses the credited web account; the platform.higgsfield.ai REST
API + the Railway `tools/higgsfield-gen.mjs` route is a separate empty pool, ignore it. The carrier
crane (`skins/crane/crane_{up,mid,down}.png`) was built this way.

**NEVER ship procedural / vector / flat single-tone canvas (`ctx`) drawings as FINAL art.** As of
BUILD 20 there are **no art placeholders left** — heroes, enemies, NPCs, food, backdrops, the carrier
crane, and the **Riot-Mecha boss** (`bosses/riot_{idle,windup,slam,defeat}.png`, loaded by `loadBoss`/
`BOSS_FRAMES`, drawn per boss state with the code FX — hit-flash/shockwaves/defeat-collapse — layered
over the sprite) are all real Higgsfield pixel art. Keep it that way: new art lands under the right
folder (`skins/`, `enemies/`, `npcs/`, `backdrops/`, `bosses/`), drawn `imageSmoothingEnabled=false`
(hi-res sprites downscaled at runtime use `true`), and **bump `ASSET_VER`**. Replacing any future
stand-in → DELETE the placeholder code/asset (memory `delete-old-art-on-replace`).

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
- Audio-engineer brief (the bar for any new SFX/music): `sounds/AUDIO-SPEC-FOR-ENGINEER.md`.

## Leaderboard + language quiz (see memory `kaiju-clash-leaderboard`)
- Backend is in the user's **Railway** account (project `kaiju-leaderboard`): Postgres + a Node API at
  `https://kaiju-api-production.up.railway.app` (source `leaderboard-api/`). Deploy with the Railway
  **CLI** (`railway up --service kaiju-api`) — the Railway **MCP** returns Unauthorized here; use the CLI.
  Writes gated by a per-player **secret**; tables read-only to the public; **CORS = exact-match** allowlist
  (kaijukids.co + aurionxai.github.io — no `startsWith`).
- Two boards: **🏁 Speedrun** (per-level best ms, Global/Friends) + **🎓 Proficiency** (quiz mastery
  points, NOT words-seen). Identity = username + 6-char friend code in `localStorage['kaiju_lb']`;
  **COPPA-safe** (no email/PII). Client `_lb*` fns + `drawLeaderboard`; **🏆 Ranks** button on the
  overworld; HTML overlay `#lbov` for text entry. All calls no-op gracefully offline.
- **Quiz** (`scene='quiz'`, `_quiz*` fns): 4-option multiple-choice, mixed listen/read/recall, pool =
  `meta.learned` (needs ≥4). Correct → `meta.mastery[id]` (cap 3); `_profScore()` = total → `_profTier`
  (Novice→…→先生 Sensei). Finishing syncs proficiency to the board. Entry: Word Book + Proficiency board.
- **CORS test gotcha:** the API only allows the live origins, so headless **`file://` CANNOT call it**.
  Test the live chain by loading **https://kaijukids.co/kaiju-clash/** in chromium (an allowed origin).
- Scenes now: `select·overworld·playing·howto·victory·gameover·bonus·wordbook·carry·leaderboard·quiz`.

## Secret doors (see memory `kaiju-clash-art-rework` for the cinematic art)
- Hidden `D` tile per level (`s.level.door`, `hidden:true`); **fart near it to reveal**, touch to enter
  the shared `w1secret` room; reaching its exit = carried BACK (not "finish") to where you left. The
  carry cinematic is the pixel crane (`drawCarry` / `drawWingedMonster` cycle `crane_{up,mid,down}`).
  Live in w1l1/w1l2/w1l3. `enterSecret`/`exitSecret` save+restore state AND globals `LW/LH`.
