"use strict";

const path = require("path");
const admin = require("firebase-admin");
const fs = require("fs");

const projectRoot = path.resolve(__dirname, "..", "..");
const serviceAccountPath = path.join(projectRoot, "service-account.json");
const definitions = require("../data/mandarin_tracing_questions.json");

const mode = process.argv[2] ?? "--dry-run";
const validModes = new Set(["--inspect", "--dry-run", "--apply"]);

if (!validModes.has(mode)) {
  console.error("Usage: node functions/scripts/seed_mandarin_tracing.js [--inspect|--dry-run|--apply]");
  process.exit(1);
}

let serviceAccount;
try {
  serviceAccount = require(serviceAccountPath);
} catch (_) {
  console.error("Missing service-account.json at the repository root.");
  process.exit(1);
}

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();
const questions = db.collection("questions");
const tracingPrefix = "bc_c1_l4_trace_";
const legacyTracingPrefix = "bc_c1_l3_trace_";
const targetLevelId = "BC_C1_L4";
const targetLevelNumber = 4;
const targetProgressLevelId = "c1_l4";
const legacyProgressLevelId = "c1_l3";

function desiredIds() {
  return new Set(definitions.map((definition) => definition.id));
}

function legacyQuestionId(definition) {
  return definition.id.replace(tracingPrefix, legacyTracingPrefix);
}

function isTracingQuestion(data) {
  return data?.type === "stroke_trace" || data?.questionType === "stroke_trace";
}

function loadStrokeOrderData(character) {
  const assetPath = path.join(projectRoot, "assets", "hanzi", `${character}.json`);
  const strokeOrderData = JSON.parse(fs.readFileSync(assetPath, "utf8"));
  return JSON.stringify(strokeOrderData);
}

function buildQuestion(definition, existingData) {
  const promptChanged =
    existingData?.prompt !== definition.prompt ||
    existingData?.questionText !== definition.prompt;
  const strokeOrderData = loadStrokeOrderData(definition.characterUnicode);

  return {
    ...(existingData ?? {}),
    id: definition.id,
    subjectId: "BC",
    chapterId: "BC_C1",
    levelId: targetLevelId,
    levelNumber: targetLevelNumber,
    difficulty: 1,
    prompt: definition.prompt,
    questionText: definition.prompt,
    lesson: definition.lesson ?? existingData?.lesson ?? null,
    strokeOrderData,
    questionType: "stroke_trace",
    type: "stroke_trace",
    characterUnicode: definition.characterUnicode,
    correctAnswerId: "A",
    correctAnswerIndex: 0,
    correctBlank: null,
    correctOrder: null,
    imageMode: "none",
    imageUrl: null,
    promptAudioUrl: promptChanged ? null : existingData?.promptAudioUrl ?? null,
    options: [],
    createdAt: existingData?.createdAt ?? admin.firestore.FieldValue.serverTimestamp(),
  };
}

function comparable(value) {
  if (value && typeof value.toDate === "function") {
    return value.toDate().toISOString();
  }
  if (value && value.isEqual && value.constructor?.name === "FieldValue") {
    return "<server timestamp>";
  }
  return value;
}

function diffFields(existing, desired) {
  const keys = new Set([...Object.keys(existing ?? {}), ...Object.keys(desired)]);
  const changes = [];

  for (const key of [...keys].sort()) {
    if (key === "createdAt" && existing?.createdAt) continue;
    const before = comparable(existing?.[key]);
    const after = comparable(desired[key]);
    if (JSON.stringify(before) !== JSON.stringify(after)) {
      changes.push({field: key, before, after});
    }
  }

  return changes;
}

