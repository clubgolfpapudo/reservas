// Deploy Fix 2025-06-05 14:35 - Individual cancellation URLs
// Google Sheets Integration - 2025-06-05 15:30

const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const nodemailer = require('nodemailer');
const {onRequest} = require("firebase-functions/v2/https");
const {onSchedule} = require("firebase-functions/v2/scheduler");
const {setGlobalOptions} = require("firebase-functions/v2");
const admin = require('firebase-admin');
const { GoogleSpreadsheet } = require('google-spreadsheet'); // Nueva dependencia

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
// NUEVA FUNCIÓN: VERIFICAR GOOGLE SHEETS API
// ============================================================================
exports.verifyGoogleSheetsAPI = onRequest({
  cors: true,
}, async (req, res) => {
  try {
    console.log('🔍 Verificando configuración de Google Sheets API...');
    
    const SHEET_ID = '1A-8RvvgkHXUP-985So8CBJvDAj50w58EFML1CJEq2c4';
    const SHEET_NAME = 'Maestro';
    
    // Verificar variables de entorno
    const serviceAccountEmail = "sheets-api-service@cgpreservas.iam.gserviceaccount.com";
    const privateKey = `-----BEGIN PRIVATE KEY-----
    MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQDjOl2rzfM4gPIT
    LgW34/wl1TY/elF6ic6JP53hxHWJZeyjd3q5eFl9fWvdDaujo641ymq0LDeW7rFS
    QnDhM+EmEmQEz/r6YFmzRhzneIZXSJDjGdSPdV3LkIuhn6Fz/2eiL+k9qMAx5Tea
    fPlLikd4UHhw4yEMpnmkt/MBxxW77taoCTTR/Es6e+j0/qpMmdY/G/E0jgjIITwR
    TIRgzyPgGmax+JZleXqQXZYDPlThozXqMZiVr6+4OPkZod2EUwCki+L2vdh+0KqW
    xZejkjZ8Yc89YWzAr2QXGh2V2wy8h4DLk+z7hBw0hhmc6qpfRPw8I51S553E8Q1V
    3K0EKQc7AgMBAAECggEAFhLg76QxqP8JxSg24P7SS2CThQYebS9+82FNNpXtrxvK
    KbUdJHBXDTRGarJ9xodLkKkpxXf4LH7ilfGjYpU2HYsy0S7dHD6I6Dv66deRAWCo
    xo8HUapeorxXfCt0NT8N87kAyP8gMJiqVqUmWJrFx5/Vm23NE5wGfCRshHMxHtDt
    f0CNZwXvgRQdIGgIBGk9sVspSWKWLqSjCK+aknaBlOieNq3VwhdytBYdr0HukLl2
    kV4FGGtOu2QbLTEfI1gZk1L48wOrSquHPt++OnOGe7AHCgykoj4IIvt9UMi+yp9q
    v+2nsBr8P5ZR0PS8oLIXn6JQwjUD7sDc/JTI2TeA9QKBgQD6tV5P4R75he3wxjxX
    5muean28Y6VwkJzvh3rd3ABj/8NC8AV7N0/Gf1j9f3EkK+Gf29cGbn6CkR9YyXya
    kDu8ZbNZHyXyI3V+bOnnQC+71D11TcKKdoLtYN2oicxMEHPxw9kXSG+XoOc4DCX0
    bpiVYEHq5VYesrzeHcJmNb0VhwKBgQDoBiCf1gz3rGg+aNEP5LFChcqNf5aFtfdG
    ElP2VXoLWtVlSeteQR0lVoduBHhp4gwBBdNdW/O/sRvlOMqYAADz9+R9dTay5NfO
    61n3RX+Dg8BHRnfKwEkJwtEkwYFE3pKHRppMwJV6j7KHHv2gEX8Xg7j8+jGHSIlS
    Cy038tFtrQKBgBuW0eYgc/QplOGmLwXNSZKJTYTpwk782whQ9GhtyW03vBklqLTC
    hXjmkrhyydSdL5sT6jm+9xUPO0/d/GRV8vzshCwOjXJ0DH35JlRYb+hPluPNxtbN
    6+KLglkFsQG93cSBNOanBgC9qDQ2wgaAFTJ7AUYELtH6AWbAB6CP0VsJAoGACbqY
    C5uyF4CHLna+rWftdtidUamT6i9jGvERzDZxU6CPahvbXqxkSHiEXTyav/XWgwR3
    hGaipdsLTGVBOXZmk9RFJG2RyZaG5gpAT3n+iskves2doEbHyTz+AAiNHxImGr3/
    IlDA886qsbe+8sNJDPdc/l6PTRjhiSsmzj3EQlECgYEA5cN5s0gG1lMi3g6BYgJI
    ygMUk3gc51IdnybXyunvNOMwBSf82fQE3OVLuQBDXISOkQUHBnjnrQYt5Vf1JZGU
    15SNAe15MPdYJujryWGEqw3Q6qHc1XGJJAfxMMz8YbO06czV6TZK9GOdREzWnvnM
    XZTXYEu54CkpfjQSs3dMAgY=
    -----END PRIVATE KEY-----`;
    
    console.log('📧 Service Account Email:', serviceAccountEmail ? 'CONFIGURADO' : '❌ FALTANTE');
    console.log('🔑 Private Key:', privateKey ? 'CONFIGURADO' : '❌ FALTANTE');
    
    if (!serviceAccountEmail || !privateKey) {
      return res.status(500).json({
        error: 'Credenciales de Google Sheets API no configuradas',
        missing: {
          serviceAccountEmail: !serviceAccountEmail,
          privateKey: !privateKey
        },
        instructions: [
          'Configurar variables de entorno en Firebase Functions:',
          'firebase functions:config:set google.service_account_email="tu-email@proyecto.iam.gserviceaccount.com"',
          'firebase functions:config:set google.private_key="-----BEGIN PRIVATE KEY-----\\n..."'
        ]
      });
    }
    
    // Intentar conectar a Google Sheets
    const doc = new GoogleSpreadsheet(SHEET_ID);
    
    await doc.useServiceAccountAuth({
      client_email: serviceAccountEmail,
      private_key: privateKey.replace(/\n    /g, '\n'),
    });
    
    console.log('✅ Autenticación exitosa');
    
    // Cargar información del documento
    await doc.loadInfo();
    console.log('📊 Documento cargado:', doc.title);
    
    // Verificar que existe la hoja 'Maestro'
    const sheet = doc.sheetsByTitle[SHEET_NAME];
    if (!sheet) {
      const availableSheets = Object.keys(doc.sheetsByTitle);
      return res.status(404).json({
        error: `Hoja '${SHEET_NAME}' no encontrada`,
        availableSheets: availableSheets,
        suggestion: 'Verificar nombre de la hoja'
      });
    }
    
    console.log('📋 Hoja encontrada:', sheet.title);
    
    // Cargar las primeras filas para verificar estructura
    await sheet.loadHeaderRow();
    const headers = sheet.headerValues;
    
    console.log('📝 Headers encontrados:', headers);
    
    // Verificar headers esperados
    const expectedHeaders = ['EMAIL', 'NOMBRE(S)', 'APELLIDO_PATERNO', 'APELLIDO_MATERNO', 'RUT/PASAPORTE', 'FECHA NACIMIENTO', 'RELACION', 'CELULAR'];
    const missingHeaders = expectedHeaders.filter(header => !headers.includes(header));
    const extraHeaders = headers.filter(header => !expectedHeaders.includes(header));
    
    // Obtener una muestra de datos
    const rows = await sheet.getRows({ limit: 3 });
    const sampleData = rows.map(row => ({
      email: row.EMAIL,
      nombres: row['NOMBRE(S)'],
      apellido_paterno: row.APELLIDO_PATERNO,
      apellido_materno: row.APELLIDO_MATERNO,
      relacion: row.RELACION,
      celular: row.CELULAR,
      formatted_name: formatUserName(
        row['NOMBRE(S)'] || '',
        row.APELLIDO_PATERNO || '',
        row.APELLIDO_MATERNO || ''
      )
    }));
    
    console.log('📊 Datos de muestra:', sampleData);
    
    res.json({
      success: true,
      message: '✅ Google Sheets API configurado correctamente',
      document: {
        title: doc.title,
        sheetName: sheet.title,
        rowCount: sheet.rowCount,
        columnCount: sheet.columnCount
      },
      headers: {
        found: headers,
        missing: missingHeaders,
        extra: extraHeaders,
        isValid: missingHeaders.length === 0
      },
      sampleData: sampleData,
      timestamp: new Date().toISOString()
    });
    
  } catch (error) {
    console.error('❌ Error verificando Google Sheets API:', error);
    
    res.status(500).json({
      error: 'Error al verificar Google Sheets API',
      message: error.message,
      code: error.code,
      suggestions: [
        'Verificar que las credenciales estén correctamente configuradas',
        'Verificar que la cuenta de servicio tenga acceso a la planilla',
        'Verificar que el ID de la planilla sea correcto',
        'Instalar dependencia: npm install google-spreadsheet'
      ]
    });
  }
});

