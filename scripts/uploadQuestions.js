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

// ── Question types that do not require options ────────────────────────────────
const NO_OPTIONS_TYPES = ['keyInNumber', 'fillBlankList', 'strokeTrace', 'matching'];

// ── Valid question types ──────────────────────────────────────────────────────
const VALID_TYPES = [
  'mcq',
  'fillBlank',
  'fillBlankList',
  'rearrange',
  'keyInNumber',
  'stroke_trace',
  'strokeTrace',
  'dragDropSpelling',
  'matching',
];

// ── Validate each question ────────────────────────────────────────────────────
const requiredFields = [
  "id",
  "subjectId",
  "chapterId",
  "levelId",
  "difficulty",
  "prompt",
];

questions.forEach((q, index) => {
  const questionType = q.questionType;

  // ── Required fields ─────────────────────────────────────────────────────────
  requiredFields.forEach((field) => {
    if (q[field] === undefined || q[field] === null) {
      console.error(
        `\n❌  Question at index ${index} (id: "${q.id}") is missing required field: "${field}"\n`
      );
      process.exit(1);
    }
  });

  // ── Valid question type ─────────────────────────────────────────────────────
  if (!VALID_TYPES.includes(questionType)) {
    console.error(
      `\n❌  Question "${q.id}" has unknown questionType: "${questionType}"\n` +
      `    Valid types: ${VALID_TYPES.join(', ')}\n`
    );
    process.exit(1);
  }

  // ── Options validation ──────────────────────────────────────────────────────
  const isNoOptions = NO_OPTIONS_TYPES.includes(questionType);

  if (!isNoOptions) {
    if (!Array.isArray(q.options) || q.options.length < 2 || q.options.length > 6) {
      console.error(
        `\n❌  Question "${q.id}" must have between 2 and 6 options. Got: ${q.options?.length ?? 0}\n`
      );
      process.exit(1);
    }
  }

  // ── Per-type correctness validation ─────────────────────────────────────────
  if (questionType === 'mcq') {
    const optionIds = (q.options || []).map((o) => o.id);
    if (!q.correctAnswerId || !optionIds.includes(q.correctAnswerId)) {
      console.error(
        `\n❌  Question "${q.id}" correctAnswerId "${q.correctAnswerId}" does not match any option id.\n` +
        `    Available ids: ${optionIds.join(', ')}\n`
      );
      process.exit(1);
    }
  }

  if (questionType === 'fillBlank' && !q.correctBlank) {
    console.error(
      `\n❌  Question "${q.id}" is fillBlank but missing correctBlank.\n`
    );
    process.exit(1);
  }

  if (questionType === 'fillBlankList') {
    if (!q.correctOrder || q.correctOrder.length === 0) {
      console.error(
        `\n❌  Question "${q.id}" is fillBlankList but missing correctOrder.\n`
      );
      process.exit(1);
    }
  }

  if (questionType === 'rearrange') {
    if (!q.correctOrder || q.correctOrder.length === 0) {
      console.error(
        `\n❌  Question "${q.id}" is rearrange but missing correctOrder.\n`
      );
      process.exit(1);
    }
  }

  if (questionType === 'keyInNumber') {
    if (!q.correctNumber && q.correctNumber !== 0) {
      console.error(
        `\n❌  Question "${q.id}" is keyInNumber but missing correctNumber.\n`
      );
      process.exit(1);
    }
  }

  if (questionType === 'stroke_trace' || questionType === 'strokeTrace') {
    if (!q.characterUnicode && !q.strokeOrderDataJson) {
      console.error(
        `\n❌  Question "${q.id}" is stroke_trace but missing both characterUnicode and strokeOrderDataJson.\n`
      );
      process.exit(1);
    }
  }

  if (questionType === 'keyInNumber') {
    const hasCorrectNumber = q.correctNumber !== undefined && q.correctNumber !== null;
    const hasCorrectAnswers = Array.isArray(q.correctAnswers) && q.correctAnswers.length > 0;
    if (!hasCorrectNumber && !hasCorrectAnswers) {
      console.error(
        `\n❌  Question "${q.id}" is keyInNumber but missing both correctNumber and correctAnswers.\n`
      );
      process.exit(1);
    }
  }

  // ── Difficulty range ────────────────────────────────────────────────────────
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

  const subjectId    = questions[0].subjectId;
  const chapterId    = questions[0].chapterId;
  const levelId      = questions[0].levelId;
  const difficulties = [...new Set(questions.map((q) => q.difficulty))].sort();
  const types        = [...new Set(questions.map((q) => q.questionType))];

  console.log(`📚  Subject      : ${subjectId}`);
  console.log(`📖  Chapter      : ${chapterId}`);
  console.log(`🎯  Level        : ${levelId}`);
  console.log(`⭐  Difficulties : ${difficulties.join(", ")}`);
  console.log(`📝  Types        : ${types.join(", ")}`);
  console.log("━".repeat(44));
  console.log("\nUploading...\n");

  // Firestore batch limit is 500 — split if needed
  const BATCH_SIZE = 490;
  const batches = [];
  for (let i = 0; i < questions.length; i += BATCH_SIZE) {
    batches.push(questions.slice(i, i + BATCH_SIZE));
  }

  for (const batchItems of batches) {
    const batch = db.batch();
    batchItems.forEach((q) => {
      const docRef = db.collection("questions").doc(q.id);
      batch.set(docRef, {
        ...q,
        createdAt: admin.firestore.Timestamp.fromDate(
          new Date(q.createdAt || new Date())
        ),
      });
    });
    await batch.commit();
  }

  console.log(`✅  ${questions.length} questions uploaded successfully!\n`);
  console.log("📋  Uploaded document IDs:");
  questions.forEach((q) =>
    console.log(
      `    • ${q.id}  [type: ${q.questionType}]  [difficulty: ${q.difficulty}]  [level: ${q.levelId}]`
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