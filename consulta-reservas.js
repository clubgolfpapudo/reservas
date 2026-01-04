const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

db.collection('bookings')
  .where('date', '==', '2025-12-02')
  .where('courtId', '==', 'golf_tee_10')
  .get()
  .then(snapshot => {
    console.log('Encontrados:', snapshot.size, 'registros\n');
    snapshot.forEach(doc => {
      console.log('ID:', doc.id);
      console.log(JSON.stringify(doc.data(), null, 2));
      console.log('---');
    });
    process.exit();
  });