async function inspect() {
  const obsolete = await getObsoleteTracingDocs();
  const legacyDocs = await getLegacyTracingDocs();

  for (const definition of definitions) {
    const snapshot = await questions.doc(definition.id).get();
    const legacySnapshot = await questions.doc(legacyQuestionId(definition)).get();
    console.log(
      `\n${definition.id}: ${snapshot.exists ? "exists" : "missing"}` +
        ` (legacy: ${legacySnapshot.exists ? "exists" : "missing"})`,
    );
    if (snapshot.exists) {
      const data = snapshot.data();
      console.log(Object.keys(data).sort().join(", "));
      console.log(`  prompt: ${JSON.stringify(data.prompt ?? null)}`);
      console.log(`  questionText: ${JSON.stringify(data.questionText ?? null)}`);
      console.log(`  promptAudioUrl: ${JSON.stringify(data.promptAudioUrl ?? null)}`);
    }
  }

  if (obsolete.length > 0) {
    console.log(`\nObsolete tracing docs currently under ${tracingPrefix}:`);
    for (const doc of obsolete) {
      console.log(`  ${doc.id}`);
    }
  }

  await inspectChildMigrations(legacyDocs.length > 0);
}

async function dryRun() {
  let changedCount = 0;
  const obsolete = await getObsoleteTracingDocs();
  const legacyDocs = await getLegacyTracingDocs();
  const childMigrations = await getChildMigrations({
    migrateLevelProgress: legacyDocs.length > 0,
  });

  for (const definition of definitions) {
    const snapshot = await questions.doc(definition.id).get();
    const legacySnapshot = await questions.doc(legacyQuestionId(definition)).get();
    const existing = snapshot.exists
      ? snapshot.data()
      : legacySnapshot.exists
        ? legacySnapshot.data()
        : null;
    const desired = buildQuestion(definition, existing);
    const changes = diffFields(existing, desired);

    const action = snapshot.exists
      ? "UPDATE"
      : legacySnapshot.exists
        ? "MOVE"
        : "CREATE";
    console.log(`\n${definition.id}: ${action}`);
    if (changes.length === 0) {
      console.log("  No changes.");
    } else {
      changedCount++;
      for (const change of changes) {
        console.log(
          `  ${change.field}: ${JSON.stringify(change.before)} -> ${JSON.stringify(change.after)}`,
        );
      }
    }

    if (legacySnapshot.exists) {
      changedCount++;
      console.log(`  Delete legacy document: ${legacySnapshot.id}`);
    }
  }

  for (const doc of obsolete) {
    changedCount++;
    console.log(`\n${doc.id}: DELETE`);
    console.log(`  Obsolete stroke_trace doc under ${tracingPrefix}.`);
  }

  for (const [index, migration] of childMigrations.entries()) {
    changedCount += migration.operations.length;
    console.log(`\nChild profile ${index + 1}:`);
    for (const operation of migration.operations) {
      console.log(`  ${operation}`);
    }
  }

  console.log(`\nDry run complete. ${changedCount} document(s) would change.`);
}

async function apply() {
  const batch = db.batch();
  const obsolete = await getObsoleteTracingDocs();
  const legacyDocs = await getLegacyTracingDocs();
  const childMigrations = await getChildMigrations({
    migrateLevelProgress: legacyDocs.length > 0,
  });

  for (const definition of definitions) {
    const reference = questions.doc(definition.id);
    const snapshot = await reference.get();
    const legacyReference = questions.doc(legacyQuestionId(definition));
    const legacySnapshot = await legacyReference.get();
    const existing = snapshot.exists
      ? snapshot.data()
      : legacySnapshot.exists
        ? legacySnapshot.data()
        : null;
    batch.set(reference, buildQuestion(definition, existing));
    if (legacySnapshot.exists) {
      batch.delete(legacyReference);
    }
  }

  for (const doc of obsolete) {
    batch.delete(doc.ref);
  }

  for (const migration of childMigrations) {
    for (const write of migration.writes) {
      if (write.type === "set") {
        batch.set(write.reference, write.data);
      } else {
        batch.delete(write.reference);
      }
    }
  }

  await batch.commit();
  console.log(
    `Applied ${definitions.length} Mandarin tracing document(s), ` +
      `deleted ${obsolete.length} obsolete target document(s), and ` +
      `migrated ${childMigrations.length} child profile(s).`,
  );
}

async function getObsoleteTracingDocs() {
  const desired = desiredIds();
  const snapshot = await questions
    .where(admin.firestore.FieldPath.documentId(), ">=", tracingPrefix)
    .where(admin.firestore.FieldPath.documentId(), "<", `${tracingPrefix}\uf8ff`)
    .get();

  return snapshot.docs.filter((doc) => {
    if (desired.has(doc.id)) return false;
    return isTracingQuestion(doc.data());
  });
}

