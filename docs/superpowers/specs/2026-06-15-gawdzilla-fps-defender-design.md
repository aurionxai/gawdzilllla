# GAWDZILLA — First-Person Titan Defender Design Spec

## Vision

You are Earth's defender. Playing first-person inside one of 5 hero kaiju, you step through a Monarch quantum portal into cities under attack by invading titans. Humans are your allies. Enemy kaiju are the threat. You protect the city, save civilians, and defeat the titan before the city falls.

This is a rebuild of the existing LÖVE 2D side-scroller into a first-person RPG — keeping the food system, restaurant cinema, city structure, and kaiju lore while replacing the side-scroll perspective with an FPS view and adding full character progression.

---

## World & Mission Flow

### Monarch Global Alert Network
Between missions the player sees a world map (Monarch's alert system). Active titan attacks pulse red across the globe. The player chooses which city to defend next. Completing a region unlocks deeper, harder attacks further afield.

- **22 cities** total (matching existing `restaurant_defs.lua` city list)
- After each city victory, 2–3 new attacks appear on the map
- Completing all attacks in a region unlocks the next region

### Quantum Portal Travel
Monarch Command activates a quantum portal to transport the player's kaiju to the target city. This is a cinematic FPS transition — the portal opens, you step through, and emerge mid-battle inside the city as the titan attack is already underway.

The portal replaces the current city-select screen and gives narrative justification for instant global travel.

### Win Conditions (per city)
| Condition | Threshold | Rank impact |
|-----------|-----------|-------------|
| Defeat the invading titan | Required | — |
| City integrity (buildings standing) | > 50% | S rank needs > 80% |
| Civilian casualties | Below threshold | S rank needs zero losses |
| Speed | — | Bonus for fast clear |

**S Rank** on all three = Hero rating → unlocks restaurant cinema → food stat boost.

---

## FPS Combat System

### Perspective
The player sees the world from inside their kaiju. Giant clawed hands visible at the bottom corners of the screen (color-coded per kaiju). City buildings at eye level. Enemy titan approaching center screen, HP bar overhead.

### Combat Framework (all kaiju share this)
Every hero uses the same hybrid structure:

**Ranged** — soften the titan from distance before closing in. Each kaiju has a unique ranged attack (atomic breath, divine beam, sonic screech, thrown debris, etc.)

**Melee combo** — close-range claw swipe + tail slam + bite. Tail slam stuns; bite after stun deals massive bonus damage. Claw combos build a hit counter.

**Signature special** — unique to each kaiju, unlocked through progression.

**Passive trait** — always-on ability that defines the kaiju's playstyle.

### Monarch Intel
Dr. Chen and Monarch Command radio the player mid-fight:
- Marks titan weak spots (glowing overlay on enemy body segment)
- Calls out incoming special attacks ("Ghidorah charging gravity beams — dodge left!")
- Tracks civilian positions and calls for evacuation windows

Hitting a Monarch-marked weak spot deals 1.5–2× damage.

### Hostile Military
Some military factions attack the player by mistake early in each city. The player must NOT retaliate. Surviving their fire for 30 seconds triggers a trust event — they switch to assisting (marking targets, calling in healing strikes, evacuating civilians faster).

### Power Unlock Progression
Players start with 2 basic attacks and unlock more through play:
- **Lv1–4**: Ranged attack + basic claw melee
- **Lv5**: Bite unlocked
- **Lv7**: Tail slam unlocked
- **Lv9**: Signature special unlocked
- **Lv12**: Evolution branch chosen → form ability unlocked
- **Lv15+**: Second evolution ability unlocked

---

## Hero Roster

Five playable titans, each with a distinct combat identity. All share the hybrid framework but play completely differently.

### GAWDZILLA
*Balanced · Classic feel*
- **Ranged**: Atomic Breath — hold to sustain beam, dorsal spines glow brighter the higher RAGE stat
- **Special**: Dorsal Pulse — AoE shockwave pushes all enemies back, protects a wide area
- **Passive**: Nuclear Surge — higher RAGE = stronger atomic breath + visually glowing spines
- **Playstyle**: Jack of all trades, strongest late-game when RAGE is maxed

### MOTHRA
*Support · Civilian Protector*
- **Ranged**: Divine Beam — precision shot that auto-targets Monarch-marked weak spots
- **Special**: Silk Bind — immobilizes an enemy titan for 5 seconds (only hero with a CC ability)
- **Passive**: Revive Aura — divine scales slow-heal nearby injured civilians passively
- **Playstyle**: Low damage, highest civilian survival rate; Wing Gust pushes enemies away from buildings

### RODAN
*Speed · Air Power*
- **Ranged**: Sonic Screech — wide cone that stuns all enemies in range
- **Special**: Volcanic Burst — drops molten rock from above on a targeted position
- **Passive**: Aerial Charge — airborne movement charges next attack for bonus damage
- **Playstyle**: Fastest kaiju; Talon Grab picks up enemy titans and drops them away from the city; Supersonic Dive closes distance instantly

### KONG
*Brute · Melee King*
- **Ranged**: Throw Debris — rips chunks off wrecked buildings and hurls them (ranged damage + clears rubble from civilians)
- **Special**: Roar Shockwave — staggers enemy titans AND stuns attacking jets simultaneously
- **Passive**: Redirect Rubble — catches falling debris and redirects it away from civilians automatically
- **Playstyle**: Highest single-hit melee damage; bite removes armor from heavily armored titans; Ground Slam shakes an area

### ANGUIRUS
*Tank · Building Shield*
- **Ranged**: Sonic Roar — disrupts enemy attacks mid-wind-up, cancels their incoming specials
- **Special**: Curl Roll — tucks into spiked ball and charges, devastating knockback
- **Passive**: Shell Guard — can physically stand between enemy titans and buildings, absorbing hits meant for structures
- **Playstyle**: Lowest damage, highest survivability; unique ability to directly shield buildings with his body

---

## Character Progression

### Stats (all kaiju share the same 5 stats)
| Stat | Affects |
|------|---------|
| STR | Melee damage, building smash speed |
| DEF | Damage resistance, missile tank |
| SPD | Movement speed, dodge roll |
| RAGE | Ranged attack power, special cooldown |
| INSTINCT | Weak spot detection range, civilian sense |

Spend stat points each level. Food gives permanent boosts (see Food System).

### Evolution Tree
At Lv12 each kaiju branches into 2 forms based on playstyle:
- **Burning branch**: unlocked by aggressive play (high damage dealt, buildings destroyed) — power-focused, visually changes appearance
- **Armored branch**: unlocked by defensive play (civilians saved, buildings protected) — resilience-focused, different visual

Each branch adds 1–2 form-specific abilities and stat bonuses. Final forms unlock at Lv25.

---

## Food & Restaurant Cinema System

The existing restaurant cinema system is preserved exactly as designed. After an S-rank city clear, the player earns a cultural food reward in a first-person cinema sequence at the city's signature restaurant.

Food gives permanent stat boosts:
| Food type | Stat boost |
|-----------|------------|
| Meat / protein | STR +1 |
| Noodles / carbs | SPD +1 |
| Spicy food | RAGE +1 |
| Seafood | INSTINCT +1 |
| Dessert / sweets | DEF +1 |

City examples:
- Tokyo S rank → Kaiju Ramen → SPD +1
- Seoul S rank → Korean BBQ → STR +1
- Hong Kong S rank → Dim Sum → INSTINCT +1

---

## Ally System

### Monarch Command
- Dr. Chen radios intel mid-fight (weak spots, incoming attacks, civilian counts)
- Between missions: debriefs the player, updates the world map, hints at the overarching villain threat
- Heals the player's kaiju between city missions at Monarch HQ

### City Survivors
Each city has a survivor faction. Protect them → they unlock city-specific buffs for the duration of that mission:
- Military cooperation: jets mark titan positions
- Scientists: double the weak spot damage window
- Civilians: faster evacuation (lower casualty threshold required for S rank)

---

## Enemies

### Invading Titans (primary threat)
Each city has a scripted titan attacker with unique attack patterns:
- **Ghidorah** — gravity beams, three-head coordination, aerial threat
- **Rodan** (when not player) — fast-moving, dive attacks, hard to track
- **MUTOs** — swarm tactics, EMP pulse disables Monarch comms temporarily
- **King Ghidorah (final)** — multi-phase boss, city-wide devastation

### Titan damage states
As titans take damage they show visible diminishment — cracked scales, limping, slower attacks, dimmer eyes. At 20% HP a "FINISH" window opens for a signature takedown move.

---

## Technical Scope

**This is a ground-up rebuild of the game engine.** The existing LÖVE 2D side-scroller architecture does not support FPS. The new game reuses:
- City and restaurant data (`restaurant_defs.lua`)
- Audio assets (`assets/audio/`)
- Character lore and stat definitions
- Food system design

Everything else is new:
- FPS raycaster renderer (replace side-scroll renderer)
- New input system (WASD move, mouse look or arrow aim, Q/E/R/Z/X abilities)
- New combat system (hitboxes in 3D space vs 2D screen)
- World map screen (replace city select)
- Quantum portal transition renderer
- New character sheet UI (evolution tree + stat screen)

**Implementation should be phased:**
1. Phase 1: FPS renderer + single city + one kaiju (Gawdzilla) + one enemy titan
2. Phase 2: Full combat system (all attacks, power unlocks, Monarch intel)
3. Phase 3: World map + quantum portal + all 5 kaiju
4. Phase 4: Full progression (evolution tree, stats, food system)
5. Phase 5: All 22 cities + full enemy roster

---

## Open Questions (deferred)
- Multiplayer co-op (two kaiju defending same city) — out of scope for v1
- Additional titans beyond the 5 — unlock through story progression post-launch
- Mobile port — deferred
- Difficulty settings — handled via stat scaling per region
