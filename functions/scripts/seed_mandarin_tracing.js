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
const tracingPrefix = "bc_c1_l3_trace_";

function desiredIds() {
  return new Set(definitions.map((definition) => definition.id));
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
    levelId: "BC_C1_L3",
    levelNumber: 3,
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

  for (const definition of definitions) {
    const snapshot = await questions.doc(definition.id).get();
    console.log(`\n${definition.id}: ${snapshot.exists ? "exists" : "missing"}`);
    if (snapshot.exists) {
      const data = snapshot.data();
      console.log(Object.keys(data).sort().join(", "));
      console.log(`  prompt: ${JSON.stringify(data.prompt ?? null)}`);
      console.log(`  questionText: ${JSON.stringify(data.questionText ?? null)}`);
      console.log(`  promptAudioUrl: ${JSON.stringify(data.promptAudioUrl ?? null)}`);
    }
  }

  if (obsolete.length > 0) {
    console.log("\nObsolete tracing docs currently under bc_c1_l3_trace_:");
    for (const doc of obsolete) {
      console.log(`  ${doc.id}`);
    }
  }
}

async function dryRun() {
  let changedCount = 0;
  const obsolete = await getObsoleteTracingDocs();

  for (const definition of definitions) {
    const snapshot = await questions.doc(definition.id).get();
    const existing = snapshot.exists ? snapshot.data() : null;
    const desired = buildQuestion(definition, existing);
    const changes = diffFields(existing, desired);

    console.log(`\n${definition.id}: ${snapshot.exists ? "UPDATE" : "CREATE"}`);
    if (changes.length === 0) {
      console.log("  No changes.");
      continue;
    }

    changedCount++;
    for (const change of changes) {
      console.log(
        `  ${change.field}: ${JSON.stringify(change.before)} -> ${JSON.stringify(change.after)}`,
      );
    }
  }

  for (const doc of obsolete) {
    changedCount++;
    console.log(`\n${doc.id}: DELETE`);
    console.log("  Obsolete stroke_trace doc under bc_c1_l3_trace_.");
  }

  console.log(`\nDry run complete. ${changedCount} document(s) would change.`);
}

async function apply() {
  const batch = db.batch();
  const obsolete = await getObsoleteTracingDocs();

  for (const definition of definitions) {
    const reference = questions.doc(definition.id);
    const snapshot = await reference.get();
    const existing = snapshot.exists ? snapshot.data() : null;
    batch.set(reference, buildQuestion(definition, existing));
  }

  for (const doc of obsolete) {
    batch.delete(doc.ref);
  }

  await batch.commit();
  console.log(
    `Applied ${definitions.length} Mandarin tracing document(s), deleted ${obsolete.length} obsolete document(s).`,
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
