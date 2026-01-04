const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function buscarReservas() {
  const snapshot = await db.collection('bookings')
    .where('date', '==', '2025-12-01')
    .get();

  console.log('Registros en 2025-12-01:', snapshot.size);
  console.log('Buscando reservas de FELIPE GARCIA...\n');
  
  let contador = 0;
  
  snapshot.forEach(doc => {
    const datos = doc.data();
    
    // Buscar si algún player tiene name = "FELIPE GARCIA"
    const tieneJugador = datos.players.some(player => player.name === 'FELIPE GARCIA');
    
    if (tieneJugador) {
      contador++;
      console.log('ID:', doc.id);
      console.log('Court:', datos.courtId);
      console.log('TimeSlot:', datos.timeSlot);
      console.log('Players:', datos.players.map(p => p.name).join(', '));
      console.log('---');
    }
  });
  
  console.log('\nTotal reservas encontradas:', contador);
  process.exit();
}

buscarReservas().catch(err => {
  console.error('Error:', err);
  process.exit(1);
});
