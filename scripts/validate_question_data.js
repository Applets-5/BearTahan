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
  "fillblanklist",
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
      const inferredType =
        name.includes("tracing") && question.characterUnicode
          ? "stroke_trace"
          : "mcq";
      const type = String(
          question.questionType || question.type || inferredType,
      ).toLowerCase();
      if (!id) errors.push(`${name}: question is missing id`);
      if (!supportedTypes.has(type)) {
        errors.push(`${id}: unsupported question type "${type}"`);
      }
      const options = Array.isArray(question.options) ? question.options : [];
      const optionText = (option) => {
        if (typeof option === "string") return option;
        return String(option?.text ?? option?.label ?? "");
      };
      const optionImage = (option) =>
        typeof option === "object" && option !== null
          ? option.imageUrl ?? option.image ?? null
          : null;
      const prompt = String(question.prompt ?? question.questionText ?? "");

      if (type === "mcq") {
        if (options.length < 2) {
          errors.push(`${id}: mcq requires at least two options`);
        }
        if (options.some((option) => !optionText(option) && !optionImage(option))) {
          errors.push(`${id}: mcq contains an empty option`);
        }
      }
      if (type === "fillblank" || type === "fillblanklistening") {
        const correctBlank = String(question.correctBlank ?? "").trim();
        const hasBlankMarker = /[（(]\s*[）)]|____/.test(prompt);
        const matchingOption = options.some(
            (option) => optionText(option).trim() === correctBlank,
        );
        if (!hasBlankMarker) {
          errors.push(`${id}: fillblank requires a blank marker`);
        }
        if (!correctBlank || !matchingOption) {
          errors.push(`${id}: correctBlank must match option text`);
        }
        if (options.some((option) => !optionText(option) && optionImage(option))) {
          errors.push(`${id}: image-only options must use mcq, not fillblank`);
        }
      }
      if (type === "fillblanklist") {
        const correctOrder = Array.isArray(question.correctOrder)
          ? question.correctOrder
          : [];
        const blankCount = (prompt.match(/[（(]\s*[）)]|___+/g) || []).length;
        if (correctOrder.length === 0) {
          errors.push(`${id}: fillblanklist requires correctOrder`);
        } else if (blankCount > 0 && correctOrder.length !== blankCount) {
          errors.push(
            `${id}: fillblanklist correctOrder length (${correctOrder.length}) does not match blank count (${blankCount})`,
          );
        }
      }
      if (type === "rearrange") {
        const correctOrder = Array.isArray(question.correctOrder)
          ? question.correctOrder.map(String)
          : [];
        const optionTexts = options.map(optionText);
        if (
          correctOrder.length !== optionTexts.length ||
          correctOrder.some((value) => !optionTexts.includes(value))
        ) {
          errors.push(`${id}: rearrange correctOrder must match its options`);
        }
        const repeatedWords = optionTexts.filter(
            (value) => value && prompt.includes(value),
        );
        if (repeatedWords.length >= Math.max(2, optionTexts.length - 1)) {
          errors.push(`${id}: rearrange prompt duplicates draggable words`);
        }
      }
      if (type === "matching") {
        for (const option of options) {
          const hasLeft = Boolean(optionText(option) || optionImage(option));
          const hasRight = Boolean(
              option?.pairText ??
              option?.matchText ??
              option?.pairImageUrl ??
              option?.pairImage ??
              option?.matchImageUrl ??
              optionImage(option),
          );
          if (!hasLeft || !hasRight) {
            errors.push(`${id}: matching options require both sides`);
            break;
          }
        }
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
      if (type === "stroke_trace" && question.characterUnicode) {
        const assetPath = path.join(
            __dirname,
            "..",
            "assets",
            "hanzi",
            `${question.characterUnicode}.json`,
        );
        if (!fs.existsSync(assetPath)) {
          errors.push(
              `${id}: missing Hanzi asset for ${question.characterUnicode}`,
          );
        } else {
          const strokeData = JSON.parse(fs.readFileSync(assetPath, "utf8"));
          const hasValidStrokes =
            Array.isArray(strokeData.strokes) &&
            strokeData.strokes.length > 0 &&
            strokeData.strokes.every(
                (stroke) => typeof stroke === "string" && stroke.length > 0,
            );
          const hasValidMedians =
            Array.isArray(strokeData.medians) &&
            strokeData.medians.length === strokeData.strokes?.length &&
            strokeData.medians.every(
                (median) => Array.isArray(median) && median.length >= 2,
            );
          if (!hasValidStrokes || !hasValidMedians) {
            errors.push(`${id}: invalid stroke geometry`);
          }
        }
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
