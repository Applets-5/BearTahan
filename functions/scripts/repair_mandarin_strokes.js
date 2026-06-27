"use strict";

const fs = require("fs");
const path = require("path");
const admin = require("firebase-admin");
const {
  buildRepairedQuestion,
  duplicateQuestionMappings,
  mergeReferenceData,
  repairedQuestions,
  replaceQuestionIds,
} = require("./mandarin_stroke_repair_lib");

const mode = process.argv[2] ?? "--dry-run";
const validModes = new Set(["--inspect", "--dry-run", "--apply"]);

if (!validModes.has(mode)) {
  console.error(
    "Usage: node functions/scripts/repair_mandarin_strokes.js " +
      "[--inspect|--dry-run|--apply]",
  );
  process.exit(1);
}

const projectRoot = path.resolve(__dirname, "..", "..");
const serviceAccountPath = path.join(projectRoot, "service-account.json");
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

function loadStrokeOrderData(character) {
  const assetPath = path.join(
    projectRoot,
    "assets",
    "hanzi",
    `${character}.json`,
  );
  return JSON.parse(fs.readFileSync(assetPath, "utf8"));
}

function comparable(value) {
  if (value && typeof value.toDate === "function") {
    return value.toDate().toISOString();
  }
  if (value && value.constructor?.name === "FieldValue") {
    return "<server timestamp>";
  }
  return value;
}

function diffFields(existing, desired) {
  const keys = new Set([
    ...Object.keys(existing ?? {}),
    ...Object.keys(desired),
  ]);
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

async function getQuestionPlan() {
  const repairs = [];
  const deletions = [];

  for (const definition of repairedQuestions) {
    const snapshot = await questions.doc(definition.id).get();
    const existing = snapshot.data() ?? null;
    const desired = buildRepairedQuestion(
      definition,
      existing,
      loadStrokeOrderData(definition.characterUnicode),
      admin.firestore.FieldValue.serverTimestamp(),
    );
    repairs.push({
      reference: questions.doc(definition.id),
      existing,
      desired,
      changes: diffFields(existing, desired),
    });
  }

  for (const [sourceId, targetId] of duplicateQuestionMappings) {
    const [source, target] = await Promise.all([
      questions.doc(sourceId).get(),
      questions.doc(targetId).get(),
    ]);
    if (!target.exists) {
      throw new Error(
        `Cannot delete ${sourceId}: replacement ${targetId} is missing`,
      );
    }
    deletions.push({
      sourceId,
      targetId,
      reference: source.ref,
      exists: source.exists,
    });
  }

  return {repairs, deletions};
}

async function getChildReferencePlan() {
  const parents = await db.collection("parents").get();
  const writes = [];
  const operations = [];

  for (const parent of parents.docs) {
    const children = await parent.ref.collection("children").get();

    for (const child of children.docs) {
      for (const collectionName of ["wrongAnswerBank", "questionStats"]) {
        const collectionRef = child.ref.collection(collectionName);
        const snapshot = await collectionRef.get();

        for (const document of snapshot.docs) {
          const sourceData = document.data();
          const targetQuestionId =
            duplicateQuestionMappings.get(document.id) ??
            duplicateQuestionMappings.get(sourceData.questionId);
          if (!targetQuestionId) continue;

          const targetRef = collectionRef.doc(targetQuestionId);
          const target = await targetRef.get();
          writes.push({
            type: "set",
            reference: targetRef,
            data: mergeReferenceData(
              collectionName,
              sourceData,
              target.data() ?? {},
              targetQuestionId,
            ),
          });
          if (document.ref.path !== targetRef.path) {
            writes.push({type: "delete", reference: document.ref});
          }
          operations.push(
            `${child.id}: ${collectionName}/${document.id} -> ` +
              targetQuestionId,
          );
        }
      }

      const attempts = await child.ref.collection("attempts").get();
      for (const attempt of attempts.docs) {
        const data = attempt.data();
        const updates = {};

        for (const field of [
          "wrongAnswerQuestionIDs",
          "wrongAnswerQuestionIds",
        ]) {
          const current = data[field];
          const replaced = replaceQuestionIds(current);
          if (
            Array.isArray(current) &&
            JSON.stringify(current) !== JSON.stringify(replaced)
          ) {
            updates[field] = replaced;
          }
        }

        if (Object.keys(updates).length > 0) {
          writes.push({
            type: "set",
            reference: attempt.ref,
            data: updates,
            merge: true,
          });
          operations.push(`${child.id}: update attempts/${attempt.id}`);
        }
      }
    }
  }

  return {writes, operations};
}

function printPlan(questionPlan, childPlan) {
  for (const repair of questionPlan.repairs) {
    console.log(`\n${repair.reference.id}: UPDATE`);
    if (repair.changes.length === 0) {
      console.log("  No changes.");
    } else {
      for (const change of repair.changes) {
        console.log(
          `  ${change.field}: ${JSON.stringify(change.before)} -> ` +
            `${JSON.stringify(change.after)}`,
        );
      }
    }
  }

  for (const deletion of questionPlan.deletions) {
    console.log(
      `\n${deletion.sourceId}: ${deletion.exists ? "DELETE" : "MISSING"}`,
    );
    console.log(`  Replacement: ${deletion.targetId}`);
  }

  console.log(
    `\nChild reference operations: ${childPlan.operations.length}`,
  );
  for (const operation of childPlan.operations) {
    console.log(`  ${operation}`);
  }
}

async function commitWrites(writes) {
  const chunkSize = 400;
  for (let index = 0; index < writes.length; index += chunkSize) {
    const batch = db.batch();
    for (const write of writes.slice(index, index + chunkSize)) {
      if (write.type === "delete") {
        batch.delete(write.reference);
      } else if (write.merge) {
        batch.set(write.reference, write.data, {merge: true});
      } else {
        batch.set(write.reference, write.data);
      }
    }
    await batch.commit();
  }
}

async function main() {
  const questionPlan = await getQuestionPlan();
  const childPlan = await getChildReferencePlan();
  printPlan(questionPlan, childPlan);

  const changedRepairs = questionPlan.repairs.filter(
    (repair) => repair.changes.length > 0,
  );
  const existingDeletions = questionPlan.deletions.filter(
    (deletion) => deletion.exists,
  );

  console.log(
    `\nSummary: ${changedRepairs.length} question repair(s), ` +
      `${existingDeletions.length} duplicate deletion(s), ` +
      `${childPlan.operations.length} child reference operation(s).`,
  );

  if (mode !== "--apply") {
    console.log(
      mode === "--inspect"
        ? "Inspection complete. No writes performed."
        : "Dry run complete. No writes performed.",
    );
    return;
  }

  const writes = [
    ...questionPlan.repairs.map((repair) => ({
      type: "set",
      reference: repair.reference,
      data: repair.desired,
    })),
    ...questionPlan.deletions
      .filter((deletion) => deletion.exists)
      .map((deletion) => ({
        type: "delete",
        reference: deletion.reference,
      })),
    ...childPlan.writes,
  ];
  await commitWrites(writes);
  console.log(`Applied ${writes.length} Firestore write(s).`);
}

main()
  .catch((error) => {
    console.error(error);
    process.exitCode = 1;
  })
  .finally(async () => {
    await admin.app().delete();
  });
