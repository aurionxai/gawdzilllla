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
