const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function actualizarRegistros() {
  // Buscar registros con date > 2025-12-01
  const snapshot = await db.collection('bookings')
    .where('date', '>', '2025-12-01')
    .get();

  console.log('Registros encontrados con date > 2025-12-01:', snapshot.size);
  
  let contador = 0;
  
  for (const doc of snapshot.docs) {
    const datos = doc.data();
    
    // Actualizar el name de todos los players
    const playersActualizados = datos.players.map(player => ({
      ...player,
      name: 'ABIERTO PAPUDO'
    }));
    
    await db.collection('bookings').doc(doc.id).update({
      players: playersActualizados,
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });
    
    contador++;
    console.log('Actualizado:', contador, '| date:', datos.date, '| timeSlot:', datos.timeSlot);
  }
  
  console.log('\n--- COMPLETADO ---');
  console.log('Total registros actualizados:', contador);
  process.exit();
}

actualizarRegistros().catch(err => {
  console.error('Error:', err);
  process.exit(1);
});
