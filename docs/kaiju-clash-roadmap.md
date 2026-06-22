# Kaiju Clash — Development Roadmap

## Phase 1 — NPC + Backdrop Polish ✅ DONE
- [x] 8 distinct NPC character types (salaryman, schoolgirl, sumo, chef, otaku, tourist, idol, obāchan)
- [x] Each NPC: unique body proportions, outfit colors, accessories, hair — now 45px tall, 1.4x scale
- [x] Backdrop layer: Tokyo Tower, dense buildings, lamp halos, torii gate, power lines
- [x] Neon signs: ramen, pachinko, karaoke bars in Japanese

## Phase 2 — Gameplay Balance ✅ DONE (partially)
- [x] Score system: citizens saved ×500, enemies killed ×100, food ×50, lost −200
- [x] Victory screen: full score breakdown + letter grade S/A/B/C/D
- [x] Knee attack: ↓ on ground = sweep, ↓ in air = dive
- [x] Enemy die sound wired to all kill paths
- [ ] Spawn grace period: 2s invincibility at game start
- [ ] Citizen danger signal: shake + "HELP!" bubble flashes red before being caught
- [ ] Fart meter visual feedback: flash bar + ping when threshold crossed

## Phase 3 — Audio ✅ IN PROGRESS
- [x] Lofi Tokyo background music loop (Am pentatonic, 220ms steps, kick+hat+bass+lead)
- [x] Knee smash sound (thud + low tone)
- [x] Enemy hit sound (square wave descend)
- [x] Enemy die sound (3-note splat pop)
- [x] Enemy spit sound (sawtooth splat)
- [x] Citizen saved chime (4-note ding ascending)
- [x] Citizen scream function (ready to wire to HELP! bubble)
- [x] Music starts on game start, stops on victory/gameover
- [ ] Richer fart sounds: wet/bubbly variation for size 1
- [ ] Draglet gets a distinct snarl vs slime gurgle on hit
- [ ] Ambient city noise loop (traffic hum, distant crowd)
- [ ] Per-citizen save sounds (different pitch per NPC type)

## Phase 4 — Level System + Difficulty Scaling

### Architecture
Add `levelNum` to game state. Each level uses a config object:
```javascript
const LEVELS = {
  1: { name:'Shinjuku Night',    sky:'#0a0a1a', enemyHpMult:1.0, enemySpeedMult:1.0, spitCoolMult:1.0, numCitizens:8, numEnemies:6 },
  2: { name:'Shibuya Scramble',  sky:'#1a0a0a', enemyHpMult:1.3, enemySpeedMult:1.1, spitCoolMult:0.85, numCitizens:10, numEnemies:8 },
  3: { name:'Akihabara Electric',sky:'#0a1a0a', enemyHpMult:1.6, enemySpeedMult:1.2, spitCoolMult:0.7,  numCitizens:12, numEnemies:10 },
  4: { name:'Odaiba Harbor',     sky:'#1a0a1a', enemyHpMult:2.0, enemySpeedMult:1.35,spitCoolMult:0.55, numCitizens:14, numEnemies:12, boss:true },
};
```

### Level 1: Shinjuku Night (Current)
- Sky: deep blue-black night
- Enemies: Slimes + Draglets (current)
- Citizens: 8
- Background: Tokyo Tower, cherry blossoms, neon signs

### Level 2: Shibuya Scramble (Dawn)
- Sky: orange-pink sunrise gradient
- New mechanic: **Crosswalk tiles** — NPCs panic-run across the intersection every 8s
- New enemy: **Sumo Monster** (wide, slow, charges, 80HP)
- Citizens: 10 — 3 clustered near Scramble crossing
- Background: Shibuya crossing lines, 109 building silhouette, dawn sky

### Level 3: Akihabara Electric (Neon Night)
- Sky: intense neon green/teal
- New mechanic: **Shock tiles** — yellow floor sections deal 5HP/sec damage
- New enemy: **Mech Robot** (shoots burst of 3 bullets, slower spit cooldown)
- Citizens: 12 — some on elevated platforms
- Background: Dense neon signage, anime billboard, electric sparks

### Level 4: Odaiba Harbor (Apocalypse)
- Sky: red/purple apocalyptic
- New mechanic: **Rising platforms** — some tiles bob up/down over water
- Boss: **Giant Mecha Kaiju** (400HP, stomps create shockwaves, fires 5-wide burst)
- Citizens: 14 — scattered, some on water platforms
- Background: Tokyo Bay, Rainbow Bridge, giant mecha silhouette

### Difficulty Scaling Per Level
| Stat              | L1     | L2     | L3     | L4 Boss |
|-------------------|--------|--------|--------|---------|
| Enemy HP          | 30/55  | 39/72  | 48/88  | 400     |
| Enemy walk speed  | 1.2    | 1.32   | 1.44   | 0.8     |
| Spit cooldown     | 3000ms | 2550ms | 2100ms | 1800ms  |
| Eat cooldown      | 8000ms | 6800ms | 5800ms | N/A     |
| Citizens          | 8      | 10     | 12     | 14      |
| Enemies           | 6      | 8      | 10     | 12+boss |

