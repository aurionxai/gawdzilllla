#!/usr/bin/env node
// Kaiju Clash QA auditor — static check that every gameplay event has audio and every
// entity has visuals + assets. Run: `node qa-audit.js`. No browser needed.
const fs = require('fs');
const path = require('path');
const HTML = fs.readFileSync(path.join(__dirname, 'index.html'), 'utf8');

let pass = 0, warn = 0, fail = 0;
const rec = [];
const line = (s) => console.log(s);
const ok   = (m) => { pass++; line('  \x1b[32m✓\x1b[0m ' + m); };
const wn   = (m, r) => { warn++; line('  \x1b[33m⚠\x1b[0m ' + m); if (r) rec.push('[polish] ' + r); };
const bad  = (m, r) => { fail++; line('  \x1b[31m✗\x1b[0m ' + m); if (r) rec.push('[FIX]   ' + r); };
const has  = (re) => (re instanceof RegExp ? re : new RegExp(re)).test(HTML);

function head(t){ line('\n\x1b[1m' + t + '\x1b[0m'); }

// ── 1. AUDIO: every gameplay event triggers a sound ───────────────────────────
head('AUDIO — event coverage');
const audioEvents = [
  ['eat food',        /sndEat\(/,                'food pickup'],
  ['stomp enemy',     /sndEnemyHit\(|sndEnemyDie\(/, 'stomp'],
  ['bite/chomp',      /doBite[\s\S]*?snd/,       'melee bite'],
  ['fart',            /sndFart\(/,               'fart attack'],
  ['giggle on fart',  /sndGiggle\(/,             'giggle'],
  ['take damage',     /sndHurt\(/,               'player hurt'],
  ['fall to death',   /sndFall\(/,               'fall in a pit'],
  ['rescue citizen',  /saveCitizen[\s\S]*?playSample/, 'townsfolk rescued (speaks the word)'],
  ['jump',            /sndJump\(/,               'jump'],
  ['combo chain',     /sndCombo\(/,              'chain stomp'],
  ['level win',       /sndVictory\(/,            'level complete'],
  ['boss hit',        /updateBoss[\s\S]*?snd(Creature|Roar)\(/, 'boss weak-point'],
  ['theme music',     /function _musicTick/,     'background music'],
];
for (const [name, re, what] of audioEvents) {
  has(re) ? ok(name + ' → sound') : bad(name + ' has NO sound', 'add a sound to the "' + what + '" event');
}
// missing-but-expected events
if (!/scene==='gameover'[\s\S]{0,400}snd|sndLose|sndGameOver/.test(HTML))
  wn('game-over has no dedicated sound', 'add a short "defeat" sting when scene→gameover');
if (!/sndGem|gem[\s\S]{0,80}snd(Giggle|Chime)/.test(HTML))
  wn('gem-collect reuses the giggle (no dedicated chime)', 'a distinct "gem" chime would read better than the giggle');

// ── 2. AUDIO: per-enemy and per-food voices ───────────────────────────────────
head('AUDIO — per-entity voices');
const enemyTypes = [...HTML.matchAll(/^\s*([a-z_]+):\s*\{\s*file:'enemies\//gm)].map(m => m[1]);
const voiceBlock = (HTML.match(/_VOICE\s*=\s*\{([\s\S]*?)\};/) || [,''])[1];
const missingVoice = enemyTypes.filter(t => !new RegExp('\\b' + t + '\\s*:').test(voiceBlock));
enemyTypes.length ? ok(enemyTypes.length + ' enemy types found') : bad('no enemy registry found');
missingVoice.length === 0
  ? ok('every enemy has a _VOICE entry')
  : bad('enemies missing a voice: ' + missingVoice.join(', '), 'add _VOICE entries for: ' + missingVoice.join(', '));
const foodBlock = (HTML.match(/FOOD_TYPES\s*=\s*\[([\s\S]*?)\];/) || [,''])[1];
const foodKeys = [...foodBlock.matchAll(/key:'([a-z]+)'/g)].map(m => m[1]);
const foodSnd = (HTML.match(/_FOODSND\s*=\s*\{([\s\S]*?)\};/) || [,''])[1];
const missingFood = [...new Set(foodKeys)].filter(k => !new RegExp(k + '\\s*:').test(foodSnd));
missingFood.length === 0
  ? ok('every food has its own eat sound')
  : wn('foods reusing the default eat sound: ' + missingFood.join(', '), 'give ' + missingFood.join(', ') + ' a distinct eat sound');

// ── 3. VISUAL: every entity has a draw routine ────────────────────────────────
head('VISUAL — draw coverage');
const draws = [
  ['player (lulah/poppy)', /function drawLulah|function drawPoppy/],
  ['enemies',  /function drawEnemies/],
  ['boss',     /function drawBoss/],
  ['citizens', /function drawCitizens/],
  ['food',     /function drawFood/],
  ['gems',     /function drawGems/],
  ['tiles',    /function drawTiles/],
  ['background',/function drawBg/],
  ['fart cloud',/function drawFartCloud/],
  ['HUD',      /function drawHUD/],
  ['touch controls', /function drawTouchControls/],
  ['overworld map',  /function drawOverworld/],
  ['hero select',    /function drawSelect/],
  ['victory screen', /function drawVictory/],
  ['game-over screen',/function drawGameover/],
];
for (const [name, re] of draws) has(re) ? ok(name + ' drawn') : bad(name + ' has NO draw routine', 'implement draw for ' + name);

// ── 4. VISUAL: referenced sprite assets exist on disk ─────────────────────────
head('VISUAL — sprite assets present');
const assetRefs = [...HTML.matchAll(/'((?:enemies|npcs|skins|backdrops|food)\/[^']+\.png)'/g)].map(m => m[1]);
const skinFrames = [...HTML.matchAll(/'(skins\/[^']+\.png)'/g)].map(m => m[1]);
const npcFiles = (HTML.match(/NPC_TYPES\s*=\s*\[([\s\S]*?)\]/) || [,''])[1];
let missingAsset = [];
for (const a of [...new Set(assetRefs)]) if (!fs.existsSync(path.join(__dirname, a))) missingAsset.push(a);
missingAsset.length === 0
  ? ok([...new Set(assetRefs)].length + ' referenced sprite files all present')
  : bad(missingAsset.length + ' sprite files MISSING:\n      ' + missingAsset.join('\n      '), 'generate/restore: ' + missingAsset.join(', '));
// boss uses a procedural sprite (no png) — flag as a known gap
if (/function drawBoss[\s\S]*?fillR\(|rrect\(/.test(HTML) && !/en_riot|boss.*\.png/.test(HTML))
  wn('boss is drawn procedurally (no sprite sheet yet)', 'slice a real Riot Mecha sprite from the mockup/pipeline to match the other art');

// ── 5. AUDIO hygiene: unlock + resilience (Safari) ────────────────────────────
head('AUDIO — robustness');
has(/function unlockAudio/) ? ok('audio unlock-on-gesture present') : bad('no audio unlock', 'Safari/iOS will be silent without a gesture unlock');
has(/try\s*\{[\s\S]{0,400}?update\([\s\S]{0,400}?render\(\)[\s\S]{0,200}?catch/) ? ok('frame is crash-isolated (a sound error can\'t freeze the game)') : wn('frame not wrapped', 'wrap update/render so an audio throw cannot freeze the loop');
has(/drawAudioBtn|toggleMusic/) ? ok('player-facing mute/unmute control') : wn('no mute control', 'add a visible mute toggle');

// ── summary ───────────────────────────────────────────────────────────────────
head('SUMMARY');
line(`  \x1b[32m${pass} pass\x1b[0m · \x1b[33m${warn} polish\x1b[0m · \x1b[31m${fail} fail\x1b[0m`);
if (rec.length){ line('\n\x1b[1mRECOMMENDATIONS\x1b[0m'); rec.forEach(r => line('  • ' + r)); }
process.exit(fail ? 1 : 0);
