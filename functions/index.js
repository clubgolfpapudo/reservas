// Deploy Fix 2025-06-05 14:35 - Individual cancellation URLs
// Google Sheets Integration - 2025-06-05 15:30

const {onRequest} = require("firebase-functions/v2/https");
const {setGlobalOptions} = require("firebase-functions/v2");
const nodemailer = require("nodemailer");
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
      lastSync: admin.firestore.FieldValue.serverTimestamp(),
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
                        <span class="detail-label">📅 Fecha:&nbsp;</span>
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

  // Fix: Agregar espacio después de "Fecha" en el template
  return " " + formatted;
}

function getEndTime(startTime) {
  const [hours, minutes] = startTime.split(":").map(Number);
  const endDate = new Date();
  endDate.setHours(hours, minutes);
  endDate.setTime(endDate.getTime() + 90 * 60000);
  return endDate.toTimeString().slice(0, 5);
}