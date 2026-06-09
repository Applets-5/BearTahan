const admin = require('firebase-admin');
const serviceAccount = require('../service-account.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function checkDb() {
  const snapshot = await db.collection('questions')
    .where(admin.firestore.FieldPath.documentId(), '>=', 'bi_c2')
    .where(admin.firestore.FieldPath.documentId(), '<', 'bi_c3')
    .get();
    
  const ids = snapshot.docs.map(doc => doc.id);
  const prefixes = new Set(ids.map(id => {
    const parts = id.split('_');
    if (parts.length >= 3) return `${parts[0]}_${parts[1]}_${parts[2]}`;
    return id;
  }));
  console.log("bi_c2 unique level prefixes:", Array.from(prefixes));
}

checkDb();