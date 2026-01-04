const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function duplicarRegistros() {
  const fechasDestino = ['2025-12-04', '2025-12-05', '2025-12-06', '2025-12-07'];
  
  // Buscar todos los registros con date = 2025-12-02
  const snapshot = await db.collection('bookings')
    .where('date', '==', '2025-12-02')
    .get();

  console.log('Registros origen (2025-12-02):', snapshot.size);
  console.log('Fechas destino:', fechasDestino.join(', '));
  console.log('Total a crear:', snapshot.size * fechasDestino.length, '\n');
  
  let contadorTotal = 0;
  
  for (const fecha of fechasDestino) {
    let contadorFecha = 0;
    
    for (const doc of snapshot.docs) {
      const datos = doc.data();
      
      const nuevosDatos = {
        ...datos,
        date: fecha,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      };
      
      await db.collection('bookings').add(nuevosDatos);
      contadorFecha++;
      contadorTotal++;
    }
    
    console.log('Fecha', fecha, '- Registros creados:', contadorFecha);
  }
  
  console.log('\n--- COMPLETADO ---');
  console.log('Total registros creados:', contadorTotal);
  process.exit();
}

duplicarRegistros().catch(err => {
  console.error('Error:', err);
  process.exit(1);
});
