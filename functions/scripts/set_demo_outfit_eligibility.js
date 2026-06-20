"use strict";

const path = require("node:path");
const admin = require("firebase-admin");
const {
  buildApplyUpdate,
  buildClearUpdate,
  calculateQuestCurrentValue,
  demoOutfitIds,
  normalizeSubjectId,
} = require("./demo_outfit_eligibility_lib");

const args = process.argv.slice(2);
const mode = args.find((value) =>
  ["--dry-run", "--apply", "--clear"].includes(value),
) ?? "--dry-run";
const nameIndex = args.indexOf("--child-name");
const childName = nameIndex >= 0 ? args[nameIndex + 1] : null;

if (!childName) {
  console.error(
      "Usage: node scripts/set_demo_outfit_eligibility.js " +
      "[--dry-run|--apply|--clear] --child-name <name>",
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

async function findChildByName(name) {
  const matches = [];
  const parents = await db.collection("parents").get();

  for (const parent of parents.docs) {
    const children = await parent.ref.collection("children").get();
    for (const child of children.docs) {
      const data = child.data();
      const actualName = String(data.name ?? data.displayName ?? "");
      if (actualName.toLowerCase() === name.toLowerCase()) {
        matches.push({parent, child, data});
      }
    }
  }

  if (matches.length !== 1) {
    throw new Error(
        `Expected exactly one child named "${name}", found ${matches.length}.`,
    );
  }
  return matches[0];
}

async function loadContext(match) {
  const childRef = match.child.ref;
  const [questSnapshot, subjectSnapshot, attemptSnapshot, progressSnapshot] =
    await Promise.all([
      db.collection("outfitQuests").orderBy("displayOrder").get(),
      childRef.collection("subjectProgress").get(),
      childRef.collection("attempts").get(),
      childRef.collection("questProgress").get(),
    ]);

  const quests = questSnapshot.docs.map((doc) => ({
    id: doc.id,
    ...doc.data(),
  }));
  const subjectProgress = {};
  for (const doc of subjectSnapshot.docs) {
    const subjectId = normalizeSubjectId(doc.id);
    const data = doc.data();
    const current = subjectProgress[subjectId];
    if (
      !current ||
      Number(data.completedLevels ?? 0) >
        Number(current.completedLevels ?? 0)
    ) {
      subjectProgress[subjectId] = data;
    }
  }

  return {
    quests,
    subjectProgress,
    attempts: attemptSnapshot.docs.map((doc) => doc.data()),
    progress: Object.fromEntries(
        progressSnapshot.docs.map((doc) => [doc.id, doc.data()]),
    ),
  };
}

function printableUpdate(update) {
  if (!update || update.skip) return update;
  const result = {...update};
  if (result.removeDemoEligibilityOverride) {
    result.demoEligibilityOverride = "<delete>";
    delete result.removeDemoEligibilityOverride;
  }
  return result;
}

async function main() {
  const match = await findChildByName(childName);
  const context = await loadContext(match);
  const operations = [];

  for (const quest of context.quests) {
    if (!demoOutfitIds.has(quest.id)) continue;

    const existingProgress = context.progress[quest.id] ?? {};
    const actualCurrentValue = calculateQuestCurrentValue({
      quest,
      child: match.data,
      subjectProgress: context.subjectProgress,
      attempts: context.attempts,
    });
    const update = mode === "--clear"
      ? buildClearUpdate({quest, existingProgress, actualCurrentValue})
      : buildApplyUpdate({quest, existingProgress});

    operations.push({quest, update});
    console.log(
        `${quest.id}: ${JSON.stringify(printableUpdate(update))}`,
    );
  }

  console.log(
      `\nChild: ${childName} (${match.child.id}) under parent ` +
      `${match.parent.id}`,
  );

  if (mode === "--dry-run") {
    console.log("Dry run complete. No writes performed.");
    return;
  }

  const batch = db.batch();
  let writeCount = 0;

  for (const {quest, update} of operations) {
    if (!update || update.skip) continue;

    const data = {...update};
    if (data.removeDemoEligibilityOverride) {
      delete data.removeDemoEligibilityOverride;
      data.demoEligibilityOverride = admin.firestore.FieldValue.delete();
    }
    data.updatedAt = admin.firestore.FieldValue.serverTimestamp();

    batch.set(
        match.child.ref.collection("questProgress").doc(quest.id),
        data,
        {merge: true},
    );
    writeCount++;
  }

  await batch.commit();
  console.log(
      `${mode === "--clear" ? "Cleared" : "Applied"} ${writeCount} ` +
      "demo outfit override(s).",
  );
}

main()
  .catch((error) => {
    console.error(error);
    process.exitCode = 1;
  })
  .finally(async () => {
    await admin.app().delete();
  });
