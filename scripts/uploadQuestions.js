const admin = require("firebase-admin");
const path = require("path");
const fs = require("fs");

// ── Argument validation ───────────────────────────────────────────────────────
const fileName = process.argv[2];

if (!fileName) {
  console.error("\n❌  No file specified.");
  console.error("    Usage: node uploadQuestions.js <filename.json>");
  console.error("    Example: node uploadQuestions.js questions_bm_chapter1.json\n");
  process.exit(1);
}

const filePath = path.resolve(__dirname, fileName);

if (!fs.existsSync(filePath)) {
  console.error(`\n❌  File not found: ${filePath}\n`);
  process.exit(1);
}

if (path.extname(fileName) !== ".json") {
  console.error("\n❌  File must be a .json file.\n");
  process.exit(1);
}

// ── Load questions ────────────────────────────────────────────────────────────
let questions;
try {
  questions = require(filePath);
} catch (err) {
  console.error(`\n❌  Failed to parse JSON: ${err.message}\n`);
  process.exit(1);
}

if (!Array.isArray(questions) || questions.length === 0) {
  console.error("\n❌  JSON file must contain a non-empty array of questions.\n");
  process.exit(1);
}

// ── Validate each question ────────────────────────────────────────────────────
const requiredFields = [
  "id",
  "subjectId",
  "chapterId",
  "levelId",
  "difficulty",
  "prompt",
  "options",
  "correctAnswerId",
];

questions.forEach((q, index) => {
  requiredFields.forEach((field) => {
    if (q[field] === undefined || q[field] === null) {
      console.error(
        `\n❌  Question at index ${index} is missing required field: "${field}"\n`
      );
      process.exit(1);
    }
  });

  if (!Array.isArray(q.options) || q.options.length !== 4) {
    console.error(
      `\n❌  Question "${q.id}" must have exactly 4 options.\n`
    );
    process.exit(1);
  }

  const optionIds = q.options.map((o) => o.id);
  if (!optionIds.includes(q.correctAnswerId)) {
    console.error(
      `\n❌  Question "${q.id}" correctAnswerId "${q.correctAnswerId}" does not match any option id.\n`
    );
    process.exit(1);
  }

  if (q.difficulty < 1 || q.difficulty > 3) {
    console.error(
      `\n❌  Question "${q.id}" difficulty must be 1, 2, or 3. Got: ${q.difficulty}\n`
    );
    process.exit(1);
  }
});

// ── Initialise Firebase ───────────────────────────────────────────────────────
let serviceAccount;
try {
  serviceAccount = require("./serviceAccountKey.json");
} catch {
  serviceAccount = null;
}

if (!admin.apps.length) {
  admin.initializeApp(
    serviceAccount
      ? { credential: admin.credential.cert(serviceAccount) }
      : { credential: admin.credential.applicationDefault() }
  );
}

const db = admin.firestore();

// ── Upload ────────────────────────────────────────────────────────────────────
async function uploadQuestions() {
  console.log("\n🐻  BearTahan — Question Bank Uploader");
  console.log("━".repeat(44));
  console.log(`📄  File      : ${fileName}`);
  console.log(`📦  Questions : ${questions.length}`);

  const subjectId   = questions[0].subjectId;
  const chapterId   = questions[0].chapterId;
  const levelId     = questions[0].levelId;
  const difficulties = [...new Set(questions.map((q) => q.difficulty))].sort();

  console.log(`📚  Subject   : ${subjectId}`);
  console.log(`📖  Chapter   : ${chapterId}`);
  console.log(`🎯  Level     : ${levelId}`);
  console.log(`⭐  Difficulties : ${difficulties.join(", ")}`);
  console.log("━".repeat(44));
  console.log("\nUploading...\n");

  const batch = db.batch();

  questions.forEach((q) => {
    const docRef = db.collection("questions").doc(q.id);
    batch.set(docRef, {
      ...q,
      createdAt: admin.firestore.Timestamp.fromDate(
        new Date(q.createdAt || new Date())
      ),
    });
  });

  await batch.commit();

  console.log(`✅  ${questions.length} questions uploaded successfully!\n`);
  console.log("📋  Uploaded document IDs:");
  questions.forEach((q) =>
    console.log(
      `    • ${q.id}  [difficulty: ${q.difficulty}]  [level: ${q.levelId}]`
    )
  );

  console.log(`
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  FIRESTORE COMPOSITE INDEX (add if missing)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Collection : questions
  Fields     : levelId (ASC) → chapterId (ASC) → difficulty (ASC)

  Query used in app:
    db.collection("questions")
      .where("levelId", "==", "${levelId}")
      .where("chapterId", "==", "${chapterId}")
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
`);

  process.exit(0);
}

uploadQuestions().catch((err) => {
  console.error("\n❌  Upload failed:", err.message || err);
  process.exit(1);
});