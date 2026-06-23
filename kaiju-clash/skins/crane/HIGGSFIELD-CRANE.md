# Secret-door carrier crane (tsuru) — Higgsfield web-app generation kit

Generate in the **Higgsfield web app** (higgsfield.ai) with **nano_banana_pro**, then drop the PNGs in
this folder. Claude wires them into the secret-door carry cinematic and deletes the vector placeholder.

## Settings (same for every frame)
- Model: **nano_banana_pro**
- **Reference images (import for on-model consistency):** `mockups/lulah-growth-FINAL.png` +
  `mockups/poppy-growth-FINAL.png` (so the crane matches the heroes' pixel style, outline, palette).
- Output: **transparent background**, single isolated crane, **no scene / no kaiju / no ground**.
- Size: **~128 px tall** (carrier = hero scale), wings make it ~160 px wide. Same canvas + same
  registration for all 3 frames so they line up when swapped (critical for the flap animation).
- **Talons reach DOWNWARD, open/gripping** — in-game the kaiju is drawn below, held in the talons.

## Style block (prepend to each prompt)
> 16-bit SNES pixel-art game sprite, single Japanese red-crowned crane (tancho / tsuru) flying toward
> the viewer, 3/4 front angle, wings spread, isolated on a FULLY TRANSPARENT background — no scene, no
> ground, nothing in its feet. Crisp hard pixels, bold dark outline, full shading ramp (bright white
> highlight → cool grey mid → slate shadow), consistent top-left light, soft rim light. White body and
> wings, jet-black wingtips, red crown patch on the head, orange beak, slate-grey legs with talons
> reaching DOWN as if gently carrying something. Friendly, soft, cute face to match the reference
> kaiju. Clean readable silhouette, vibrant kid-friendly palette, centered, ~128px tall.

## The 3 flap frames → filenames
| File | Pose prompt (append to the style block) |
|---|---|
| `crane_up.png`   | "...wings raised UP high on the upstroke, body dipped slightly, mid-flap." |
| `crane_mid.png`  | "...wings held LEVEL, spread straight out, gliding mid-beat." |
| `crane_down.png` | "...wings pushed DOWN on the powerful downstroke, body lifted slightly." |

## After you drop them in
Claude: load as `loadedSprites['crane_up'|'crane_mid'|'crane_down']`, cycle the 3 frames on each
wingbeat in `drawCarry`, keep drawing the kaiju tucked under the talons, keep the flap-whoosh +
landing dust-puff SFX, delete the procedural `drawWingedMonster`, bump `ASSET_VER`.
