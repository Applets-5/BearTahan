"use strict";

const demoOutfitIds = new Set([
  "chef_bear",
  "astro_bear",
  "super_bear",
  "explorer_bear",
]);

function normalizeSubjectId(value) {
  const subjectId = String(value ?? "").toLowerCase();
  if (subjectId === "en" || subjectId === "english") return "bi";
  if (subjectId === "science") return "sci";
  return subjectId;
}

function calculateQuestCurrentValue({
  quest,
  child,
  subjectProgress,
  attempts,
}) {
  const subjectId = normalizeSubjectId(quest.subjectId);
  const progress = subjectProgress[subjectId] ?? {};

  switch (quest.conditionType) {
    case "starter":
      return Number(quest.target ?? 0);
    case "completed_lessons":
      return Number(progress.completedLevels ?? 0);
    case "perfect_quizzes":
      return attempts.filter((attempt) => {
        const score = Number(attempt.score ?? 0);
        const total = Number(attempt.total ?? 0);
        return normalizeSubjectId(attempt.subjectId) === subjectId &&
          total > 0 &&
          score === total;
      }).length;
    case "total_stars":
      return Number(
          child.lifetimeStarsEarned ??
          child.availableStars ??
          child.starBalance ??
          child.stars ??
          0,
      );
    case "complete_all_topics":
      return Number(progress.progress ?? 0) >= 100
        ? Number(quest.target ?? 0)
        : Number(progress.completedLevels ?? 0);
    default:
      return 0;
  }
}

function buildApplyUpdate({quest, existingProgress}) {
  if (!demoOutfitIds.has(quest.id)) return null;
  if (existingProgress?.isUnlocked === true) {
    return {skip: "already unlocked"};
  }
  const targetValue = Number(quest.target ?? 0);
  if (
    existingProgress?.demoEligibilityOverride === true &&
    Number(existingProgress.currentValue ?? 0) === targetValue &&
    Number(existingProgress.targetValue ?? 0) === targetValue
  ) {
    return {skip: "override already enabled"};
  }

  return {
    demoEligibilityOverride: true,
    currentValue: targetValue,
    targetValue,
    isUnlocked: false,
  };
}

function buildClearUpdate({
  quest,
  existingProgress,
  actualCurrentValue,
}) {
  if (!demoOutfitIds.has(quest.id)) return null;
  if (existingProgress?.demoEligibilityOverride !== true) {
    return {skip: "override not set"};
  }

  return {
    removeDemoEligibilityOverride: true,
    currentValue: actualCurrentValue,
    targetValue: Number(quest.target ?? 0),
  };
}

module.exports = {
  buildApplyUpdate,
  buildClearUpdate,
  calculateQuestCurrentValue,
  demoOutfitIds,
  normalizeSubjectId,
};
