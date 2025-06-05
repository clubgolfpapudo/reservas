// Deploy Fix 2025-06-05 14:35 - Individual cancellation URLs

const {onRequest} = require("firebase-functions/v2/https");
const {setGlobalOptions} = require("firebase-functions/v2");
const nodemailer = require("nodemailer");
const admin = require('firebase-admin');

// Inicializar Firebase Admin
admin.initializeApp();

// Configuración global
setGlobalOptions({maxInstances: 10});

// Configuración simple de Gmail con App Password
const createTransporter = () => {
  // Usar directamente la App Password (más simple y confiable)
  const gmailPassword = 'myuh svqx djyn kfby';
  
  console.log('📧 Configurando Gmail transporter...');
  
  return nodemailer.createTransport({
    service: 'gmail',
    auth: {
      user: 'paddlepapudo@gmail.com',
      pass: gmailPassword
    }
  });
};

// ============================================================================
// ENVÍO DE EMAILS DE CONFIRMACIÓN
// ============================================================================
exports.sendBookingEmailHTTP = onRequest({
  cors: true,
}, async (req, res) => {
  // Manejar preflight OPTIONS request
  if (req.method === "OPTIONS") {
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
    res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    res.set('Access-Control-Max-Age', '3600');
    return res.status(204).send('');
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ 
      success: false, 
      error: 'Método no permitido' 
    });
  }

  try {
    console.log('📧 === ENVIANDO EMAILS CON GMAIL APP PASSWORD ===');
    console.log('📧 Body:', JSON.stringify(req.body, null, 2));

    // Manejar request de test
    if (req.body.test === true) {
      console.log('🧪 REQUEST DE TEST RECIBIDO');
      return res.status(200).json({ 
        success: true, 
        message: 'Endpoint Gmail funcionando correctamente',
        timestamp: new Date().toISOString()
      });
    }

    // Validar datos de reserva
    const { booking } = req.body;
    if (!booking || !booking.players || booking.players.length === 0) {
      return res.status(400).json({ 
        success: false, 
        error: 'Datos de reserva requeridos' 
      });
    }

    console.log(`📧 Procesando reserva: ${booking.courtNumber} ${booking.date} ${booking.timeSlot}`);
    console.log(`📧 Jugadores: ${booking.players.length}`);

    // Crear transporter
    const transporter = createTransporter();

    // Preparar emails para todos los jugadores
    const emailPromises = booking.players
      .filter(player => player.email && player.email !== 'sin-email@cgp.cl')
      .map(async (player, index) => {
        try {
          console.log(`📧 Enviando email ${index + 1}/${booking.players.length} a: ${player.name} (${player.email})`);

          // Generar ID único para la reserva
          const bookingId = `${booking.courtNumber}-${booking.date}-${booking.timeSlot}`.replace(/[^a-zA-Z0-9-]/g, '');
          console.log(`📧 ID generado para ${player.name}: ${bookingId}`);

          const emailHtml = generateBookingEmailHtml({
            playerName: player.name,
            playerEmail: player.email,
            isOrganizer: index === 0,
            booking: {
              ...booking,
              id: bookingId
            }
          });

          // Generar archivo .ics para calendario (comentado para evitar duplicación)
          // const icsContent = generateICSContent(booking);

          const mailOptions = {
            from: `"Club de Golf Papudo" <paddlepapudo@gmail.com>`,
            to: player.email,
            subject: `Reserva de Pádel Confirmada - ${formatDate(booking.date)}`,
            html: emailHtml,
            // attachments: [
            //   {
            //     filename: 'reserva-padel.ics',
            //     content: icsContent,
            //     contentType: 'text/calendar'
            //   }
            // ]
          };

          const result = await transporter.sendMail(mailOptions);
          console.log(`✅ Email enviado a ${player.name}: ${result.messageId}`);
          
          return { 
            success: true, 
            player: player.name, 
            email: player.email,
            messageId: result.messageId 
          };

        } catch (error) {
          console.error(`❌ Error enviando email a ${player.name}:`, error);
          return { 
            success: false, 
            player: player.name, 
            email: player.email, 
            error: error.message 
          };
        }
      });

    // Ejecutar todos los envíos
    const results = await Promise.all(emailPromises);
    
    const successful = results.filter(r => r.success);
    const failed = results.filter(r => !r.success);

    console.log(`📧 === RESUMEN ===`);
    console.log(`✅ Exitosos: ${successful.length}/${results.length}`);
    console.log(`❌ Fallidos: ${failed.length}/${results.length}`);

    if (successful.length > 0) {
      return res.status(200).json({
        success: true,
        message: `${successful.length} emails enviados exitosamente`,
        results: results
      });
    } else {
      return res.status(500).json({
        success: false,
        message: 'No se pudo enviar ningún email',
        results: results
      });
    }

  } catch (error) {
    console.error('❌ Error general:', error);
    return res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// ============================================================================
// CANCELACIÓN DE RESERVAS
// ============================================================================
exports.cancelBooking = onRequest({
  cors: true,
}, async (req, res) => {
  if (req.method === "OPTIONS") {
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    res.set('Access-Control-Allow-Headers', 'Content-Type');
    return res.status(204).send('');
  }

  try {
    console.log('🗑️ === CANCELACIÓN DE RESERVA ===');
    console.log('🗑️ Method:', req.method);
    console.log('🗑️ Query:', req.query);

    const bookingId = req.query.id || req.body.bookingId;
    const playerEmail = req.query.email || req.body.playerEmail;
    
    if (!bookingId) {
      return res.status(400).json({
        success: false,
        error: 'ID de reserva requerido'
      });
    }

    if (!playerEmail) {
      return res.status(400).json({
        success: false,
        error: 'Email del jugador requerido'
      });
    }

    console.log(`🗑️ Cancelando jugador ${decodeURIComponent(playerEmail)} de reserva: ${bookingId}`);

    // Primero, vamos a ver qué hay en la base de datos
    const db = admin.firestore();
    const bookingsRef = db.collection('bookings');
    
    console.log('🔍 === DEBUGGING FIRESTORE ===');
    
    // Listar todas las reservas para debugging
    const allBookings = await bookingsRef.limit(10).get();
    console.log(`📋 Total reservas en DB: ${allBookings.size}`);
    
    allBookings.forEach(doc => {
      const data = doc.data();
      console.log(`📋 Reserva encontrada:`, {
        docId: doc.id,
        id: data.id,
        courtNumber: data.courtNumber,
        date: data.date,
        timeSlot: data.timeSlot,
        status: data.status
      });
    });

    // Buscar la reserva por el ID generado
    console.log(`🔍 Buscando por ID: ${bookingId}`);
    const snapshot = await bookingsRef.where('id', '==', bookingId).get();
    console.log(`🔍 Búsqueda por ID resultado: ${snapshot.size} documentos`);
    
    if (snapshot.empty) {
      // Decodificar el ID para buscar por campos individuales
      const idParts = bookingId.split('-');
      console.log(`🔍 ID parts:`, idParts);
      
      if (idParts.length >= 5) {
        // ID formato: court1-2025-06-05-1200
        // Convertir a formato Firebase: court_1, 2025-06-05, 12:00
        const courtNumber = idParts[0].replace('court', 'court_'); // court1 → court_1
        const date = `${idParts[1]}-${idParts[2]}-${idParts[3]}`; // 2025-06-05
        const timeRaw = idParts[4]; // 1200
        const timeSlot = `${timeRaw.substring(0,2)}:${timeRaw.substring(2,4)}`; // 12:00
        
        console.log(`🔍 Buscando por: court=${courtNumber}, date=${date}, time=${timeSlot}`);
        
        const alternativeSnapshot = await bookingsRef
          .where('courtNumber', '==', courtNumber)
          .where('date', '==', date)
          .where('timeSlot', '==', timeSlot)
          .get();
          
        console.log(`🔍 Búsqueda alternativa resultado: ${alternativeSnapshot.size} documentos`);
          
        if (!alternativeSnapshot.empty) {
          // Encontramos la reserva, ahora remover solo al jugador
          console.log('🔍 Reserva encontrada, removiendo jugador...');
          
          const doc = alternativeSnapshot.docs[0]; // Tomar el primer documento
          const bookingData = doc.data();
          const currentPlayers = bookingData.players || [];
          
          console.log('👥 Jugadores actuales:', currentPlayers.map(p => p.email));
          
          // Filtrar el jugador que cancela
          const decodedPlayerEmail = decodeURIComponent(playerEmail);
          const updatedPlayers = currentPlayers.filter(player => 
            player.email !== decodedPlayerEmail
          );
          
          console.log('👥 Jugadores después de cancelación:', updatedPlayers.map(p => p.email));
          
          if (updatedPlayers.length === 0) {
            // Si no quedan jugadores, eliminar toda la reserva
            console.log('🗑️ No quedan jugadores, eliminando reserva completa...');
            await doc.ref.delete();
            console.log('✅ Reserva eliminada completamente (sin jugadores)');
          } else {
            // Actualizar la reserva con los jugadores restantes
            console.log('🔄 Actualizando reserva con jugadores restantes...');
            await doc.ref.update({
              players: updatedPlayers,
              lastModified: admin.firestore.FieldValue.serverTimestamp()
            });
            console.log(`✅ Jugador removido. Quedan ${updatedPlayers.length} jugadores`);
          }
        } else {
          console.log('❌ No se encontró la reserva para cancelar en búsqueda alternativa');
        }
      } else {
        console.log('❌ Formato de ID inválido para búsqueda alternativa');
      }
    } else {
      // Encontramos la reserva por ID directo, remover solo al jugador
      console.log('🔍 Reserva encontrada por ID directo, removiendo jugador...');
      
      const doc = snapshot.docs[0]; // Tomar el primer documento
      const bookingData = doc.data();
      const currentPlayers = bookingData.players || [];
      
      console.log('👥 Jugadores actuales:', currentPlayers.map(p => p.email));
      
      // Filtrar el jugador que cancela
      const decodedPlayerEmail = decodeURIComponent(playerEmail);
      const updatedPlayers = currentPlayers.filter(player => 
        player.email !== decodedPlayerEmail
      );
      
      console.log('👥 Jugadores después de cancelación:', updatedPlayers.map(p => p.email));
      
      if (updatedPlayers.length === 0) {
        // Si no quedan jugadores, eliminar toda la reserva
        console.log('🗑️ No quedan jugadores, eliminando reserva completa...');
        await doc.ref.delete();
        console.log('✅ Reserva eliminada completamente (sin jugadores)');
      } else {
        // Actualizar la reserva con los jugadores restantes
        console.log('🔄 Actualizando reserva con jugadores restantes...');
        await doc.ref.update({
          players: updatedPlayers,
          lastModified: admin.firestore.FieldValue.serverTimestamp()
        });
        console.log(`✅ Jugador removido. Quedan ${updatedPlayers.length} jugadores`);
      }
    }

    // Mostrar página de confirmación para GET requests
    if (req.method === 'GET') {
      const html = `
        <!DOCTYPE html>
        <html lang="es">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Cancelar Reserva - Club de Golf Papudo</title>
            <style>
                body { 
                    font-family: -apple-system, BlinkMacSystemFont, sans-serif; 
                    background: #f5f5f5; margin: 0; padding: 20px; 
                }
                .container { 
                    max-width: 500px; margin: 50px auto; background: white; 
                    border-radius: 12px; padding: 40px; text-align: center;
                    box-shadow: 0 4px 12px rgba(0,0,0,0.1);
                }
                .header { color: #1e3a8a; margin-bottom: 30px; }
                .success { color: #10b981; font-size: 48px; margin-bottom: 20px; }
                .message { font-size: 18px; color: #374151; margin-bottom: 30px; line-height: 1.6; }
                .booking-id { 
                    background: #f3f4f6; padding: 12px; border-radius: 6px; 
                    font-family: monospace; color: #6b7280; margin: 20px 0; 
                }
                .button { 
                    background: #1e3a8a; color: white; padding: 12px 24px; 
                    text-decoration: none; border-radius: 6px; display: inline-block;
                    margin: 10px; font-weight: 600;
                }
                .button:hover { background: #1e40af; }
                .note { 
                    background: #fef3cd; padding: 16px; border-radius: 6px; 
                    color: #92400e; font-size: 14px; margin-top: 20px; 
                }
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <h1>Club de Golf Papudo</h1>
                    <p>Sistema de Reservas de Pádel</p>
                </div>
                
                <div class="success">✅</div>
                
                <div class="message">
                    <strong>Cancelación Individual Exitosa</strong><br><br>
                    Has sido removido de esta reserva de pádel. 
                    Los otros jugadores han sido notificados automáticamente.
                </div>
                
                <div class="booking-id">
                    Reserva: ${bookingId}<br>
                    Jugador: ${decodeURIComponent(playerEmail)}
                </div>
                
                <a href="https://cgpreservas.web.app" class="button">
                    🏓 Hacer Nueva Reserva
                </a>
                
                <a href="mailto:paddlepapudo@gmail.com" class="button">
                    📧 Contactar al Club
                </a>
                
                <div class="note">
                    <strong>💡 Nota:</strong> Puedes hacer una nueva reserva 
                    en cualquier momento desde la aplicación web del club.
                </div>
            </div>
        </body>
        </html>
      `;
      
      res.set('Content-Type', 'text/html');
      return res.status(200).send(html);
    }

    // Para POST requests, responder JSON
    return res.status(200).json({
      success: true,
      message: 'Reserva cancelada exitosamente',
      bookingId: bookingId
    });

  } catch (error) {
    console.error('❌ Error cancelando:', error);
    
    // Aún mostrar página de éxito aunque haya error interno
    if (req.method === 'GET') {
      const html = `
        <!DOCTYPE html>
        <html>
        <head><title>Error - Club de Golf Papudo</title></head>
        <body style="font-family: Arial; text-align: center; padding: 50px;">
          <h1>⚠️ Error al Cancelar</h1>
          <p>Hubo un problema al cancelar la reserva.</p>
          <p>Por favor contacta al club directamente.</p>
          <a href="mailto:paddlepapudo@gmail.com">📧 Contactar Club</a>
        </body>
        </html>
      `;
      res.set('Content-Type', 'text/html');
      return res.status(500).send(html);
    }
    
    return res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// ============================================================================
// FUNCIONES AUXILIARES
// ============================================================================

function generateBookingEmailHtml({playerName, playerEmail, isOrganizer, booking}) {
  const courtName = getCourtName(booking.courtNumber);
  const playersHtml = booking.players.map((player, index) => {
    const isOrganizerBadge = (index === 0) ?
      "<div class=\"organizer-badge\">Organizador</div>" : "";

    return `
      <div class="player-card">
        <div class="player-name">${player.name}</div>
        ${isOrganizerBadge}
      </div>
    `;
  }).join("");

  return `
    <!DOCTYPE html>
    <html lang="es">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Reserva Confirmada - Pádel Papudo</title>
        <style>
            body { 
                font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 
                Roboto, sans-serif; line-height: 1.6; margin: 0; padding: 0; 
                background-color: #f5f5f5; 
            }
            .container { 
                max-width: 600px; margin: 20px auto; background: white; 
                border-radius: 12px; overflow: hidden; 
                box-shadow: 0 4px 12px rgba(0,0,0,0.1); 
            }
            .header { 
                background: linear-gradient(135deg, #1e3a8a, #1e40af); 
                color: white; padding: 40px 20px; text-align: center; 
            }
            .logo { 
                width: 80px; height: 80px; margin: 0 auto 15px auto; 
                background: white; border-radius: 50%; display: flex; 
                align-items: center; justify-content: center; 
                box-shadow: 0 4px 12px rgba(0,0,0,0.2); 
            }
            .content { padding: 30px; }
            .booking-card { 
                background: #f8fafc; border-radius: 8px; padding: 24px; 
                margin: 20px 0; border-left: 4px solid #1e3a8a; 
            }
            .detail-row { 
                display: flex; justify-content: space-between; 
                padding: 8px 0; border-bottom: 1px solid #e2e8f0; 
            }
            .detail-label { font-weight: 600; color: #475569; }
            .detail-value { color: #1e293b; font-weight: 500; }
            .players-grid { 
                display: grid; grid-template-columns: repeat(2, 1fr); 
                gap: 12px; margin-top: 12px; 
            }
            .player-card { 
                background: white; padding: 12px; border-radius: 6px; 
                border: 1px solid #e2e8f0; text-align: center; 
            }
            .player-name { font-weight: 600; color: #1e293b; font-size: 14px; }
            .organizer-badge { 
                background: #1e3a8a; color: white; padding: 2px 8px; 
                border-radius: 12px; font-size: 11px; margin-top: 4px; 
                display: inline-block; 
            }
            .actions { margin: 30px 0; text-align: center; }
            .button { 
                display: inline-block; padding: 12px 24px; margin: 0 8px; 
                border-radius: 6px; text-decoration: none; font-weight: 600; 
                font-size: 14px; 
            }
            .button-primary { background: #10b981; color: white; }
            .button-secondary { background: #ef4444; color: white; }
            @media (max-width: 600px) { 
                .players-grid { grid-template-columns: 1fr; } 
                .button { display: block; margin: 8px 0; } 
            }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <div class="logo">
                    <div style="font-weight: bold; color: #1e3a8a; 
                    font-size: 10px; text-align: center;">
                    CLUB<br>GOLF<br>PAPUDO<br>
                    <small style="font-size: 7px;">1932</small></div>
                </div>
                <h1>🏓 Reserva Confirmada</h1>
                <p>Club de Golf Papudo - Pádel • Desde 1932</p>
            </div>
            
            <div class="content">
                <h2>¡Hola ${playerName}!</h2>
                <p>Tu reserva de pádel ha sido confirmada exitosamente. 
                Te esperamos en la cancha.</p>

                <div class="booking-card">
                    <div class="detail-row">
                        <span class="detail-label">📅 Fecha</span>
                        <span class="detail-value">${formatDate(booking.date)}</span>
                    </div>
                    <div class="detail-row">
                        <span class="detail-label">⏰ Hora</span>
                        <span class="detail-value">${booking.timeSlot} - 
                        ${getEndTime(booking.timeSlot)}</span>
                    </div>
                    <div class="detail-row">
                        <span class="detail-label">🎾 Cancha</span>
                        <span class="detail-value">${courtName}</span>
                    </div>
                </div>

                <div>
                    <h3>👥 Jugadores Confirmados (${booking.players.length}/4)</h3>
                    <div class="players-grid">
                        ${playersHtml}
                    </div>
                </div>

                <div class="actions">
                    <a href="https://us-central1-cgpreservas.cloudfunctions.net/cancelBooking?id=${booking.id}&email=${encodeURIComponent(playerEmail)}" 
                    class="button button-secondary">❌ Cancelar Reserva</a>
                </div>

                <div style="background: #fef3cd; padding: 16px; 
                border-radius: 6px; margin: 20px 0;">
                    <strong>💡 Importante:</strong> Para cancelar esta reserva, 
                    haz clic en el botón de arriba. Se notificará automáticamente 
                    a los otros jugadores.
                </div>
            </div>

            <div style="background: #f8fafc; padding: 20px; 
            text-align: center; color: #64748b; font-size: 14px;">
                <p>
                    <strong>Club de Golf Papudo</strong> • Desde 1932<br>
                    📧 <a href="mailto:paddlepapudo@gmail.com" 
                    style="color: #1e3a8a;">paddlepapudo@gmail.com</a><br>
                    📍 Camino Papudo - Zapallar, Papudo, Valparaíso<br>
                    🌐 <a href="https://clubgolfpapudo.cl" 
                    style="color: #1e3a8a;">clubgolfpapudo.cl</a>
                </p>
            </div>
        </div>
    </body>
    </html>
  `;
}

function generateICSContent(booking) {
  const startDateTime = new Date(`${booking.date}T${booking.timeSlot}:00`);
  const endDateTime = new Date(startDateTime.getTime() + 90 * 60000); // +90 minutos
  
  const formatDate = (date) => {
    return date.toISOString().replace(/[-:]/g, '').split('.')[0] + 'Z';
  };
  
  const courtName = getCourtName(booking.courtNumber);
  const playersNames = booking.players.map(p => p.name).join(', ');
  
  return `BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//Club de Golf Papudo//Padel//ES
BEGIN:VEVENT
UID:booking-${booking.id}@cgpreservas.web.app
DTSTART:${formatDate(startDateTime)}
DTEND:${formatDate(endDateTime)}
SUMMARY:Pádel - ${courtName}
DESCRIPTION:Reserva de pádel en ${courtName}\\nJugadores: ${playersNames}
LOCATION:Club de Golf Papudo\\nCamino Papudo - Zapallar\\nPapudo\\, Valparaíso
ORGANIZER:MAILTO:paddlepapudo@gmail.com
END:VEVENT
END:VCALENDAR`;
}

function getCourtName(courtNumber) {
  const courts = {
    "court_1": "Cancha 1 - PITE",
    "court_2": "Cancha 2 - LILEN", 
    "court_3": "Cancha 3 - PLAIYA",
  };
  return courts[courtNumber] || courtNumber;
}

function formatDate(dateStr) {
  const [year, month, day] = dateStr.split("-");
  const date = new Date(year, month - 1, day);
  return date.toLocaleDateString("es-ES", {
    weekday: "long",
    year: "numeric", 
    month: "long",
    day: "numeric",
  });
}

function getEndTime(startTime) {
  const [hours, minutes] = startTime.split(":").map(Number);
  const endDate = new Date();
  endDate.setHours(hours, minutes);
  endDate.setTime(endDate.getTime() + 90 * 60000);
  return endDate.toTimeString().slice(0, 5);
}