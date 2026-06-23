const test = require('node:test');
const assert = require('node:assert');
const Progression = require('../progression.js');

test('computeRank: flawless fast full-save is S', () => {
  assert.strictEqual(
    Progression.computeRank({ timeSec: 60, hitsTaken: 0, citizensSaved: 8, citizensTotal: 8 }),
    'S');
});

test('computeRank: most saved, few hits is A', () => {
  assert.strictEqual(
    Progression.computeRank({ timeSec: 200, hitsTaken: 2, citizensSaved: 6, citizensTotal: 8 }),
    'A');
});

test('computeRank: half saved is B', () => {
  assert.strictEqual(
    Progression.computeRank({ timeSec: 300, hitsTaken: 5, citizensSaved: 4, citizensTotal: 8 }),
    'B');
});

test('computeRank: poor save rate is C', () => {
  assert.strictEqual(
    Progression.computeRank({ timeSec: 300, hitsTaken: 9, citizensSaved: 1, citizensTotal: 8 }),
    'C');
});

test('computeRank: handles zero citizens total without dividing by zero', () => {
  assert.strictEqual(
    Progression.computeRank({ timeSec: 60, hitsTaken: 0, citizensSaved: 0, citizensTotal: 0 }),
    'S');
});

test('orbsForResult: S rank base + bonuses', () => {
  // base S=100, +5/citizen *8 = 40, +20/sidequest *1 = 20  => 160
  assert.strictEqual(
    Progression.orbsForResult({ rank: 'S', citizensSaved: 8, sideQuestsDone: 1 }),
    160);
});

test('orbsForResult: C rank minimal', () => {
  // base C=30, +0 citizens, +0 sidequests => 30
  assert.strictEqual(
    Progression.orbsForResult({ rank: 'C', citizensSaved: 0, sideQuestsDone: 0 }),
    30);
});

test('starsForResult: complete only is 1 star', () => {
  assert.strictEqual(
    Progression.starsForResult({ rank: 'C', citizensSaved: 2, citizensTotal: 8 }),
    1);
});

test('starsForResult: A rank adds a star', () => {
  assert.strictEqual(
    Progression.starsForResult({ rank: 'A', citizensSaved: 6, citizensTotal: 8 }),
    2);
});

test('starsForResult: A rank + all citizens is 3 stars', () => {
  assert.strictEqual(
    Progression.starsForResult({ rank: 'A', citizensSaved: 8, citizensTotal: 8 }),
    3);
});

test('GROWTH_STAGES has 5 named ascending stages', () => {
  assert.strictEqual(Progression.GROWTH_STAGES.length, 5);
  assert.deepStrictEqual(
    Progression.GROWTH_STAGES.map(s => s.key),
    ['hatchling', 'juvenile', 'adolescent', 'leviathan', 'apex']);
  for (let i = 1; i < Progression.GROWTH_STAGES.length; i++) {
    assert.ok(Progression.GROWTH_STAGES[i].minOrbs > Progression.GROWTH_STAGES[i - 1].minOrbs);
  }
});

test('stageForOrbs maps orb totals to stage index', () => {
  assert.strictEqual(Progression.stageForOrbs(0), 0);   // hatchling
  assert.strictEqual(Progression.stageForOrbs(149), 0);
  assert.strictEqual(Progression.stageForOrbs(150), 1); // juvenile
  assert.strictEqual(Progression.stageForOrbs(400), 2); // adolescent
  assert.strictEqual(Progression.stageForOrbs(750), 3); // leviathan
  assert.strictEqual(Progression.stageForOrbs(99999), 4); // apex (capped)
});

test('defaultMeta shape', () => {
  assert.deepStrictEqual(Progression.defaultMeta(),
    { version: 1, orbs: 0, growthStage: 0, levels: {} });
});

test('serialize/deserialize round-trips', () => {
  const m = Progression.defaultMeta();
  m.orbs = 320;
  const back = Progression.deserializeMeta(Progression.serializeMeta(m));
  assert.strictEqual(back.orbs, 320);
});

