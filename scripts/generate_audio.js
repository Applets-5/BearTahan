const admin = require('firebase-admin');
const textToSpeech = require('@google-cloud/text-to-speech');
const serviceAccount = require('../service-account.json');

// Initialize Firebase
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  storageBucket: "beartahan-2e52d.firebasestorage.app" // REPLACE WITH YOUR BUCKET NAME
});

const db = admin.firestore();
const bucket = admin.storage().bucket();
const ttsClient = new textToSpeech.TextToSpeechClient();

async function generateAudio() {
  console.log("🚀 Starting audio generation...");
  
  const snapshot = await db.collection('questions').get();
  
  for (const doc of snapshot.docs) {
    const data = doc.data();
    
    // Skip if audio already exists
    if (data.promptAudioUrl) {
      console.log(`- Skipping ${doc.id} (already has audio)`);
      continue;
    }

    const text = data.text || data.questionText;
    if (!text) continue;

    // Detect Language based on document ID prefix
    let langCode = 'ms-MY';
    let voiceName = 'ms-MY-Wavenet-A'; // High-quality Malaysian Neural

    if (doc.id.startsWith('en_')) {
      langCode = 'en-GB';
      voiceName = 'en-GB-Wavenet-A';
    } else if (doc.id.startsWith('zh_')) {
      langCode = 'cmn-CN';
      voiceName = 'cmn-CN-Wavenet-A';
    }

    // Clean text (replace ___ with "tempat kosong" for the generator)
    const cleanText = text.replace(
      /_{2,}/g,
      langCode.startsWith('ms') ? "tempat kosong" : "blank"
    );

    console.log(`🎵 Generating audio for [${doc.id}]: "${cleanText}"`);

    const request = {
      input: { text: cleanText },
      voice: { languageCode: langCode, name: voiceName },
      audioConfig: {
        audioEncoding: 'MP3',
        speakingRate: 0.9 // Slightly slower for kids
      }
    };

    try {
      const [response] = await ttsClient.synthesizeSpeech(request);
      
      const fileName = `audio/questions/${doc.id}.mp3`;
      const file = bucket.file(fileName);

      await file.save(response.audioContent, {
        metadata: { contentType: 'audio/mpeg' },
      });

      // Make file public and get URL
      await file.makePublic();
      const publicUrl = `https://storage.googleapis.com/${bucket.name}/${fileName}`;

      // Update Firestore
      await doc.ref.update({ promptAudioUrl: publicUrl });

      console.log(`✅ Success! URL: ${publicUrl}`);

    } catch (err) {
      console.error(`❌ Error on ${doc.id}:`, err);
    }
  }

  console.log("🏁 Done!");
}

generateAudio();