// ============================================================================
// NUEVA FUNCIÓN: SINCRONIZAR USUARIOS DESDE GOOGLE SHEETS
// ============================================================================
exports.syncUsersFromSheets = onRequest({
  cors: true,
}, async (req, res) => {
  try {
    console.log('🔄 === SINCRONIZANDO USUARIOS DESDE GOOGLE SHEETS ===');
    
    const SHEET_ID = '1A-8RvvgkHXUP-985So8CBJvDAj50w58EFML1CJEq2c4';
    const SHEET_NAME = 'Maestro';
    
    // Verificar credenciales
    const serviceAccountEmail = "sheets-api-service@cgpreservas.iam.gserviceaccount.com";
    const privateKey = `-----BEGIN PRIVATE KEY-----
    MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQDjOl2rzfM4gPIT
    LgW34/wl1TY/elF6ic6JP53hxHWJZeyjd3q5eFl9fWvdDaujo641ymq0LDeW7rFS
    QnDhM+EmEmQEz/r6YFmzRhzneIZXSJDjGdSPdV3LkIuhn6Fz/2eiL+k9qMAx5Tea
    fPlLikd4UHhw4yEMpnmkt/MBxxW77taoCTTR/Es6e+j0/qpMmdY/G/E0jgjIITwR
    TIRgzyPgGmax+JZleXqQXZYDPlThozXqMZiVr6+4OPkZod2EUwCki+L2vdh+0KqW
    xZejkjZ8Yc89YWzAr2QXGh2V2wy8h4DLk+z7hBw0hhmc6qpfRPw8I51S553E8Q1V
    3K0EKQc7AgMBAAECggEAFhLg76QxqP8JxSg24P7SS2CThQYebS9+82FNNpXtrxvK
    KbUdJHBXDTRGarJ9xodLkKkpxXf4LH7ilfGjYpU2HYsy0S7dHD6I6Dv66deRAWCo
    xo8HUapeorxXfCt0NT8N87kAyP8gMJiqVqUmWJrFx5/Vm23NE5wGfCRshHMxHtDt
    f0CNZwXvgRQdIGgIBGk9sVspSWKWLqSjCK+aknaBlOieNq3VwhdytBYdr0HukLl2
    kV4FGGtOu2QbLTEfI1gZk1L48wOrSquHPt++OnOGe7AHCgykoj4IIvt9UMi+yp9q
    v+2nsBr8P5ZR0PS8oLIXn6JQwjUD7sDc/JTI2TeA9QKBgQD6tV5P4R75he3wxjxX
    5muean28Y6VwkJzvh3rd3ABj/8NC8AV7N0/Gf1j9f3EkK+Gf29cGbn6CkR9YyXya
    kDu8ZbNZHyXyI3V+bOnnQC+71D11TcKKdoLtYN2oicxMEHPxw9kXSG+XoOc4DCX0
    bpiVYEHq5VYesrzeHcJmNb0VhwKBgQDoBiCf1gz3rGg+aNEP5LFChcqNf5aFtfdG
    ElP2VXoLWtVlSeteQR0lVoduBHhp4gwBBdNdW/O/sRvlOMqYAADz9+R9dTay5NfO
    61n3RX+Dg8BHRnfKwEkJwtEkwYFE3pKHRppMwJV6j7KHHv2gEX8Xg7j8+jGHSIlS
    Cy038tFtrQKBgBuW0eYgc/QplOGmLwXNSZKJTYTpwk782whQ9GhtyW03vBklqLTC
    hXjmkrhyydSdL5sT6jm+9xUPO0/d/GRV8vzshCwOjXJ0DH35JlRYb+hPluPNxtbN
    6+KLglkFsQG93cSBNOanBgC9qDQ2wgaAFTJ7AUYELtH6AWbAB6CP0VsJAoGACbqY
    C5uyF4CHLna+rWftdtidUamT6i9jGvERzDZxU6CPahvbXqxkSHiEXTyav/XWgwR3
    hGaipdsLTGVBOXZmk9RFJG2RyZaG5gpAT3n+iskves2doEbHyTz+AAiNHxImGr3/
    IlDA886qsbe+8sNJDPdc/l6PTRjhiSsmzj3EQlECgYEA5cN5s0gG1lMi3g6BYgJI
    ygMUk3gc51IdnybXyunvNOMwBSf82fQE3OVLuQBDXISOkQUHBnjnrQYt5Vf1JZGU
    15SNAe15MPdYJujryWGEqw3Q6qHc1XGJJAfxMMz8YbO06czV6TZK9GOdREzWnvnM
    XZTXYEu54CkpfjQSs3dMAgY=
    -----END PRIVATE KEY-----`;
    
    if (!serviceAccountEmail || !privateKey) {
      return res.status(500).json({
        error: 'Credenciales de Google Sheets API no configuradas'
      });
    }
    
    // Conectar a Google Sheets
    const doc = new GoogleSpreadsheet(SHEET_ID);
    await doc.useServiceAccountAuth({
      client_email: serviceAccountEmail,
      private_key: privateKey.replace(/\n    /g, '\n'),
    });
    
    await doc.loadInfo();
    const sheet = doc.sheetsByTitle[SHEET_NAME];
    
    if (!sheet) {
      return res.status(404).json({
        error: `Hoja '${SHEET_NAME}' no encontrada`
      });
    }
    
    // Leer todas las filas
    const rows = await sheet.getRows();
    const rowsToProcess = rows.slice(0, 50); // Procesar solo 50 por vez
    console.log(`📊 Procesando ${rowsToProcess.length} de ${rows.length} usuarios`);
    console.log(`📊 Procesando ${rows.length} usuarios desde Google Sheets`);
    
    const db = admin.firestore();
    const usersRef = db.collection('users');
    
    // Estadísticas de sincronización
    const stats = {
      processed: 0,
      created: 0,
      updated: 0,
      errors: 0,
      filtered: 0 // emails inválidos o vacíos
    };
    
    // Procesar cada fila
    for (const row of rowsToProcess) {
      try {
        stats.processed++;
        
        const email = (row.EMAIL || '').trim().toLowerCase();
        const nombres = (row['NOMBRE(S)'] || '').trim();
        const apellidoPaterno = (row.APELLIDO_PATERNO || '').trim();
        const apellidoMaterno = (row.APELLIDO_MATERNO || '').trim();
        const rutPasaporte = (row['RUT/PASAPORTE'] || '').trim();
        const fechaNacimiento = (row['FECHA NACIMIENTO'] || '').trim();
        const relacion = (row.RELACION || '').trim();
        const celular = (row.CELULAR || '').trim();
        
        // Validar email
        if (!email || !email.includes('@')) {
          console.log(`⚠️ Email inválido o vacío para: ${nombres} ${apellidoPaterno}`);
          stats.filtered++;
          continue;
        }
        
        // Formatear nombre según lógica requerida
        const formattedName = formatUserName(nombres, apellidoPaterno, apellidoMaterno);
        
        // Preparar documento del usuario
        const userData = {
          email: email,
          nombres: nombres,
          apellidoPaterno: apellidoPaterno,
          apellidoMaterno: apellidoMaterno,
          displayName: formattedName,
          rutPasaporte: rutPasaporte,
          fechaNacimiento: fechaNacimiento,
          relacion: relacion,
          celular: celular,
          isActive: true,
          lastSyncFromSheets: admin.firestore.FieldValue.serverTimestamp(),
          source: 'google_sheets'
        };
        
        // Verificar si el usuario ya existe
        const userDoc = await usersRef.doc(email).get();
        
        if (userDoc.exists) {
          // Actualizar usuario existente
          await usersRef.doc(email).update(userData);
          stats.updated++;
          console.log(`🔄 Usuario actualizado: ${formattedName} (${email})`);
        } else {
          // Crear nuevo usuario
          await usersRef.doc(email).set({
            ...userData,
            createdAt: admin.firestore.FieldValue.serverTimestamp()
          });
          stats.created++;
          console.log(`✅ Usuario creado: ${formattedName} (${email})`);
        }
        
      } catch (error) {
        stats.errors++;
        console.error(`❌ Error procesando usuario: ${error.message}`);
      }
    }
    
    // Marcar timestamp de última sincronización
    await db.collection('system').doc('sync_status').set({
      lastSync: new Date(),
      stats: stats,
      source: 'google_sheets',
      sheetId: SHEET_ID,
      sheetName: SHEET_NAME
    }, { merge: true });
    
    console.log('📊 === RESUMEN DE SINCRONIZACIÓN ===');
    console.log(`📋 Procesados: ${stats.processed}`);
    console.log(`✅ Creados: ${stats.created}`);
    console.log(`🔄 Actualizados: ${stats.updated}`);
    console.log(`⚠️ Filtrados: ${stats.filtered}`);
    console.log(`❌ Errores: ${stats.errors}`);
    
    res.json({
      success: true,
      message: 'Sincronización completada exitosamente',
      stats: stats,
      timestamp: new Date().toISOString()
    });
    
  } catch (error) {
    console.error('❌ Error en sincronización:', error);
    res.status(500).json({
      error: 'Error sincronizando usuarios',
      message: error.message
    });
  }
});

