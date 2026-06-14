"use strict";

const assert = require("node:assert/strict");
const test = require("node:test");
const {
  buildRepairedQuestion,
  repairDefinitions,
} = require("../scripts/mandarin_non_tracing_repair_lib");

test("repair definitions cover the malformed presentation questions", () => {
  assert.deepEqual(
      repairDefinitions.map((definition) => definition.id),
      [
        "bc_c1_l3_q07",
        "bc_c1_l3_q08",
        "bc_c1_l4_q05",
        "bc_c1_l4_q06",
        "bc_c1_l4_q07",
        "bc_c1_l4_q08",
        "bc_c1_l4_q09",
      ],
  );
});

test("image radical questions are converted to valid image MCQs", () => {
  const options = ["a", "b", "c", "d"].map((name) => ({
    text: "",
    imageUrl: `https://example.com/${name}.png`,
  }));
  const result = buildRepairedQuestion(repairDefinitions[0], {
    questionType: "fillblank",
    prompt: "old",
    options,
    correctBlank: "https://example.com/a.png",
  });

  assert.equal(result.questionType, "mcq");
  assert.equal(result.type, "mcq");
  assert.equal(result.correctAnswerId, "A");
  assert.equal(result.correctAnswerIndex, 0);
  assert.equal(result.correctBlank, null);
  assert.equal(result.questionText, "选择与图片相同的部首");
  assert.deepEqual(result.options, options);
});

test("rearrange repair removes duplicated words from the prompt", () => {
  const result = buildRepairedQuestion(repairDefinitions[5], {
    questionType: "rearrange",
    prompt: "词句重组 太阳 像 一个 大火球",
    options: ["太阳", "像", "一个", "大火球"],
    correctOrder: ["太阳", "像", "一个", "大火球"],
  });

  assert.equal(result.prompt, "将词语排列成正确的句子");
  assert.equal(result.questionText, "将词语排列成正确的句子");
});

test("fillblank repair keeps only the sentence around the blank", () => {
  const result = buildRepairedQuestion(repairDefinitions[2], {
    questionType: "fillBlank",
    prompt: "阅读句子，根据图意填入正确的词语\n下课了，同学们（ ）食堂吃东西。",
    options: [
      {text: "去"},
      {text: "早上"},
      {text: "门口"},
      {text: "走"},
    ],
    correctBlank: "去",
  });

  assert.equal(result.prompt, "下课了，同学们（ ）食堂吃东西。");
  assert.equal(result.questionText, "下课了，同学们（ ）食堂吃东西。");
});