### Progression Triggers
- Complete level (reach end OR kill all enemies + score ≥ threshold)
- Between-level: brief cutscene card "LEVEL 2 — SHIBUYA SCRAMBLE" with star rating
- Carry score and HP forward (no mid-level save)

## Phase 5 — Content + Polish
- [ ] Pre-fight countdown: 3-2-1 GET STOMPING before enemies activate
- [ ] Mid-level checkpoint at tile ~55
- [ ] NHK helicopter drops food onto platforms mid-level
- [ ] Unlockable: win with both Lulah+Poppy → unlock 3rd character

## Controls Reference
| Key      | Action                     |
|----------|----------------------------|
| ← →      | Move                       |
| ↑ / Space | Jump & Stomp              |
| A        | Chomp (melee)              |
| S        | Fart special (when charged)|
| D        | Shoot (ranged)             |
| ↓ ground | Knee sweep attack          |
| ↓ in air | Dive bomb                  |

## Score System
| Action             | Points |
|--------------------|--------|
| Citizen saved      | +500   |
| Enemy (slime) kill | +100   |
| Enemy (draglet) kill| +300  |
| Food eaten         | +50    |
| Citizen eaten      | −200   |

**Letter Grades:** S = 8/8 saved · A = 6-7 · B = 4-5 · C = 2-3 · D = 0-1

---

# 🌏 MASTER PLAN UPDATE — Language Learning + Audio + Infra (2026-06-21)

## Phase 6 — Passive Japanese Learning ✅ LIVE (World 1)
The hook: kids learn Japanese **without realizing it** — every action surfaces a real word on
screen (kana + romaji + meaning) AND speaks it aloud.

**Three teaching moments, all live in World 1:**
- 🤝 **Rescue an NPC** → says a greeting/feeling word, voice matched to the NPC's gender. 24 words.
- 🍣 **Eat food** → speaks the food's Japanese name; food rotates through 24 types (new word each
  pickup). 24 words (female / hero voice).
- 👾 **Defeat an enemy** → speaks the monster/animal word in a male voice. 20 words.

**≈ 68 spoken Japanese words in World 1 alone** (target was 20-30/world — exceeded).

**Reinforcement, also live:**
- 🍣 Eating food shows the phrase BIG on screen (kana + romaji + meaning) while it's spoken.
- 🎌 **End-of-world BONUS** — after the boss, a match-the-words mini-game (`scene='bonus'`): 5
  Japanese words vs shuffled meanings, tap-to-match, correct = speak + cheer + points, then victory.
  Pool = that world's rescue + food + enemy words (`startBonus()` / `drawBonus()`).

### Structure (scales to all worlds)
- `WORLD_VOCAB[world]` — rescue words per world (add `[2]`,`[3]`,`[4]` to expand).
- `FOOD_TYPES[].jp/ro/en` + `ENEMIES[].jp/ro/en` — food & enemy words.
- Voice clips: `sounds/jp/<key>_<f|m>.mp3` (macOS Kyoko TTS, normalized -15 LUFS). 92 clips, loaded by `loadJpVoices()`.

### TODO
- [ ] World 2/3/4 vocab sets (20-30 each): colors/numbers (W2), sea animals/nature (W3), weather/verbs (W4)
- [ ] **Real male voice** — install Otoya (System Settings → Spoken Content → JP voices) + regenerate `_m` clips (currently pitch-shifted Kyoko: correct pronunciation, synthesized pitch)
- [ ] "Word book" screen: list learned words, tap to replay
- [ ] Localize to other languages (same structure, swap vocab + TTS voice)

## Phase 7 — Audio Engineering ✅ DONE
- Loudness-normalized every clip (SFX -16, music -20 LUFS, -1 dB true-peak) — consistent mix
- Sub-mix buses (SFX + music) + per-sound throttle + 8-voice cap — no pile-ups
- Music routed around the SFX compressor + unlock-runs-once fix — steady music (no pumping/restart)
- Real samples: main + boss themes, 3 fart levels, baby giggle, distinct enemy hit + death sounds

## Infrastructure ✅ DONE
- Live on GitHub Pages + **kaijukids.co** (HTTPS cert provisioning); auto-deploys on push to `main`
- Cache-busting via `ASSET_VER` in index.html (BUMP on any asset change)
- Headless QA: `loadtest.js` (startup-crash guard), `playtest.js` (bot beats all 4 levels),
  `qa-audit.js` (audio/sprite audit), 23 unit tests — all green
- "How to Play" card before level 1; richly-animated procedural Riot Mecha boss with damage states

## Current controls (supersedes the old table above)
← → move · ↑/Space jump & stomp · **Z** = fart (when charged) / chomp · eat 🍣 to charge the fart meter
