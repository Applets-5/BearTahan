const admin = require('firebase-admin');
const serviceAccount = require('../service-account.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function checkDb() {
  console.log("Checking bi_c1 questions...");
  const snapshot = await db.collection('questions')
    .where(admin.firestore.FieldPath.documentId(), '>=', 'bi_c1')
    .where(admin.firestore.FieldPath.documentId(), '<', 'bi_c2')
    .get();
    
  const ids = snapshot.docs.map(doc => doc.id);
  console.log(`Found ${ids.length} questions.`);
  if (ids.length > 0) {
    // Print unique prefixes to see the level IDs
    const prefixes = new Set(ids.map(id => {
      const parts = id.split('_');
      if (parts.length >= 3) return `${parts[0]}_${parts[1]}_${parts[2]}`;
      return id;
    }));
    console.log("Unique level prefixes found:", Array.from(prefixes));
  }
}

checkDb();