// Pure progression logic. Runs in Node (tests) and the browser (global Progression).
// MUST NOT reference window/document/localStorage/Date.
const Progression = {};

// S/A/B/C letter rank for a completed level.
// Evaluated top-down: first matching tier wins.
Progression.computeRank = function computeRank({ timeSec, hitsTaken, citizensSaved, citizensTotal }) {
  const ratio = citizensTotal > 0 ? citizensSaved / citizensTotal : 1;
  if (ratio >= 1 && hitsTaken === 0 && timeSec <= 90) return 'S';
  if (ratio >= 0.75 && hitsTaken <= 2) return 'A';
  if (ratio >= 0.5) return 'B';
  return 'C';
};

const RANK_ORB_BASE = { S: 100, A: 75, B: 50, C: 30 };

Progression.orbsForResult = function orbsForResult({ rank, citizensSaved, sideQuestsDone }) {
  const base = RANK_ORB_BASE[rank] || 0;
  return base + citizensSaved * 5 + sideQuestsDone * 20;
};

// 1 star: completed. +1 star: rank A or S. +1 star: every citizen saved.
Progression.starsForResult = function starsForResult({ rank, citizensSaved, citizensTotal }) {
  let stars = 1;
  if (rank === 'A' || rank === 'S') stars += 1;
  if (citizensTotal > 0 && citizensSaved >= citizensTotal) stars += 1;
  return stars;
};

Progression.GROWTH_STAGES = [
  { key: 'hatchling',  name: 'Hatchling',  minOrbs: 0 },
  { key: 'juvenile',   name: 'Juvenile',   minOrbs: 150 },
  { key: 'adolescent', name: 'Adolescent', minOrbs: 400 },
  { key: 'leviathan',  name: 'Leviathan',  minOrbs: 750 },
  { key: 'apex',       name: 'Apex',       minOrbs: 1200 },
];

Progression.stageForOrbs = function stageForOrbs(totalOrbs) {
  let idx = 0;
  for (let i = 0; i < Progression.GROWTH_STAGES.length; i++) {
    if (totalOrbs >= Progression.GROWTH_STAGES[i].minOrbs) idx = i;
  }
  return idx;
};

const META_VERSION = 1;
const RANK_ORDER = { C: 0, B: 1, A: 2, S: 3 };

Progression.defaultMeta = function defaultMeta() {
  return { version: META_VERSION, orbs: 0, growthStage: 0, levels: {} };
};

Progression.serializeMeta = function serializeMeta(meta) {
  return JSON.stringify(meta);
};

Progression.deserializeMeta = function deserializeMeta(str) {
  if (!str) return Progression.defaultMeta();
  let parsed;
  try { parsed = JSON.parse(str); } catch (e) { return Progression.defaultMeta(); }
  if (!parsed || parsed.version !== META_VERSION) return Progression.defaultMeta();
  return parsed;
};

Progression.applyResult = function applyResult(meta, { levelId, rank, citizensSaved, citizensTotal, sideQuestsDone }) {
  const next = Progression.deserializeMeta(Progression.serializeMeta(meta)); // deep copy
  next.orbs += Progression.orbsForResult({ rank, citizensSaved, sideQuestsDone });
  const stars = Progression.starsForResult({ rank, citizensSaved, citizensTotal });
  const prev = next.levels[levelId];
  const bestStars = prev ? Math.max(prev.stars, stars) : stars;
  const bestRank = prev && RANK_ORDER[prev.rank] >= RANK_ORDER[rank] ? prev.rank : rank;
  next.levels[levelId] = { stars: bestStars, rank: bestRank, sideQuestsDone: sideQuestsDone };
  next.growthStage = Progression.stageForOrbs(next.orbs);
  return next;
};

Progression.LEVELS = [
  { id: 'w1l1', world: 1, name: 'Tokyo Streets', order: 1, playable: true },
  { id: 'w1l2', world: 1, name: 'Rooftop Run',   order: 2, playable: true },
  { id: 'w1l3', world: 1, name: 'Tower Climb',    order: 3, playable: true },
  { id: 'w1l4', world: 1, name: 'Riot Mecha',     order: 4, playable: true },
];

function levelById(id) { return Progression.LEVELS.find(l => l.id === id) || null; }

Progression.isLevelUnlocked = function isLevelUnlocked(meta, levelId) {
  const lvl = levelById(levelId);
  if (!lvl) return false;
  if (lvl.order === 1) return true;
  if (!lvl.playable) return false;
  const prev = Progression.LEVELS.find(l => l.world === lvl.world && l.order === lvl.order - 1);
  return !!(prev && meta.levels && meta.levels[prev.id]);
};

Progression.nextLevelId = function nextLevelId(levelId) {
  const lvl = levelById(levelId);
  if (!lvl) return null;
  const candidates = Progression.LEVELS
    .filter(l => l.playable && (l.world > lvl.world || (l.world === lvl.world && l.order > lvl.order)))
    .sort((a, b) => (a.world - b.world) || (a.order - b.order));
  return candidates.length ? candidates[0].id : null;
};

if (typeof module !== 'undefined' && module.exports) module.exports = Progression;
