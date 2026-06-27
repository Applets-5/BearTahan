"use strict";

const admin = require("firebase-admin");

const args = new Set(process.argv.slice(2));
const apply = args.has("--apply");
const dryRun = !apply;

admin.initializeApp();
const db = admin.firestore();

function normalizeSubjectId(value) {
  if (value === "en" || value === "english") return "bi";
  if (value === "science") return "sci";
  return value;
}

function normalizeLevelId(value) {
  return /^l\d+$/.test(value) ? `c1_${value}` : value;
}

async function setIfApplying(ref, data) {
  console.log(`${dryRun ? "WOULD WRITE" : "WRITE"} ${ref.path}`);
  if (!dryRun) await ref.set(data, {merge: true});
}

async function migrateOutfitQuests() {
  const snapshot = await db.collection("outfitQuests").get();
  for (const doc of snapshot.docs) {
    const subjectId = doc.data().subjectId;
    const normalized = normalizeSubjectId(subjectId);
    if (normalized !== subjectId) {
      await setIfApplying(doc.ref, {subjectId: normalized});
    }
  }
}

async function recalculateSubject(childDoc, subjectId) {
  const chapters = await db
      .collection("subjects")
      .doc(subjectId)
      .collection("chapters")
      .get();
  if (chapters.empty) {
    console.log(`SKIP aggregate without chapter config: ${subjectId}`);
    return;
  }

  const validIds = new Set();
  for (const chapter of chapters.docs) {
    for (const levelId of chapter.data().levelIds || []) {
      validIds.add(normalizeLevelId(levelId));
    }
    validIds.add(`${chapter.id}_summary`);
  }

  const subjectRef = childDoc.ref.collection("subjectProgress").doc(subjectId);
  const levels = await subjectRef.collection("levels").get();
  const starsByLevel = new Map();
  for (const level of levels.docs) {
    const levelId = normalizeLevelId(level.id);
    if (!validIds.has(levelId)) continue;
    starsByLevel.set(
        levelId,
        Math.max(
            Number(level.data().stars || 0),
            Number(starsByLevel.get(levelId) || 0),
        ),
    );
  }

  const earned = [...starsByLevel.values()].filter((stars) => stars > 0);
  const completedLevels = earned.length;
  const totalStars = earned.reduce((sum, stars) => sum + stars, 0);
  const progress = validIds.size === 0 ?
    0 :
    Math.floor((completedLevels / validIds.size) * 100);

  await setIfApplying(subjectRef, {
    completedLevels,
    totalStars,
    progress: Math.min(progress, 100),
    allChaptersComplete:
      validIds.size > 0 && completedLevels >= validIds.size,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
}

async function migrateChild(parentDoc, childDoc) {
  const subjects = await childDoc.ref.collection("subjectProgress").get();

  for (const subjectDoc of subjects.docs) {
    const normalizedSubjectId = normalizeSubjectId(subjectDoc.id);
    const targetSubjectRef = childDoc.ref
        .collection("subjectProgress")
        .doc(normalizedSubjectId);
    const levels = await subjectDoc.ref.collection("levels").get();

    for (const levelDoc of levels.docs) {
      const normalizedLevelId = normalizeLevelId(levelDoc.id);
      if (
        normalizedSubjectId === subjectDoc.id &&
        normalizedLevelId === levelDoc.id
      ) {
        continue;
      }

      const targetRef = targetSubjectRef
          .collection("levels")
          .doc(normalizedLevelId);
      const target = await targetRef.get();
      const sourceData = levelDoc.data();
      const targetData = target.data() || {};
      await setIfApplying(targetRef, {
        ...sourceData,
        stars: Math.max(
            Number(sourceData.stars || 0),
            Number(targetData.stars || 0),
        ),
        migratedFrom: levelDoc.ref.path,
        migratedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
  }

  const claims = await childDoc.ref
      .collection("rewardClaims")
      .where("status", "==", "pending")
      .get();
  for (const claim of claims.docs) {
    const rewardId = claim.data().rewardId;
    if (!rewardId) continue;
    await setIfApplying(
        childDoc.ref.collection("rewardClaimLocks").doc(rewardId),
        {
          claimId: claim.id,
          status: "pending",
          migratedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
    );
  }

  const subjectIds = new Set(
      subjects.docs.map((doc) => normalizeSubjectId(doc.id)),
  );
  for (const subjectId of subjectIds) {
    await recalculateSubject(childDoc, subjectId);
  }
}

async function main() {
  console.log(`Sprint 3 migration mode: ${dryRun ? "DRY RUN" : "APPLY"}`);
  await migrateOutfitQuests();

  const parents = await db.collection("parents").get();
  for (const parent of parents.docs) {
    const children = await parent.ref.collection("children").get();
    for (const child of children.docs) {
      await migrateChild(parent, child);
    }
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
