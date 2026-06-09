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
const ttsClient = new textToSpeech.TextToSpeechClient({
  credentials: {
    client_email: serviceAccount.client_email,
    private_key: serviceAccount.private_key,
  },
  projectId: serviceAccount.project_id,
});

async function generateAudio() {
  console.log("🚀 Starting audio generation...");

  // Add IDs here that you want to force-regenerate
  const forceIds = [
    // Add specific IDs here if needed
    'bi_c0_l3_q07',
    'bi_c0_l3_q09'
  ];
  
  const snapshot = await db.collection('questions').get();
  
  for (const doc of snapshot.docs) {
    const data = doc.data();
    const lowerId = doc.id.toLowerCase();
    
    // Check if it's a target subject for force regeneration
    const isTargetSubject = lowerId.startsWith('math_') || lowerId.startsWith('sci_');
    
    // Check if it's an English question
    const isEnglishSubject = lowerId.startsWith('bi_') || lowerId.startsWith('en_');
    // User mentioned English audio is already good, so no need to force regenerate
    const needsAccentFix = false; 

    // Skip if audio already exists, UNLESS it's in the forceIds list OR it's a target subject OR English fix
    if (data.promptAudioUrl && !forceIds.includes(doc.id) && !isTargetSubject && !needsAccentFix) {
      console.log(`- Skipping ${doc.id} (already has audio)`);
      continue;
    }

    if (forceIds.includes(doc.id) || isTargetSubject || needsAccentFix) {
      console.log(`🔄 Force regenerating audio for ${doc.id}...`);
    }

    // Try multiple field names for the text, prioritizing promptAudioText
    const text = data.promptAudioText || data.prompt || data.text || data.questionText;
    if (!text) {
      console.log(`- Skipping ${doc.id} (no 'promptAudioText', 'prompt', 'text', or 'questionText' field found)`);
      continue;
    }

    // Detect Language
    let langCode = 'ms-MY';
    let voiceName = 'ms-MY-Wavenet-A'; 

    // Character-based detection for Mandarin (priority)
    const hasChinese = /[\u4e00-\u9fa5]/.test(text);
    
    if (hasChinese) {
      langCode = 'cmn-CN';
      voiceName = 'cmn-CN-Wavenet-A';
    } else if (isEnglishSubject || ((lowerId.startsWith('math_') || lowerId.startsWith('sci_')) && !hasChinese)) {
      langCode = 'en-GB';
      voiceName = 'en-GB-Neural2-A';
    } else if (lowerId.startsWith('zh_') || lowerId.startsWith('bc_')) {
      langCode = 'cmn-CN';
      voiceName = 'cmn-CN-Wavenet-A';
    }

    // Determine blank placeholder based on language
    let blankPlaceholder = "blank";
    if (langCode.startsWith('ms')) {
      blankPlaceholder = "tempat kosong";
    } else if (langCode.startsWith('cmn')) {
      blankPlaceholder = "空格"; 
    }

    // Clean text: replace both ___ and （ ）
    const cleanText = text
      .replace(/_{2,}/g, blankPlaceholder)
      .replace(/[\(\（]\s*[\)\）]/g, blankPlaceholder);

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
      // Add a timestamp query parameter to bust the cache in the Flutter app!
      const cacheBuster = Date.now();
      const publicUrl = `https://storage.googleapis.com/${bucket.name}/${fileName}?t=${cacheBuster}`;

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