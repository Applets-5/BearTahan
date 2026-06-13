"use strict";

const repairedQuestions =
  require("../data/mandarin_stroke_repair_questions.json");

const duplicateQuestionMappings = new Map([
  ["bc_c1_l4_q01", "bc_c1_l4_trace_tai"],
  ["bc_c1_l4_q02", "bc_c1_l4_trace_tian"],
  ["bc_c1_l4_q03", "bc_c1_l4_trace_yang"],
  ["bc_c1_l4_q04", "bc_c1_l4_trace_xue"],
]);

function validateStrokeOrderData(data) {
  return Boolean(
    data &&
      Array.isArray(data.strokes) &&
      data.strokes.length > 0 &&
      Array.isArray(data.medians) &&
      data.medians.length === data.strokes.length &&
      data.strokes.every(
        (stroke) => typeof stroke === "string" && stroke.length > 0,
      ) &&
      data.medians.every(
        (median) =>
          Array.isArray(median) &&
          median.length >= 2 &&
          median.every(
            (point) =>
              Array.isArray(point) &&
              point.length === 2 &&
              point.every(Number.isFinite),
          ),
      ),
  );
}

function buildRepairedQuestion(
  definition,
  existingData,
  strokeOrderData,
  createdAtFallback,
) {
  if (!validateStrokeOrderData(strokeOrderData)) {
    throw new Error(
      `Invalid stroke order data for ${definition.characterUnicode}`,
    );
  }

  return {
    ...(existingData ?? {}),
    id: definition.id,
    subjectId: "BC",
    chapterId: "BC_C1",
    levelId: "BC_C1_L3",
    levelNumber: 3,
    difficulty: definition.difficulty,
    prompt: existingData?.prompt ?? definition.prompt,
    questionText:
      existingData?.questionText ??
      existingData?.prompt ??
      definition.prompt,
    questionType: "stroke_trace",
    type: "stroke_trace",
    characterUnicode: definition.characterUnicode,
    strokeOrderData: JSON.stringify(strokeOrderData),
    imageMode: "none",
    imageUrl: null,
    options: [],
    correctAnswerId: "A",
    correctAnswerIndex: 0,
    correctBlank: null,
    correctOrder: null,
    createdAt: existingData?.createdAt ?? createdAtFallback,
  };
}

function mergeReferenceData(
  collectionName,
  sourceData,
  targetData,
  targetQuestionId,
) {
  if (collectionName === "wrongAnswerBank") {
    return {
      ...sourceData,
      ...targetData,
      questionId: targetQuestionId,
      levelId: "c1_l4",
      reviewCount:
        Number(sourceData?.reviewCount ?? 0) +
        Number(targetData?.reviewCount ?? 0),
    };
  }

  if (collectionName === "questionStats") {
    return {
      ...sourceData,
      ...targetData,
      timesSeen:
        Number(sourceData?.timesSeen ?? 0) +
        Number(targetData?.timesSeen ?? 0),
      timesWrong:
        Number(sourceData?.timesWrong ?? 0) +
        Number(targetData?.timesWrong ?? 0),
    };
  }

  throw new Error(`Unsupported reference collection: ${collectionName}`);
}

function replaceQuestionIds(values, mappings = duplicateQuestionMappings) {
  if (!Array.isArray(values)) return values;

  return [
    ...new Set(values.map((value) => mappings.get(value) ?? value)),
  ];
}

module.exports = {
  buildRepairedQuestion,
  duplicateQuestionMappings,
  mergeReferenceData,
  repairedQuestions,
  replaceQuestionIds,
  validateStrokeOrderData,
};
