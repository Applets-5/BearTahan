"use strict";

const path = require("path");
const admin = require("firebase-admin");
const textToSpeech = require("@google-cloud/text-to-speech");

const projectRoot = path.resolve(__dirname, "..", "..");
const serviceAccountPath = path.join(projectRoot, "service-account.json");
const definitions = require("../data/mandarin_tracing_questions.json");

const mode = process.argv[2] ?? "--dry-run";
const validModes = new Set(["--dry-run", "--apply"]);

if (!validModes.has(mode)) {
  console.error(
    "Usage: node functions/scripts/generate_mandarin_tracing_audio.js [--dry-run|--apply]",
  );
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
  storageBucket: "beartahan-2e52d.firebasestorage.app",
});

const db = admin.firestore();
const bucket = admin.storage().bucket();
const ttsClient = new textToSpeech.TextToSpeechClient({
  credentials: {
    client_email: serviceAccount.client_email,
    private_key: serviceAccount.private_key,
  },
  projectId: serviceAccount.project_id,
});

function expectedPrompt(definition) {
  return definition.prompt;
}

async function synthesizeAudio(text) {
  const [response] = await ttsClient.synthesizeSpeech({
    input: {text},
    voice: {
      languageCode: "cmn-CN",
      name: "cmn-CN-Wavenet-A",
    },
    audioConfig: {
      audioEncoding: "MP3",
      speakingRate: 0.9,
    },
  });

  return response.audioContent;
}

async function dryRun() {
  let readyCount = 0;
  let skippedCount = 0;

  for (const definition of definitions) {
    const snapshot = await db.collection("questions").doc(definition.id).get();
    const data = snapshot.exists ? snapshot.data() : null;
    const prompt = data?.prompt ?? data?.questionText ?? expectedPrompt(definition);
    const expected = expectedPrompt(definition);

    console.log(`\n${definition.id}: ${snapshot.exists ? "exists" : "missing"}`);
    console.log(`  prompt: ${JSON.stringify(prompt)}`);
    console.log(`  expected: ${JSON.stringify(expected)}`);
    console.log(`  promptAudioUrl: ${JSON.stringify(data?.promptAudioUrl ?? null)}`);

    if (!snapshot.exists) {
      skippedCount++;
      console.log("  Skipping: document does not exist. Run seed apply first.");
    } else if (prompt !== expected) {
      skippedCount++;
      console.log("  Skipping: Firestore prompt does not match tracing definition.");
    } else {
      readyCount++;
      console.log(`  Would generate audio/questions/${definition.id}.mp3`);
    }
  }

  console.log(
    `\nDry run complete. ${readyCount} ready, ${skippedCount} skipped.`,
  );
}

async function apply() {
  await dryRun();
  console.log("\nGenerating Mandarin tracing audio...");

  let generatedCount = 0;

  for (const definition of definitions) {
    const reference = db.collection("questions").doc(definition.id);
    const snapshot = await reference.get();

    if (!snapshot.exists) continue;

    const data = snapshot.data();
    const prompt = data.prompt ?? data.questionText;
    if (prompt !== expectedPrompt(definition)) continue;

    const audioContent = await synthesizeAudio(prompt);
    const fileName = `audio/questions/${definition.id}.mp3`;
    const file = bucket.file(fileName);

    await file.save(audioContent, {
      metadata: {contentType: "audio/mpeg"},
    });
    await file.makePublic();

    const publicUrl = `https://storage.googleapis.com/${bucket.name}/${fileName}`;
    await reference.update({promptAudioUrl: publicUrl});
    generatedCount++;

    console.log(`  ${definition.id}: ${publicUrl}`);
  }

  console.log(`\nGenerated ${generatedCount} Mandarin tracing audio file(s).`);
}

async function main() {
  if (mode === "--apply") {
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
