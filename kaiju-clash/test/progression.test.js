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
