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

if (typeof module !== 'undefined' && module.exports) module.exports = Progression;
