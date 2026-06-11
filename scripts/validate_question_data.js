"use strict";

const fs = require("fs");
const path = require("path");

const roots = [
  path.join(__dirname),
  path.join(__dirname, "..", "functions", "data"),
];
const supportedTypes = new Set([
  "mcq",
  "fillblank",
  "fillblanklistening",
  "rearrange",
  "dragdropspelling",
  "matching",
  "stroke_trace",
  "keyinnumber",
]);

const errors = [];
let count = 0;

for (const root of roots) {
  if (!fs.existsSync(root)) continue;
  for (const name of fs.readdirSync(root)) {
    if (!name.endsWith(".json") || !name.includes("question")) continue;
    const file = path.join(root, name);
    const questions = JSON.parse(fs.readFileSync(file, "utf8"));
    if (!Array.isArray(questions)) continue;

    for (const question of questions) {
      count++;
      const id = String(question.id || "");
      const type = String(question.questionType || question.type || "mcq")
          .toLowerCase();
      if (!id) errors.push(`${name}: question is missing id`);
      if (!supportedTypes.has(type)) {
        errors.push(`${id}: unsupported question type "${type}"`);
      }
      if (type === "keyinnumber") {
        const answer =
          question.correctNumber ??
          question.correctAnswer ??
          question.correctAnswerId ??
          question.correctBlank ??
          question.answer;
        if (!Number.isInteger(Number(answer)) || Number(answer) < 0) {
          errors.push(`${id}: keyinnumber requires a non-negative integer`);
        }
      }
      if (type === "stroke_trace" && !question.characterUnicode) {
        errors.push(`${id}: stroke_trace requires characterUnicode`);
      }
    }
  }
}

const outfitSource = fs.readFileSync(
    path.join(__dirname, "..", "lib", "models", "outfit_quest.dart"),
    "utf8",
);
if (/subjectId:\s*'(en|science)'/.test(outfitSource)) {
  errors.push("Outfit quest defaults use non-canonical subject IDs");
}

if (errors.length > 0) {
  console.error(errors.join("\n"));
  process.exitCode = 1;
} else {
  console.log(`Validated ${count} question definitions and outfit subject IDs.`);
}
