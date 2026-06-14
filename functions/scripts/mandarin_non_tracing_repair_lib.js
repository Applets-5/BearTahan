"use strict";

const repairDefinitions =
  require("../data/mandarin_non_tracing_repairs.json");

function optionText(option) {
  if (typeof option === "string") return option;
  return String(option?.text ?? option?.label ?? "");
}

function validateRepairSource(definition, existing) {
  if (!existing) {
    throw new Error(`Missing question ${definition.id}`);
  }

  const options = Array.isArray(existing.options) ? existing.options : [];
  const desiredType = String(
      definition.questionType ?? existing.questionType ?? existing.type ?? "",
  ).toLowerCase();

  if (desiredType === "mcq") {
    if (options.length < 2) {
      throw new Error(`${definition.id} requires at least two MCQ options`);
    }
    if (
      !Number.isInteger(definition.correctAnswerIndex) ||
      definition.correctAnswerIndex < 0 ||
      definition.correctAnswerIndex >= options.length
    ) {
      throw new Error(`${definition.id} has an invalid correct answer index`);
    }
    if (options.some((option) => !optionText(option) && !option?.imageUrl)) {
      throw new Error(`${definition.id} contains an empty MCQ option`);
    }
  }

  if (desiredType === "rearrange") {
    const order = existing.correctOrder;
    const texts = options.map(optionText);
    if (
      !Array.isArray(order) ||
      order.length !== texts.length ||
      order.some((value) => !texts.includes(String(value)))
    ) {
      throw new Error(`${definition.id} has an invalid correctOrder`);
    }
  }
}

function buildRepairedQuestion(definition, existing) {
  validateRepairSource(definition, existing);
  return {
    ...existing,
    ...definition,
    id: definition.id,
    questionText: definition.prompt ?? existing.questionText ?? existing.prompt,
  };
}

module.exports = {
  buildRepairedQuestion,
  repairDefinitions,
  validateRepairSource,
};
