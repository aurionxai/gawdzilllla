# Stage 1 — Foundation Prompt

**Goal:** Establish the 2.5D FPS aesthetic, core combat, and Tokyo city. Verify before advancing to Stage 2.

---

## Higgsfield Prompt

2.5D pixel-art first-person kaiju game. You play as GAWDZILLA — giant clawed scaly hands visible at screen corners, Tokyo cityscape at eye level. Chunky 16-bit pixel art, DOOM-era sprite scaling, dark navy sky, neon Shinjuku signage in Japanese kanji, Tokyo Tower silhouette in background distance. Camera: first-person with slight head-bob on movement.

HUD: minimal — dorsal-spine power bar at bottom center (glows radioactive green, pulses when full), health bar top left. No other chrome.

ENEMY: KING GHIDORAH — massive three-headed titan attacking the city. Ranged: gravity beam from each head (dodge timing telegraphed by heads charging up, 1-sec warning). Melee: triple-head lunge when close. Visible damage states: scales crack, heads droop, movement slows at 50% HP. At 20% HP: FINISH prompt appears.

GAWDZILLA COMBAT:
- Atomic Breath (hold trigger): sustained radioactive beam, dorsal spines glow brighter as power meter fills — stronger beam at higher power
- Claw Swipe: fast 3-hit melee combo
- Tail Slam: slower, stuns Ghidorah for 2 sec
- Dorsal Pulse (special, costs full meter): AoE shockwave pushes all enemies back in wide radius

ENVIRONMENT: Tokyo streets dense with destructible pixel-art buildings. Civilians scatter when titan approaches — protect them. Military jets and tanks fire on Gawdzilla for the first 30 seconds (mistaken identity) — do NOT retaliate. After 30 sec: military trust event fires, jets switch to ally and mark Ghidorah weak spots with glowing overlays.

WIN: Defeat Ghidorah. City integrity and civilian survival tracked.

---

## Verify Before Advancing

- [ ] 2.5D FPS perspective feels right — kaiju hands at corners, city at eye level
- [ ] Tokyo is recognizable — Tower silhouette, kanji neon, dense urban pixel art
- [ ] Atomic breath mechanic responds to hold input
- [ ] Spine glow visually tracks power meter fill
- [ ] Military trust flip works at 30-sec mark
- [ ] Civilians distinguish from enemy targets
