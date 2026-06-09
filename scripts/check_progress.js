const admin = require('firebase-admin');
const serviceAccount = require('../service-account.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function checkProgress() {
  console.log("Checking subjectProgress/bi/levels...");
  
  // Find a parent with a child
  const parentsSnap = await db.collection('parents').limit(5).get();
  for (const parent of parentsSnap.docs) {
    const childrenSnap = await parent.ref.collection('children').limit(1).get();
    for (const child of childrenSnap.docs) {
        const levelsSnap = await child.ref.collection('subjectProgress').doc('bi').collection('levels').get();
        if (levelsSnap.empty) continue;
        
        console.log(`Found progress for child ${child.id}:`);
        const ids = levelsSnap.docs.map(doc => doc.id);
        console.log(ids);
        return; // Just need one example
    }
  }
  console.log("No progress found in the first few parents.");
}

checkProgress();