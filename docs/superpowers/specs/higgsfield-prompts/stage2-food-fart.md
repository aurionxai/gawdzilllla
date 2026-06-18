# Stage 2 — Food + Fart System Prompt

**Goal:** Add food power-up cinema, localized audio, fart tiers, and standard power-up drops. Verify pacing before advancing to Stage 3.

---

## Higgsfield Prompt (additive — builds on Stage 1 output)

Add to the existing Tokyo stage:

FOOD POWER-UP SYSTEM: When the player successfully evacuates a Tokyo city block (all civilians move out of titan's attack path), a glowing Yakitori (🍢) icon appears on the street. Player walks into it. Trigger: 2-second pixel art cinema cutscene — kaiju at a Japanese street food stall, giant claw reaching in. Voice line fires in Japanese: "やきとり！パワーアップ！" with English subtitle "Yakitori! Power up!" displayed in native Japanese script. 30% chance: a funny variant voice line fires instead — exaggerated enthusiasm about yakitori being too small for a kaiju-sized meal. Power effect activates: Rage Surge large (ranged attack +75% for 15 sec). After 3 seconds: Fart Tier 1 fires — Polite Puff — small green cloud, Ghidorah hiccups and staggers briefly, any nearby civilians sneeze. Cloud lasts 3 sec. Gawdzilla resumes immediately.

GREGG INTERFERENCE: 30% chance when food icon appears — GREGG spawns from off-screen. Dark hair, full beard, navy baseball cap, light blue polo, khaki pants, white sneakers. He is fully invincible. He sprints to the food icon and eats it before the player can reach it. After eating: Gregg produces a small sad fart. He immediately points at the nearest enemy titan and says in a confident voice-over: "That three-headed thing right there. I saw him." He walks away. Food icon disappears — player gets nothing.

STANDARD POWER-UPS: Every 3rd titan hit or destroyed enemy structure drops one random standard pickup on the ground. Pickups glow and pulse. Player walks into them for instant effect — no cutscene.
- ⚡ Rage Surge — ranged attack +50%, 10 sec
- 🛡 Armor Shell — damage resistance 50%, 8 sec
- 💨 Speed Burst — movement 2×, 8 sec
- ☢️ Power Charge — fill power meter instantly
- 💊 Regen — restore 20% HP instantly

---

## Verify Before Advancing

- [ ] Food power-up only appears after city block evacuation — not random drops
- [ ] Cinema cutscene is 2 seconds exactly, not disruptive to flow
- [ ] Japanese voice line fires correctly with English subtitle
- [ ] 30% funny variant triggers appropriately
- [ ] Fart Tier 1 visual is small/brief — Polite Puff, not screen-filling
- [ ] Standard power-ups drop frequently and feel good to pick up
- [ ] Gregg visually distinct, sprints convincingly, blame line fires cleanly
- [ ] Gregg cannot be hit or killed by any attack
