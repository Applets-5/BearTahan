"use strict";

const assert = require("node:assert/strict");
const test = require("node:test");
const {
  buildApplyUpdate,
  buildClearUpdate,
  calculateQuestCurrentValue,
} = require("../scripts/demo_outfit_eligibility_lib");

test("apply makes a locked demo outfit eligible without unlocking it", () => {
  const update = buildApplyUpdate({
    quest: {id: "chef_bear", target: 5},
    existingProgress: {currentValue: 1, isUnlocked: false},
  });

  assert.deepEqual(update, {
    demoEligibilityOverride: true,
    currentValue: 5,
    targetValue: 5,
    isUnlocked: false,
  });
});

test("apply does not modify an outfit that is already unlocked", () => {
  const update = buildApplyUpdate({
    quest: {id: "chef_bear", target: 5},
    existingProgress: {isUnlocked: true},
  });

  assert.deepEqual(update, {skip: "already unlocked"});
});

test("apply is idempotent when the override is already enabled", () => {
  const update = buildApplyUpdate({
    quest: {id: "astro_bear", target: 3},
    existingProgress: {
      currentValue: 3,
      targetValue: 3,
      isUnlocked: false,
      demoEligibilityOverride: true,
    },
  });

  assert.deepEqual(update, {skip: "override already enabled"});
});

test("clear restores calculated progress and removes the override", () => {
  const update = buildClearUpdate({
    quest: {id: "super_bear", target: 500},
    existingProgress: {demoEligibilityOverride: true, isUnlocked: false},
    actualCurrentValue: 61,
  });

  assert.deepEqual(update, {
    removeDemoEligibilityOverride: true,
    currentValue: 61,
    targetValue: 500,
  });
});

test("quest calculation uses real source metrics", () => {
  const value = calculateQuestCurrentValue({
    quest: {
      id: "astro_bear",
      conditionType: "perfect_quizzes",
      subjectId: "math",
      target: 3,
    },
    child: {},
    subjectProgress: {},
    attempts: [
      {subjectId: "math", score: 10, total: 10},
      {subjectId: "math", score: 8, total: 10},
    ],
  });

  assert.equal(value, 1);
});
