"use strict";

const path = require("node:path");
const admin = require("firebase-admin");
const {
  buildRepairedQuestion,
  repairDefinitions,
} = require("./mandarin_non_tracing_repair_lib");

const mode = process.argv[2] ?? "--dry-run";
const validModes = new Set(["--inspect", "--dry-run", "--apply"]);

if (!validModes.has(mode)) {
  console.error(
      "Usage: node functions/scripts/repair_mandarin_non_tracing.js " +
      "[--inspect|--dry-run|--apply]",
  );
  process.exit(1);
}

const projectRoot = path.resolve(__dirname, "..", "..");
let serviceAccount;

try {
  serviceAccount = require(path.join(projectRoot, "service-account.json"));
} catch (_) {
  console.error("Missing service-account.json at the repository root.");
  process.exit(1);
}

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();
const questions = db.collection("questions");

function comparable(value) {
  if (value && typeof value.toDate === "function") {
    return value.toDate().toISOString();
  }
  return value;
}

function diffFields(existing, desired) {
  const keys = new Set([...Object.keys(existing), ...Object.keys(desired)]);
  const changes = [];

  for (const key of [...keys].sort()) {
    const before = comparable(existing[key]);
    const after = comparable(desired[key]);
    if (JSON.stringify(before) !== JSON.stringify(after)) {
      changes.push({field: key, before, after});
    }
  }
  return changes;
}

async function buildPlan() {
  const plan = [];

  for (const definition of repairDefinitions) {
    const reference = questions.doc(definition.id);
    const snapshot = await reference.get();
    const existing = snapshot.exists ? snapshot.data() : null;
    const desired = buildRepairedQuestion(definition, existing);
    plan.push({
      reference,
      desired,
      changes: diffFields(existing, desired),
    });
  }

  return plan;
}

async function main() {
  const plan = await buildPlan();

  for (const item of plan) {
    console.log(`\n${item.reference.id}: UPDATE`);
    if (item.changes.length === 0) {
      console.log("  No changes.");
    } else {
      for (const change of item.changes) {
        console.log(
            `  ${change.field}: ${JSON.stringify(change.before)} -> ` +
            `${JSON.stringify(change.after)}`,
        );
      }
    }
  }

  const changed = plan.filter((item) => item.changes.length > 0);
  console.log(`\nSummary: ${changed.length} question repair(s).`);

  if (mode !== "--apply") {
    console.log(
        mode === "--inspect"
          ? "Inspection complete. No writes performed."
          : "Dry run complete. No writes performed.",
    );
    return;
  }

  const batch = db.batch();
  for (const item of changed) {
    batch.set(item.reference, item.desired);
  }
  await batch.commit();
  console.log(`Applied ${changed.length} Firestore write(s).`);
}

main()
  .catch((error) => {
    console.error(error);
    process.exitCode = 1;
  })
  .finally(async () => {
    await admin.app().delete();
  });
