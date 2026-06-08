"use strict";

const fs = require("fs/promises");
const path = require("path");

const projectRoot = path.resolve(__dirname, "..");
const definitions = require("../functions/data/mandarin_tracing_questions.json");
const outputDir = path.join(projectRoot, "assets", "hanzi");
const mode = process.argv[2] ?? "--dry-run";
const validModes = new Set(["--dry-run", "--apply"]);

if (!validModes.has(mode)) {
  console.error("Usage: node tool/download_hanzi_assets.js [--dry-run|--apply]");
  process.exit(1);
}

function uniqueCharacters() {
  return [
    ...new Set(
      definitions
        .map((definition) => definition.characterUnicode)
        .filter((character) => typeof character === "string" && character.length > 0),
    ),
  ];
}

async function fileExists(filePath) {
  try {
    await fs.access(filePath);
    return true;
  } catch (_) {
    return false;
  }
}

async function downloadCharacter(character) {
  const url = `https://cdn.jsdelivr.net/npm/hanzi-writer-data@latest/${encodeURIComponent(
    character,
  )}.json`;
  const response = await fetch(url);

  if (!response.ok) {
    throw new Error(`Failed to download ${character}: ${response.status} ${response.statusText}`);
  }

  const data = await response.json();
  if (!Array.isArray(data.strokes) || !Array.isArray(data.medians)) {
    throw new Error(`Invalid Hanzi Writer data for ${character}`);
  }

  return `${JSON.stringify(data)}\n`;
}

async function main() {
  const characters = uniqueCharacters();
  let missingCount = 0;
  let downloadedCount = 0;

  await fs.mkdir(outputDir, {recursive: true});

  for (const character of characters) {
    const filePath = path.join(outputDir, `${character}.json`);
    const exists = await fileExists(filePath);

    if (exists) {
      console.log(`${character}: exists`);
      continue;
    }

    missingCount++;
    console.log(`${character}: missing`);

    if (mode === "--apply") {
      const content = await downloadCharacter(character);
      await fs.writeFile(filePath, content, "utf8");
      downloadedCount++;
      console.log(`  downloaded assets/hanzi/${character}.json`);
    }
  }

  if (mode === "--dry-run") {
    console.log(`\nDry run complete. ${missingCount} missing asset(s).`);
  } else {
    console.log(`\nDownloaded ${downloadedCount} Hanzi asset(s).`);
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