// ============================================================================
// NUEVA FUNCIÓN: OBTENER USUARIOS PARA EL FRONTEND
// ============================================================================
exports.getUsers = onRequest({
  cors: true,
}, async (req, res) => {
  try {
    console.log('👥 Obteniendo usuarios desde Firebase...');
    
    const db = admin.firestore();
    const usersSnapshot = await db.collection('users')
      .where('isActive', '==', true)
      .orderBy('displayName')
      .get();
    
    const users = [];
    usersSnapshot.forEach(doc => {
      const userData = doc.data();
      users.push({
        email: doc.id,
        name: userData.displayName,
        phone: userData.celular || '',
        relacion: userData.relacion || '',
        // Solo incluir campos necesarios para el frontend
      });
    });
    
    console.log(`👥 Enviando ${users.length} usuarios al frontend`);
    
    res.json({
      success: true,
      users: users,
      count: users.length,
      timestamp: new Date().toISOString()
    });
    
  } catch (error) {
    console.error('❌ Error obteniendo usuarios:', error);
    res.status(500).json({
      error: 'Error obteniendo usuarios',
      message: error.message
    });
  }
});

// ============================================================================
// ENVÍO DE EMAILS DE CONFIRMACIÓN
// ============================================================================

// Esta versión incluye las funciones auxiliares seguras
exports.sendBookingEmailHTTP = onRequest({
  region: 'us-central1',
  cors: true
}, async (req, res) => {
  console.log('📧 === ENVIANDO EMAILS CON GMAIL APP PASSWORD ===');
  console.log('📧 Body:', JSON.stringify(req.body, null, 2));
  
  try {
    const bookingData = req.body;
    const booking = bookingData.booking || bookingData;
    
    // Normalizar datos para compatibilidad
    const normalizedBooking = {
      date: booking.date,
      time: booking.time || booking.timeSlot,
      courtId: booking.courtId || booking.courtNumber,
      players: booking.players || []
    };
    
    console.log(`📧 Procesando reserva: ${normalizedBooking.courtId} ${normalizedBooking.date} ${normalizedBooking.time}`);
    console.log(`📧 Jugadores: ${normalizedBooking.players.length}`);
    
    if (!normalizedBooking.players || normalizedBooking.players.length === 0) {
      throw new Error('No hay jugadores en la reserva');
    }
    
    // Configurar Gmail transporter
    console.log('📧 Configurando Gmail transporter...');
    const transporter = nodemailer.createTransport({
      host: 'smtp.gmail.com',
      port: 587,
      secure: false,
      auth: {
        user: 'paddlepapudo@gmail.com',
        pass: 'yyll uhje izsv mbwc'
      },
      tls: {
        rejectUnauthorized: false
      }
    });
    
    // Verificar si hay usuarios VISITA
    const isVisitorBooking = normalizedBooking.players.some(player => {
      const playerName = typeof player === 'string' ? player : (player.name || '');
      return playerName.toUpperCase().includes('VISITA');
    });
    
    // Enviar emails
    const emailResults = [];
    
    for (let i = 0; i < normalizedBooking.players.length; i++) {
      const player = normalizedBooking.players[i];
      const playerName = typeof player === 'string' ? player : (player.name || 'Jugador');
      const playerEmail = typeof player === 'string' ? null : player.email;
      
      if (!playerEmail) {
        console.log(`⏭️ Saltando ${playerName} - no tiene email`);
        continue;
      }
      
      console.log(`📧 Enviando email ${i + 1}/${normalizedBooking.players.length} a: ${playerName} (${playerEmail})`);
      
      // Generar ID único para este email
      const emailId = `${normalizedBooking.courtId.replace('_', '')}-${normalizedBooking.date}-${normalizedBooking.time.replace(':', '')}`;
      console.log(`📧 ID generado para ${playerName}: ${emailId}`);
      
      try {
        // Es organizador si es el primer jugador con email válido
        const isOrganizer = emailResults.length === 0;
        const showVisitorMessage = isOrganizer && isVisitorBooking;
        
        const emailHtml = generateBookingEmailHtml(normalizedBooking, playerName, showVisitorMessage, playerEmail);
        
        const mailOptions = {
          from: {
            name: 'Club de Golf Papudo',
            address: 'paddlepapudo@gmail.com'
          },
          to: playerEmail,
          subject: `Reserva de Pádel Confirmada - ${formatDate(normalizedBooking.date)}`,
          html: emailHtml
        };
        
        await transporter.sendMail(mailOptions);
        console.log(`✅ Email enviado exitosamente a: ${playerName} (${playerEmail})`);
        emailResults.push({ success: true, player: playerName, email: playerEmail });
        
      } catch (emailError) {
        console.error(`❌ Error enviando email a ${playerName}:`, emailError);
        emailResults.push({ success: false, player: playerName, email: playerEmail, error: emailError.message });
      }
    }
    
    const successCount = emailResults.filter(r => r.success).length;
    const failCount = emailResults.filter(r => !r.success).length;
    
    console.log('📧 === RESUMEN ===');
    console.log(`✅ Exitosos: ${successCount}/${emailResults.length}`);
    console.log(`❌ Fallidos: ${failCount}/${emailResults.length}`);
    
    res.status(200).json({
      success: true,
      message: `${successCount} emails enviados exitosamente`,
      results: emailResults,
      successCount: successCount,
      failCount: failCount
    });
    
  } catch (error) {
    console.error('❌ Error general:', error);
    res.status(500).json({
      success: false,
      message: error.message,
      error: error.toString()
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
        const courtNumber = idParts[0];
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
              lastModified: new Date()
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
          lastModified: new Date()
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
                    ${(() => {
                        // Mapeo de canchas
                        const courtNames = {
                            'court_1': 'PITE',
                            'court_2': 'LILEN',
                            'court_3': 'PLAIYA'
                        };
                        
                        // Extraer información del bookingId
                        const parts = bookingId.split('-');
                        const courtId = parts[0];
                        const date = parts.slice(1, 4).join('-');
                        const timeRaw = parts[4];
                        
                        // Obtener nombre amigable de la cancha
                        const courtName = courtNames[courtId] || courtId;
                        
                        // Formatear hora (1930 → 19:30)
                        const formattedTime = timeRaw.slice(0,2) + ':' + timeRaw.slice(2);
                        
                        return `Reserva: ${courtName} - ${date} - ${formattedTime}`;
                    })()}<br>
                    Jugador: ${decodeURIComponent(playerEmail)}
                </div>
                
                <a href="https://cgpreservas.web.app" class="button">
                    🏓 Ir a Reservas
                </a>
                
                <a href="#" onclick="window.close(); return false;" class="button">
                    🔙 Volver al Correo
                </a>
                
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
// SINCRONIZACIÓN PROGRAMADA DIARIA - NUEVA FUNCIÓN
// ============================================================================

exports.dailyUserSync = onSchedule({
  schedule: "0 6 * * *", // Todos los días a las 6:00 AM (UTC-3 = 3:00 AM Chile)
  timeZone: "America/Santiago", // Timezone de Chile
  memory: "1GiB", // ← MÁS MEMORIA
  timeoutSeconds: 540, // ← 9 MINUTOS (máximo permitido)
}, async (context) => {
  try {
    console.log('🔄 === SINCRONIZACIÓN AUTOMÁTICA DIARIA INICIADA ===');
    console.log('⏰ Timestamp:', new Date().toISOString());
    console.log('🌍 Timezone: America/Santiago');
    
    const startTime = Date.now();
    
    // ========================================================================
    // REUTILIZAR LÓGICA DE SINCRONIZACIÓN EXISTENTE
    // ========================================================================
    
    const SHEET_ID = '1A-8RvvgkHXUP-985So8CBJvDAj50w58EFML1CJEq2c4';
    const SHEET_NAME = 'Maestro';
    
    // Credenciales (reutilizar las existentes)
    const serviceAccountEmail = "sheets-api-service@cgpreservas.iam.gserviceaccount.com";
    const privateKey = `-----BEGIN PRIVATE KEY-----
    MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQDjOl2rzfM4gPIT
    LgW34/wl1TY/elF6ic6JP53hxHWJZeyjd3q5eFl9fWvdDaujo641ymq0LDeW7rFS
    QnDhM+EmEmQEz/r6YFmzRhzneIZXSJDjGdSPdV3LkIuhn6Fz/2eiL+k9qMAx5Tea
    fPlLikd4UHhw4yEMpnmkt/MBxxW77taoCTTR/Es6e+j0/qpMmdY/G/E0jgjIITwR
    TIRgzyPgGmax+JZleXqQXZYDPlThozXqMZiVr6+4OPkZod2EUwCki+L2vdh+0KqW
    xZejkjZ8Yc89YWzAr2QXGh2V2wy8h4DLk+z7hBw0hhmc6qpfRPw8I51S553E8Q1V
    3K0EKQc7AgMBAAECggEAFhLg76QxqP8JxSg24P7SS2CThQYebS9+82FNNpXtrxvK
    KbUdJHBXDTRGarJ9xodLkKkpxXf4LH7ilfGjYpU2HYsy0S7dHD6I6Dv66deRAWCo
    xo8HUapeorxXfCt0NT8N87kAyP8gMJiqVqUmWJrFx5/Vm23NE5wGfCRshHMxHtDt
    f0CNZwXvgRQdIGgIBGk9sVspSWKWLqSjCK+aknaBlOieNq3VwhdytBYdr0HukLl2
    kV4FGGtOu2QbLTEfI1gZk1L48wOrSquHPt++OnOGe7AHCgykoj4IIvt9UMi+yp9q
    v+2nsBr8P5ZR0PS8oLIXn6JQwjUD7sDc/JTI2TeA9QKBgQD6tV5P4R75he3wxjxX
    5muean28Y6VwkJzvh3rd3ABj/8NC8AV7N0/Gf1j9f3EkK+Gf29cGbn6CkR9YyXya
    kDu8ZbNZHyXyI3V+bOnnQC+71D11TcKKdoLtYN2oicxMEHPxw9kXSG+XoOc4DCX0
    bpiVYEHq5VYesrzeHcJmNb0VhwKBgQDoBiCf1gz3rGg+aNEP5LFChcqNf5aFtfdG
    ElP2VXoLWtVlSeteQR0lVoduBHhp4gwBBdNdW/O/sRvlOMqYAADz9+R9dTay5NfO
    61n3RX+Dg8BHRnfKwEkJwtEkwYFE3pKHRppMwJV6j7KHHv2gEX8Xg7j8+jGHSIlS
    Cy038tFtrQKBgBuW0eYgc/QplOGmLwXNSZKJTYTpwk782whQ9GhtyW03vBklqLTC
    hXjmkrhyydSdL5sT6jm+9xUPO0/d/GRV8vzshCwOjXJ0DH35JlRYb+hPluPNxtbN
    6+KLglkFsQG93cSBNOanBgC9qDQ2wgaAFTJ7AUYELtH6AWbAB6CP0VsJAoGACbqY
    C5uyF4CHLna+rWftdtidUamT6i9jGvERzDZxU6CPahvbXqxkSHiEXTyav/XWgwR3
    hGaipdsLTGVBOXZmk9RFJG2RyZaG5gpAT3n+iskves2doEbHyTz+AAiNHxImGr3/
    IlDA886qsbe+8sNJDPdc/l6PTRjhiSsmzj3EQlECgYEA5cN5s0gG1lMi3g6BYgJI
    ygMUk3gc51IdnybXyunvNOMwBSf82fQE3OVLuQBDXISOkQUHBnjnrQYt5Vf1JZGU
    15SNAe15MPdYJujryWGEqw3Q6qHc1XGJJAfxMMz8YbO06czV6TZK9GOdREzWnvnM
    XZTXYEu54CkpfjQSs3dMAgY=
    -----END PRIVATE KEY-----`;
    
    if (!serviceAccountEmail || !privateKey) {
      throw new Error('Credenciales de Google Sheets no configuradas');
    }
    
    // Conectar a Google Sheets
    const doc = new GoogleSpreadsheet(SHEET_ID);
    await doc.useServiceAccountAuth({
      client_email: serviceAccountEmail,
      private_key: privateKey.replace(/\n    /g, '\n'),
    });
    
    await doc.loadInfo();
    console.log('📊 Documento Google Sheets cargado:', doc.title);
    
    const sheet = doc.sheetsByTitle[SHEET_NAME];
    if (!sheet) {
      throw new Error(`Hoja '${SHEET_NAME}' no encontrada`);
    }
    
    // Leer todas las filas
    const rows = await sheet.getRows();
    console.log(`📊 Filas encontradas en Sheets: ${rows.length}`);
    
    // Procesar TODOS los usuarios de una vez
    const rowsToProcess = rows; // ← CAMBIO: procesar todos
    console.log(`🔄 Procesando TODOS los ${rowsToProcess.length} usuarios...`);
    
    const db = admin.firestore();
    const usersRef = db.collection('users');
    
    // Estadísticas
    const stats = {
      processed: 0,
      created: 0,
      updated: 0,
      errors: 0,
      filtered: 0
    };
    
    // Procesar usuarios
    for (const row of rowsToProcess) {
      try {
        stats.processed++;
        
        const email = (row.EMAIL || '').trim().toLowerCase();
        const nombres = (row['NOMBRE(S)'] || '').trim();
        const apellidoPaterno = (row.APELLIDO_PATERNO || '').trim();
        const apellidoMaterno = (row.APELLIDO_MATERNO || '').trim();
        const rutPasaporte = (row['RUT/PASAPORTE'] || '').trim();
        const fechaNacimiento = (row['FECHA NACIMIENTO'] || '').trim();
        const relacion = (row.RELACION || '').trim();
        const celular = (row.CELULAR || '').trim();
        
        // Validar email
        if (!email || !email.includes('@')) {
          stats.filtered++;
          continue;
        }
        
        // Formatear nombre
        const formattedName = formatUserName(nombres, apellidoPaterno, apellidoMaterno);
        
        // Datos del usuario
        const userData = {
          email: email,
          nombres: nombres,
          apellidoPaterno: apellidoPaterno,
          apellidoMaterno: apellidoMaterno,
          displayName: formattedName,
          rutPasaporte: rutPasaporte,
          fechaNacimiento: fechaNacimiento,
          relacion: relacion,
          celular: celular,
          isActive: true,
          lastSyncFromSheets: admin.firestore.FieldValue.serverTimestamp(),
          source: 'google_sheets_auto'
        };
        
        // Verificar si existe
        const userDoc = await usersRef.doc(email).get();
        
        if (userDoc.exists) {
          await usersRef.doc(email).update(userData);
          stats.updated++;
        } else {
          await usersRef.doc(email).set({
            ...userData,
            createdAt: admin.firestore.FieldValue.serverTimestamp()
          });
          stats.created++;
        }
        
      } catch (error) {
        stats.errors++;
        console.error(`❌ Error procesando usuario:`, error.message);
      }
    }
    
    // Marcar timestamp de sincronización
    await db.collection('system').doc('sync_status').set({
      lastAutoSync: new Date(),
      autoSyncStats: stats,
      source: 'scheduled_sync',
      sheetId: SHEET_ID,
      executionTime: Date.now() - startTime
    }, { merge: true });
    
    // ========================================================================
    // LOGS DE RESUMEN
    // ========================================================================
    const executionTime = Date.now() - startTime;
    
    console.log('🎉 === SINCRONIZACIÓN AUTOMÁTICA COMPLETADA ===');
    console.log(`⏱️  Tiempo de ejecución: ${executionTime}ms`);
    console.log(`📋 Procesados: ${stats.processed}`);
    console.log(`✅ Creados: ${stats.created}`);
    console.log(`🔄 Actualizados: ${stats.updated}`);
    console.log(`⚠️  Filtrados: ${stats.filtered}`);
    console.log(`❌ Errores: ${stats.errors}`);
    console.log(`🎯 Éxito: ${((stats.created + stats.updated) / stats.processed * 100).toFixed(1)}%`);
    
    // ========================================================================
    // OPCIONAL: NOTIFICACIÓN POR EMAIL (comentado por ahora)
    // ========================================================================
    /*
    if (stats.errors > 5) {
      // Enviar alerta si hay muchos errores
      await sendAdminAlert(`Sincronización con ${stats.errors} errores`);
    } else {
      // Enviar notificación de éxito
      await sendAdminNotification(`Usuarios sincronizados: ${stats.created + stats.updated}`);
    }
    */
    
    console.log('✅ Sincronización programada completada exitosamente');
    
  } catch (error) {
    console.error('❌ ERROR CRÍTICO en sincronización programada:', error);
    
    // Guardar error en Firestore para debugging
    try {
      await admin.firestore().collection('system').doc('sync_errors').set({
        timestamp: new Date(),
        error: error.message,
        stack: error.stack,
        source: 'scheduled_sync'
      }, { merge: true });
    } catch (e) {
      console.error('❌ Error guardando log de error:', e);
    }
    
    // ========================================================================
    // OPCIONAL: NOTIFICACIÓN DE ERROR (comentado por ahora)
    // ========================================================================
    /*
    try {
      await sendAdminAlert(`Error en sincronización automática: ${error.message}`);
    } catch (e) {
      console.error('❌ Error enviando alerta:', e);
    }
    */
    
    throw error; // Re-lanzar para que Firebase Functions registre el error
  }
});

// ============================================================================
// FUNCIONES AUXILIARES
// ============================================================================

// Función utilitaria para formatear nombres según la lógica requerida
function formatUserName(nombres, apellidoPaterno, apellidoMaterno) {
  try {
    // PRIMER NOMBRE (espacio) INICIAL SEGUNDO NOMBRE (ESPACIO) PRIMER APELLIDO (espacio) INICIAL SEGUNDO APELLIDO
    
    const nombresArray = nombres.trim().split(' ').filter(n => n.length > 0);
    const primerNombre = nombresArray[0] || '';
    const segundoNombre = nombresArray[1] || '';
    
    const primerApellido = apellidoPaterno.trim();
    const segundoApellido = apellidoMaterno.trim();
    
    let formattedName = primerNombre;
    
    if (segundoNombre) {
      formattedName += ` ${segundoNombre.charAt(0)}.`;
    }
    
    if (primerApellido) {
      formattedName += ` ${primerApellido}`;
    }
    
    if (segundoApellido) {
      formattedName += ` ${segundoApellido.charAt(0)}.`;
    }
    
    return formattedName.trim();
  } catch (error) {
    console.error('Error formateando nombre:', error);
    return `${nombres} ${apellidoPaterno}`.trim();
  }
}

// En functions/index.js - función generateBookingEmailHtml()
// Reemplazar la sección del header con este CSS optimizado para Gmail

function generateBookingEmailHtml(booking, organizerName, isVisitorBooking = false, email) {
  const formattedDate = formatDate(booking.date);
  const courtName = getCourtName(booking.courtId);
  const endTime = getEndTime(booking.time);
  
  // Mensaje especial para usuarios VISITA (solo aparece para el organizador)
  const visitorMessage = isVisitorBooking ? `
    <div style="background-color: #fff3cd; border: 1px solid #ffeaa7; border-radius: 8px; padding: 16px; margin: 20px 0; font-family: Arial, sans-serif;">
      <div style="display: flex; align-items: center; margin-bottom: 8px;">
        <div style="background-color: #f39c12; color: white; border-radius: 50%; width: 24px; height: 24px; display: inline-flex; align-items: center; justify-content: center; margin-right: 8px; font-size: 14px; font-weight: bold;">!</div>
        <strong style="color: #856404;">Información para el organizador</strong>
      </div>
      <p style="margin: 0; color: #856404; line-height: 1.4;">
        Esta reserva incluye jugadores invitados (VISITA). Recuerda coordinar el pago correspondiente con la Administración del Club ANTES de la hora reservada.
      </p>
    </div>
  ` : '';

  return `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Reserva de Pádel Confirmada</title>
      <!--[if mso]>
      <noscript>
        <xml>
          <o:OfficeDocumentSettings>
            <o:PixelsPerInch>96</o:PixelsPerInch>
          </o:OfficeDocumentSettings>
        </xml>
      </noscript>
      <![endif]-->
    </head>
    <body style="margin: 0; padding: 0; background-color: #f5f5f5; font-family: Arial, sans-serif;">
      <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%" style="margin: 0; padding: 0;">
        <tr>
          <td style="padding: 20px 0;">
            <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="600" style="margin: 0 auto; background-color: #ffffff; border-radius: 12px; overflow: hidden; box-shadow: 0 4px 12px rgba(0,0,0,0.1);">
              
              <!-- HEADER OPTIMIZADO PARA GMAIL -->
              <tr>
                <td style="background: linear-gradient(135deg, #4f8ef7 0%, #2c5282 100%); padding: 40px 20px; text-align: center;">
                  <table role="presentation" cellspacing="0" cellpadding="0" border="0" style="margin: 0 auto;">
                    <tr>
                      <td style="text-align: center;">
                        <!-- Círculo principal con texto centrado usando table -->
                        <table role="presentation" cellspacing="0" cellpadding="0" border="0" style="margin: 0 auto;">
                          <tr>
                            <td style="width: 160px; height: 160px; background-color: rgba(255,255,255,0.2); border-radius: 50%; position: relative; vertical-align: middle; text-align: center;">
                              <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%" height="100%">
                                <tr>
                                  <td style="vertical-align: middle; text-align: center; line-height: 1.2;">
                                    <div style="color: white; font-size: 16px; font-weight: bold; margin: 0; padding: 0;">
                                      CLUB<br>GOLF<br>PAPUDO
                                    </div>
                                  </td>
                                </tr>
                              </table>
                            </td>
                            <td style="width: 20px;"></td>
                            <td style="vertical-align: middle;">
                              <!-- Círculo de Pádel usando table para mejor centrado -->
                              <table role="presentation" cellspacing="0" cellpadding="0" border="0">
                                <tr>
                                  <td style="width: 80px; height: 80px; background-color: rgba(255,255,255,0.3); border-radius: 50%; text-align: center; vertical-align: middle;">
                                    <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%" height="100%">
                                      <tr>
                                        <td style="vertical-align: middle; text-align: center;">
                                          <span style="color: white; font-size: 36px; font-weight: bold; line-height: 1; margin: 0; padding: 0;">P</span>
                                        </td>
                                      </tr>
                                    </table>
                                  </td>
                                </tr>
                              </table>
                            </td>
                            <td style="width: 20px;"></td>
                            <td style="vertical-align: middle;">
                              <h1 style="color: white; font-size: 32px; font-weight: bold; margin: 0; line-height: 1.2;">
                                Reserva Confirmada
                              </h1>
                            </td>
                          </tr>
                        </table>
                      </td>
                    </tr>
                  </table>
                </td>
              </tr>

              <!-- CONTENIDO DEL EMAIL -->
              <tr>
                <td style="padding: 40px 40px 20px 40px;">
                  <h2 style="color: #2d3748; font-size: 24px; margin: 0 0 20px 0; font-weight: bold;">
                    ¡Hola ${organizerName.toUpperCase()}!
                  </h2>
                  <p style="color: #4a5568; font-size: 16px; line-height: 1.6; margin: 0 0 30px 0;">
                    Tu reserva de pádel ha sido confirmada exitosamente. Te esperamos en la cancha.
                  </p>
                  
                  ${visitorMessage}
                </td>
              </tr>

              <!-- DETALLES DE LA RESERVA -->
              <tr>
                <td style="padding: 0 40px 40px 40px;">
                  <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%" style="border-left: 4px solid #4f8ef7; background-color: #f8fafc; border-radius: 8px;">
                    <tr>
                      <td style="padding: 24px;">
                        <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%">
                          <tr>
                            <td style="padding: 8px 0; border-bottom: 1px solid #e2e8f0;">
                              <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%">
                                <tr>
                                  <td style="width: 40px; vertical-align: top;">
                                    <span style="font-size: 18px;">📅</span>
                                  </td>
                                  <td style="vertical-align: top; padding-left: 12px;">
                                    <strong style="color: #2d3748; font-size: 16px;">Fecha:</strong>
                                  </td>
                                  <td style="text-align: right; vertical-align: top;">
                                    <span style="color: #4a5568; font-size: 16px;">${formattedDate}</span>
                                  </td>
                                </tr>
                              </table>
                            </td>
                          </tr>
                          <tr>
                            <td style="padding: 8px 0; border-bottom: 1px solid #e2e8f0;">
                              <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%">
                                <tr>
                                  <td style="width: 40px; vertical-align: top;">
                                    <span style="font-size: 18px;">🕐</span>
                                  </td>
                                  <td style="vertical-align: top; padding-left: 12px;">
                                    <strong style="color: #2d3748; font-size: 16px;">Hora:</strong>
                                  </td>
                                  <td style="text-align: right; vertical-align: top;">
                                    <span style="color: #4a5568; font-size: 16px;">${booking.time} - ${endTime}</span>
                                  </td>
                                </tr>
                              </table>
                            </td>
                          </tr>
                          <tr>
                            <td style="padding: 8px 0;">
                              <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%">
                                <tr>
                                  <td style="width: 40px; vertical-align: top;">
                                    <span style="font-size: 18px;">🏓</span>
                                  </td>
                                  <td style="vertical-align: top; padding-left: 12px;">
                                    <strong style="color: #2d3748; font-size: 16px;">Cancha:</strong>
                                  </td>
                                  <td style="text-align: right; vertical-align: top;">
                                    <span style="color: #4a5568; font-size: 16px;">${courtName}</span>
                                  </td>
                                </tr>
                              </table>
                            </td>
                          </tr>
                        </table>
                      </td>
                    </tr>
                  </table>
                </td>
              </tr>

              <!-- JUGADORES -->
              <tr>
                <td style="padding: 0 40px 20px 40px;">
                  <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%" style="border-left: 4px solid #10b981; background-color: #f0fdf4; border-radius: 8px;">
                    <tr>
                      <td style="padding: 20px;">
                        <h3 style="color: #065f46; margin: 0 0 16px 0; font-size: 18px; font-weight: bold;">
                          👥 Jugadores (${booking.players.length}/4):
                        </h3>
                        ${booking.players.map((player, index) => {
                          const playerName = typeof player === 'string' ? player : (player.name || 'Jugador');
                          const isOrganizer = index === 0;
                          return `
                            <div style="padding: 8px 0; color: #047857; font-size: 16px; display: flex; align-items: center;">
                              <span style="margin-right: 8px; font-size: 18px;">${isOrganizer ? '🏆' : '•'}</span>
                              <span><strong>${playerName}</strong>${isOrganizer ? ' <em>(Organizador)</em>' : ''}</span>
                            </div>
                          `;
                        }).join('')}
                      </td>
                    </tr>
                  </table>
                </td>
              </tr>

              <!-- BOTÓN CANCELAR -->
              <tr>
                <td style="padding: 0 40px 20px 40px; text-align: center;">
                  <a href="https://us-central1-cgpreservas.cloudfunctions.net/cancelBooking?id=${booking.id || `${booking.courtNumber || booking.courtId}-${booking.date}-${(booking.timeSlot || booking.time || '').replace(/:/g, '')}`}&email=${encodeURIComponent(email)}" style="background: #dc2626; color: white; padding: 16px 32px; text-decoration: none; border-radius: 8px; font-weight: bold; font-size: 16px; display: inline-block; margin: 10px 0; box-shadow: 0 2px 4px rgba(0,0,0,0.2);">❌ Cancelar Reserva</a>
                </td>
              </tr>

              <!-- MENSAJE IMPORTANTE -->
              <tr>
                <td style="padding: 0 40px 20px 40px;">
                  <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%" style="background: #fef3cd; border-radius: 6px; border-left: 4px solid #f59e0b;">
                    <tr>
                      <td style="padding: 16px;">
                        <p style="margin: 0; color: #92400e; font-size: 14px; line-height: 1.6;">
                          <strong>💡 Importante:</strong> Si no has reservado, o no estás al tanto de esta invitación, o no puedes asistir, <strong>cancela</strong> esta reserva, haciendo clic en el botón de arriba. Se notificará automáticamente a los otros jugadores.
                        </p>
                      </td>
                    </tr>
                  </table>
                </td>
              </tr>

              <!-- FOOTER COMPLETO - REEMPLAZAR EL FOOTER ACTUAL -->
              <tr>
                <td style="background: #f8fafc; padding: 20px 40px; text-align: center; color: #64748b; font-size: 14px; border-top: 1px solid #e2e8f0;">
                  <p style="margin: 0 0 8px 0; line-height: 1.4;">
                    <strong>Club de Golf Papudo</strong> • Desde 1932<br>
                    📧 <a href="mailto:anibalreinosomendez@gmail.com" style="color: #1e3a8a;">paddlepapudo@gmail.com</a><br>
                    📍 Miraflores s/n - Papudo, Valparaíso<br>
                    🌐 <a href="https://clubgolfpapudo.cl" style="color: #1e3a8a;">clubgolfpapudo.cl</a>
                  </p>
                </td>
              </tr>
            </table>
          </td>
        </tr>
      </table>
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

function getCourtName(courtId) {
  console.log('🏓 getCourtName recibió:', courtId, 'tipo:', typeof courtId);
  
  try {
    if (!courtId) {
      console.warn('⚠️ getCourtName: courtId es null/undefined');
      return 'Cancha Desconocida';
    }
    
    const courtStr = String(courtId).trim().toLowerCase();
    
    const courts = {
      'court1': 'Cancha 1 - PITE',
      'court_1': 'Cancha 1 - PITE',
      'court2': 'Cancha 2 - LILEN', 
      'court_2': 'Cancha 2 - LILEN',
      'court3': 'Cancha 3 - PLAYA',
      'court_3': 'Cancha 3 - PLAYA',
      'court4': 'Cancha 4 - PEUMO',
      'court_4': 'Cancha 4 - PEUMO'
    };
    
    const result = courts[courtStr] || `Cancha ${courtId}`;
    console.log('🏓 getCourtName resultado:', result);
    
    return result;
    
  } catch (error) {
    console.error('❌ Error en getCourtName:', error);
    console.error('❌ courtId original:', courtId);
    return 'Cancha Desconocida';
  }
}

// Función formatDate segura (línea ~1333)
function formatDate(dateString) {
  console.log('📅 formatDate recibió:', dateString, 'tipo:', typeof dateString);
  
  try {
    // Validar que dateString existe y no es null/undefined
    if (!dateString) {
      console.warn('⚠️ formatDate: dateString es null/undefined, usando fecha actual');
      dateString = new Date().toISOString().split('T')[0]; // YYYY-MM-DD format
    }
    
    // Convertir a string si no lo es
    const dateStr = String(dateString).trim();
    
    if (!dateStr) {
      console.warn('⚠️ formatDate: dateString vacío después de trim, usando fecha actual');
      dateString = new Date().toISOString().split('T')[0];
    }
    
    console.log('📅 formatDate procesando:', dateStr);
    
    // Intentar crear fecha
    let date;
    
    // Si ya es un formato ISO (YYYY-MM-DD), usarlo directamente
    if (dateStr.match(/^\d{4}-\d{2}-\d{2}$/)) {
      date = new Date(dateStr + 'T12:00:00-03:00'); // Agregar hora para evitar timezone issues
    } else {
      // Intentar otros formatos
      date = new Date(dateStr);
    }
    
    // Verificar que la fecha es válida
    if (isNaN(date.getTime())) {
      console.error('❌ formatDate: Fecha inválida:', dateStr);
      date = new Date(); // Usar fecha actual como fallback
    }
    
    console.log('📅 formatDate fecha creada:', date);
    
    const options = { 
      weekday: 'long', 
      year: 'numeric', 
      month: 'long', 
      day: 'numeric',
      timeZone: 'America/Santiago'
    };
    
    const formatted = date.toLocaleDateString('es-ES', options);
    console.log('📅 formatDate resultado:', formatted);
    
    return formatted;
    
  } catch (error) {
    console.error('❌ Error en formatDate:', error);
    console.error('❌ dateString original:', dateString);
    
    // Fallback: usar fecha actual formateada
    const fallbackDate = new Date();
    const fallbackFormatted = fallbackDate.toLocaleDateString('es-ES', {
      weekday: 'long', 
      year: 'numeric', 
      month: 'long', 
      day: 'numeric',
      timeZone: 'America/Santiago'
    });
    
    console.log('🔄 formatDate usando fallback:', fallbackFormatted);
    return fallbackFormatted;
  }
}

// Función getEndTime segura
function getEndTime(startTime) {
  console.log('🕐 getEndTime recibió:', startTime, 'tipo:', typeof startTime);
  
  try {
    // Validar que startTime existe
    if (!startTime) {
      console.warn('⚠️ getEndTime: startTime es null/undefined');
      return 'N/A';
    }
    
    const timeStr = String(startTime).trim();
    
    if (!timeStr || !timeStr.includes(':')) {
      console.warn('⚠️ getEndTime: formato de tiempo inválido:', timeStr);
      return 'N/A';
    }
    
    const timeParts = timeStr.split(':');
    
    if (timeParts.length < 2) {
      console.warn('⚠️ getEndTime: no se pudo dividir tiempo:', timeStr);
      return 'N/A';
    }
    
    const hours = parseInt(timeParts[0], 10);
    const minutes = parseInt(timeParts[1], 10);
    
    if (isNaN(hours) || isNaN(minutes)) {
      console.warn('⚠️ getEndTime: horas o minutos no son números:', hours, minutes);
      return 'N/A';
    }
    
    console.log('🕐 getEndTime procesando:', hours, ':', minutes);
    
    const endHours = hours + 1;
    const endMinutes = minutes + 30;
    
    let finalHours = endHours;
    let finalMinutes = endMinutes;
    
    if (finalMinutes >= 60) {
      finalHours = endHours + 1;
      finalMinutes = endMinutes - 60;
    }
    
    const result = `${String(finalHours).padStart(2, '0')}:${String(finalMinutes).padStart(2, '0')}`;
    console.log('🕐 getEndTime resultado:', result);
    
    return result;
    
  } catch (error) {
    console.error('❌ Error en getEndTime:', error);
    console.error('❌ startTime original:', startTime);
    return 'N/A';
  }
}

// Función auxiliar para envío desde trigger
async function sendBookingEmailFirestore(transporter, email, booking, playerName, showVisitorMessage = false) {
  console.log(`📧 Enviando email desde trigger a: ${email} para jugador: ${playerName}`);
  
  const msg = {
    from: {
      name: 'Club de Golf Papudo',
      address: 'paddlepapudo@gmail.com'
    },
    to: email,
    subject: `Reserva de Pádel Confirmada - ${formatDate(booking.date)}`,
    html: generateBookingEmailHtml(booking, playerName, showVisitorMessage, email)
  };
  
  try {
    await transporter.sendMail(msg);
    console.log(`✅ Email trigger enviado exitosamente a: ${email}`);
    return { success: true, email: email };
  } catch (error) {
    console.error(`❌ Error enviando email trigger a ${email}:`, error);
    throw error;
  }
}