const admin = require('firebase-admin');
admin.initializeApp({
  projectId: 'chuende2acc'
});
const db = admin.firestore();
db.collection('system_settings').doc('ui_settings').get().then(doc => {
  console.log("FIRESTORE_DATA:", JSON.stringify(doc.data(), null, 2));
  process.exit(0);
}).catch(err => {
  console.error("FIRESTORE_ERROR:", err);
  process.exit(1);
});
