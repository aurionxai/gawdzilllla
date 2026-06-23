# Riot Mecha — Higgsfield frame-set generation kit

Generate these **4 frames** in Higgsfield (`nano_banana_pro`), then drop the PNGs in this folder.
Claude wires them into `drawBoss` (sprite-per-state) and deletes the procedural placeholder.

## Settings (same for every frame)
- Model: **nano_banana_pro**
- **Reference image:** `mockups/boss1-riot-mecha.png` (import for on-model consistency — the mech only)
- Output: **transparent background**, single isolated character, **~256 px tall**, centered,
  full body **including the tank-tread base**. Same canvas size + same registration for all 4 so
  the frames line up when swapped (critical for animation).
- Keep the **glowing cyan/teal core reactor** visible on the torso — it's the gameplay weak point.

## Shared style block (prepend to each prompt)
> 16-bit SNES pixel-art game sprite, single Riot Mecha isolated on a FULLY TRANSPARENT background —
> no scene, no Tokyo Tower, no HUD, no ground shadow. Crisp hard pixels, bold dark outline, full
> shading ramp (steel highlight → mid blue-grey → dark shadow), consistent top-left light. Grey-blue
> armored mech with amber-yellow "RIOT" shield accents, glowing red eye/visor, glowing cyan core
> reactor on the chest, tank-tread base. On-model with the reference. Clean readable silhouette,
> kid-friendly, not gory. Centered, ~256px tall.

## The 4 frames → filenames
| File | Pose prompt (append to the style block) |
|---|---|
| `riot_idle.png`   | "...neutral standing idle, shield arm forward, fist at side, treads level, menacing but calm." |
| `riot_windup.png` | "...rearing back, both arms and RIOT shield raised high overhead, core reactor flaring bright, telegraphing a ground slam — tense wind-up." |
| `riot_slam.png`   | "...lunging forward, shield/fist smashing straight down to the ground, heavy impact pose, slight forward lean." |
| `riot_defeat.png` | "...defeated and slumping, head bowed, panels cracked, sparks and a little smoke, shield lowered — beaten but still cute, not destroyed." |

## After you drop them in
Claude: load as `loadedSprites['boss_idle'|'boss_windup'|'boss_slam'|'boss_defeat']`, map `b.state`
→ frame in `drawBoss`, keep the code FX (white hit-flash tint, ground shockwaves, defeat collapse
translate/rotate) layered OVER the sprite, delete the procedural mech body, bump `ASSET_VER`.
