const fs = require("fs");
const path = require("path");

// Generates BearTahan-owned sound effects without third-party audio assets.
const sampleRate = 44100;
const channels = 1;
const bitsPerSample = 16;
const outputDirectory = path.join(__dirname, "..", "assets", "audio");

fs.mkdirSync(outputDirectory, { recursive: true });

writeWave("stroke_correct.wav", 0.12, (time, progress) => {
  const envelope = createEnvelope(time, progress, 0.005);
  const fundamental = Math.sin(2 * Math.PI * 880 * time);
  const overtone = 0.18 * Math.sin(2 * Math.PI * 1320 * time);
  return 0.42 * envelope * (fundamental + overtone);
});

writeWave("stroke_wrong.wav", 0.16, (time, progress) => {
  const envelope = createEnvelope(time, progress, 0.006);
  const phase = 2 * Math.PI * (660 * time - (110 * time * time) / 0.16);
  const frequency = 660 - 220 * progress;
  const tone = Math.sin(phase);
  const presence = 0.18 * Math.sin(2 * Math.PI * frequency * 1.5 * time);
  return 0.52 * envelope * (tone + presence);
});

function createEnvelope(time, progress, attackSeconds) {
  const attack = Math.min(1, time / attackSeconds);
  const decay = Math.exp(-3.2 * progress);
  const finalFadeStart = 0.78;
  const finalFade =
    progress < finalFadeStart
      ? 1
      : Math.exp((-18 * (progress - finalFadeStart)) / (1 - finalFadeStart));
  return attack * decay * finalFade;
}

function writeWave(fileName, durationSeconds, sampleAt) {
  const sampleCount = Math.round(durationSeconds * sampleRate);
  const dataSize = sampleCount * channels * (bitsPerSample / 8);
  const buffer = Buffer.alloc(44 + dataSize);

  buffer.write("RIFF", 0);
  buffer.writeUInt32LE(36 + dataSize, 4);
  buffer.write("WAVE", 8);
  buffer.write("fmt ", 12);
  buffer.writeUInt32LE(16, 16);
  buffer.writeUInt16LE(1, 20);
  buffer.writeUInt16LE(channels, 22);
  buffer.writeUInt32LE(sampleRate, 24);
  buffer.writeUInt32LE(sampleRate * channels * (bitsPerSample / 8), 28);
  buffer.writeUInt16LE(channels * (bitsPerSample / 8), 32);
  buffer.writeUInt16LE(bitsPerSample, 34);
  buffer.write("data", 36);
  buffer.writeUInt32LE(dataSize, 40);

  for (let index = 0; index < sampleCount; index += 1) {
    const time = index / sampleRate;
    const progress = index / Math.max(1, sampleCount - 1);
    const sample = Math.max(-1, Math.min(1, sampleAt(time, progress)));
    buffer.writeInt16LE(Math.round(sample * 32767), 44 + index * 2);
  }

  fs.writeFileSync(path.join(outputDirectory, fileName), buffer);
}