test('deserializeMeta falls back to default on garbage', () => {
  assert.deepStrictEqual(Progression.deserializeMeta('not json'), Progression.defaultMeta());
  assert.deepStrictEqual(Progression.deserializeMeta(null), Progression.defaultMeta());
  assert.deepStrictEqual(Progression.deserializeMeta('{"version":999}'), Progression.defaultMeta());
});

test('applyResult adds orbs, records level, recomputes growth stage', () => {
  let m = Progression.defaultMeta();
  m = Progression.applyResult(m, {
    levelId: 'w1l1', rank: 'S', citizensSaved: 8, citizensTotal: 8, sideQuestsDone: 1,
  });
  // orbs = orbsForResult(S,8,1) = 160
  assert.strictEqual(m.orbs, 160);
  assert.strictEqual(m.growthStage, 1); // 160 >= 150
  assert.strictEqual(m.levels['w1l1'].stars, 3);
  assert.strictEqual(m.levels['w1l1'].rank, 'S');
});

test('applyResult keeps best stars on replay, still adds orbs', () => {
  let m = Progression.defaultMeta();
  m = Progression.applyResult(m, { levelId: 'w1l1', rank: 'A', citizensSaved: 8, citizensTotal: 8, sideQuestsDone: 0 });
  const starsAfterFirst = m.levels['w1l1'].stars; // 3
  m = Progression.applyResult(m, { levelId: 'w1l1', rank: 'C', citizensSaved: 1, citizensTotal: 8, sideQuestsDone: 0 });
  assert.strictEqual(m.levels['w1l1'].stars, starsAfterFirst); // best kept (3 > 1)
  assert.strictEqual(m.levels['w1l1'].rank, 'A'); // best kept
});

test('applyResult does not mutate the input meta', () => {
  const m = Progression.defaultMeta();
  Progression.applyResult(m, { levelId: 'w1l1', rank: 'C', citizensSaved: 0, citizensTotal: 8, sideQuestsDone: 0 });
  assert.strictEqual(m.orbs, 0);
  assert.deepStrictEqual(m.levels, {});
});

test('LEVELS: world 1 has 4 ordered entries, all playable (incl. the boss)', () => {
  const w1 = Progression.LEVELS.filter(l => l.world === 1);
  assert.strictEqual(w1.length, 4);
  assert.strictEqual(w1[0].id, 'w1l1');
  assert.deepStrictEqual(w1.map(l => l.playable), [true, true, true, true]);
  assert.strictEqual(w1[3].id, 'w1l4');       // Riot Mecha boss
});

test('isLevelUnlocked: first level always unlocked', () => {
  assert.strictEqual(Progression.isLevelUnlocked(Progression.defaultMeta(), 'w1l1'), true);
});

test('isLevelUnlocked: locked when prior level incomplete', () => {
  assert.strictEqual(Progression.isLevelUnlocked(Progression.defaultMeta(), 'w1l2'), false);
});

test('isLevelUnlocked: the boss unlocks once w1l3 is cleared', () => {
  let m = Progression.defaultMeta();
  assert.strictEqual(Progression.isLevelUnlocked(m, 'w1l4'), false);  // locked at first
  m.levels['w1l1'] = { stars: 3, rank: 'A', sideQuestsDone: 0 };
  m.levels['w1l2'] = { stars: 3, rank: 'A', sideQuestsDone: 0 };
  m.levels['w1l3'] = { stars: 3, rank: 'A', sideQuestsDone: 0 };
  assert.strictEqual(Progression.isLevelUnlocked(m, 'w1l4'), true);   // unlocked after w1l3
});

test('nextLevelId returns next playable or null', () => {
  assert.strictEqual(Progression.nextLevelId('w1l1'), 'w1l2');
  assert.strictEqual(Progression.nextLevelId('w1l3'), 'w1l4');
  // world 1 boss flows into world 2; world 2 boss is the last level -> null
  assert.strictEqual(Progression.nextLevelId('w1l4'), 'w2l1');
  assert.strictEqual(Progression.nextLevelId('w2l4'), null);
});

test('world 2 is gated behind finishing world 1', () => {
  assert.strictEqual(Progression.isLevelUnlocked({ levels: {} }, 'w2l1'), false);
  assert.strictEqual(Progression.isLevelUnlocked({ levels: { w1l4: { stars: 1 } } }, 'w2l1'), true);
});