async function getLegacyTracingDocs() {
  const snapshots = await Promise.all(
    definitions.map((definition) =>
      questions.doc(legacyQuestionId(definition)).get(),
    ),
  );
  return snapshots.filter((snapshot) => snapshot.exists);
}

async function inspectChildMigrations(migrateLevelProgress) {
  const migrations = await getChildMigrations({migrateLevelProgress});
  console.log(`\nChild profiles requiring migration: ${migrations.length}`);
  for (const [index, migration] of migrations.entries()) {
    console.log(
      `  Profile ${index + 1}: ${migration.operations.join("; ")}`,
    );
  }
}

async function getChildMigrations({migrateLevelProgress}) {
  const mappings = new Map(
    definitions.map((definition) => [
      legacyQuestionId(definition),
      definition.id,
    ]),
  );
  const parentsSnapshot = await db.collection("parents").get();
  const migrations = [];

  for (const parentDoc of parentsSnapshot.docs) {
    const childrenSnapshot = await parentDoc.ref.collection("children").get();

    for (const childDoc of childrenSnapshot.docs) {
      const writes = [];
      const operations = [];
      const levelsRef = childDoc.ref
        .collection("subjectProgress")
        .doc("bc")
        .collection("levels");
      const legacyProgress = await levelsRef.doc(legacyProgressLevelId).get();
      const targetProgress = await levelsRef.doc(targetProgressLevelId).get();

      if (migrateLevelProgress && legacyProgress.exists) {
        const legacyData = legacyProgress.data();
        const targetData = targetProgress.data() ?? {};
        const mergedProgress = {
          ...legacyData,
          ...targetData,
          stars: Math.max(legacyData?.stars ?? 0, targetData.stars ?? 0),
        };
        writes.push({
          type: "set",
          reference: levelsRef.doc(targetProgressLevelId),
          data: mergedProgress,
        });
        writes.push({
          type: "delete",
          reference: levelsRef.doc(legacyProgressLevelId),
        });
        operations.push(
          `move BC progress ${legacyProgressLevelId} -> ${targetProgressLevelId}`,
        );
      }

      for (const collectionName of ["wrongAnswerBank", "questionStats"]) {
        const collectionRef = childDoc.ref.collection(collectionName);
        const snapshot = await collectionRef.get();

        for (const doc of snapshot.docs) {
          const targetQuestionId = mappings.get(doc.id);
          if (!targetQuestionId) continue;

          const targetRef = collectionRef.doc(targetQuestionId);
          const targetSnapshot = await targetRef.get();
          const legacyData = doc.data();
          const targetData = targetSnapshot.data() ?? {};
          const mergedData = {
            ...legacyData,
            ...targetData,
            ...(collectionName === "wrongAnswerBank"
              ? {
                  questionId: targetQuestionId,
                  levelId: targetProgressLevelId,
                  reviewCount:
                    (legacyData.reviewCount ?? 0) +
                    (targetData.reviewCount ?? 0),
                }
              : {
                  timesSeen:
                    (legacyData.timesSeen ?? 0) + (targetData.timesSeen ?? 0),
                  timesWrong:
                    (legacyData.timesWrong ?? 0) +
                    (targetData.timesWrong ?? 0),
                }),
          };

          writes.push({type: "set", reference: targetRef, data: mergedData});
          writes.push({type: "delete", reference: doc.ref});
          operations.push(
            `move ${collectionName}/${doc.id} -> ${targetQuestionId}`,
          );
        }
      }

      if (writes.length > 0) {
        migrations.push({childId: childDoc.id, writes, operations});
      }
    }
  }

  return migrations;
}

async function main() {
  if (mode === "--inspect") {
    await inspect();
  } else if (mode === "--apply") {
    await dryRun();
    console.log("\nApplying reviewed changes...");
    await apply();
  } else {
    await dryRun();
  }
}

main()
  .catch((error) => {
    console.error(error);
    process.exitCode = 1;
  })
  .finally(async () => {
    await admin.app().delete();
  });
