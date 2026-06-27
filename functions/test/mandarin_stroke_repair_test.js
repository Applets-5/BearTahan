"use strict";

const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const test = require("node:test");
const {
  buildRepairedQuestion,
  duplicateQuestionMappings,
  mergeReferenceData,
  repairedQuestions,
  replaceQuestionIds,
  validateStrokeOrderData,
} = require("../scripts/mandarin_stroke_repair_lib");

const projectRoot = path.resolve(__dirname, "..", "..");

test("all L3 repair assets contain one valid stroke", () => {
  for (const definition of repairedQuestions) {
    const file = path.join(
      projectRoot,
      "assets",
      "hanzi",
      `${definition.characterUnicode}.json`,
    );
    const data = JSON.parse(fs.readFileSync(file, "utf8"));
    assert.equal(validateStrokeOrderData(data), true);
    assert.equal(data.strokes.length, 1);
    assert.equal(data.medians.length, 1);
  }
});

test("derived na stroke runs from upper-left to lower-right", () => {
  const file = path.join(projectRoot, "assets", "hanzi", "㇏.json");
  const data = JSON.parse(fs.readFileSync(file, "utf8"));
  const median = data.medians[0];
  const start = median[0];
  const end = median.at(-1);

  assert.ok(end[0] > start[0]);
  assert.ok(end[1] < start[1]);
});

test("pie stroke is centered in the tracing canvas", () => {
  const character = String.fromCodePoint(0x4e3f);
  const file = path.join(projectRoot, "assets", "hanzi", `${character}.json`);
  const data = JSON.parse(fs.readFileSync(file, "utf8"));
  const xValues = data.medians[0].map(([x]) => x);
  const center = (Math.min(...xValues) + Math.max(...xValues)) / 2;

  assert.ok(center >= 450 && center <= 575);
});

test("buildRepairedQuestion preserves content and canonicalizes tracing", () => {
  const definition = repairedQuestions[1];
  const strokeOrderData = {
    strokes: ["M 0 0 L 0 10"],
    medians: [[[0, 0], [0, 10]]],
  };
  const result = buildRepairedQuestion(
    definition,
    {
      prompt: "Existing prompt",
      promptAudioUrl: "https://example.com/audio.mp3",
      createdAt: "existing",
    },
    strokeOrderData,
    "fallback",
  );

  assert.equal(result.questionType, "stroke_trace");
  assert.equal(result.type, "stroke_trace");
  assert.equal(result.prompt, "Existing prompt");
  assert.equal(result.promptAudioUrl, "https://example.com/audio.mp3");
  assert.equal(result.createdAt, "existing");
  assert.deepEqual(JSON.parse(result.strokeOrderData), strokeOrderData);
});

test("duplicate mappings point to the valid L4 tracing documents", () => {
  assert.deepEqual([...duplicateQuestionMappings.entries()], [
    ["bc_c1_l4_q01", "bc_c1_l4_trace_tai"],
    ["bc_c1_l4_q02", "bc_c1_l4_trace_tian"],
    ["bc_c1_l4_q03", "bc_c1_l4_trace_yang"],
    ["bc_c1_l4_q04", "bc_c1_l4_trace_xue"],
  ]);
});

test("reference merges add counters without losing target data", () => {
  const bank = mergeReferenceData(
    "wrongAnswerBank",
    {reviewCount: 2, questionId: "old"},
    {reviewCount: 3, lastWrongAt: "target"},
    "replacement",
  );
  assert.equal(bank.reviewCount, 5);
  assert.equal(bank.questionId, "replacement");
  assert.equal(bank.lastWrongAt, "target");

  const stats = mergeReferenceData(
    "questionStats",
    {timesSeen: 2, timesWrong: 1},
    {timesSeen: 4, timesWrong: 3},
    "replacement",
  );
  assert.equal(stats.timesSeen, 6);
  assert.equal(stats.timesWrong, 4);
});

test("attempt question IDs are replaced and deduplicated", () => {
  assert.deepEqual(
    replaceQuestionIds([
      "bc_c1_l4_q01",
      "bc_c1_l4_trace_tai",
      "other",
    ]),
    ["bc_c1_l4_trace_tai", "other"],
  );
});
