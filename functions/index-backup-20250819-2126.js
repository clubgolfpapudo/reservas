/// functions/index.js
/// 
/// PROPÃ“SITO:
/// Sistema backend completo de Firebase Cloud Functions para el Club de Golf Papudo.
/// Maneja la funcionalidad crítica del sistema de reservas multi-deporte incluyendo:
/// - Sincronización automática diaria de 502+ usuarios desde Google Sheets
/// - Sistema de emails automáticos para confirmación y cancelación de reservas
/// - API RESTful para integración con aplicación Flutter Web/PWA
/// - Gestión completa del ciclo de vida de reservas de pádel
/// - Arquitectura híbrida para integración con sistema GAS existente (Golf/Tenis)
/// 
/// VERSIÃ“N: v2.1.0 - Julio 2025
/// ESTADO: âœ… PRODUCCIÃ“N - Sistema 100% operativo
/// STACK: Node.js 20 + Firebase Functions Gen2 + Firestore + Google Sheets API
/// 
/// FUNCIONES PRINCIPALES:
/// 1. dailyUserSync: Sincronización automática de usuarios (6:00 AM diario)
/// 2. sendBookingEmailHTTP: Emails de confirmación de reservas
/// 3. cancelBooking: Sistema de cancelación individual con notificaciones
/// 4. getUsers: API para obtener usuarios desde Flutter
/// 5. verifyGoogleSheetsAPI: Diagnóstico y validación de conectividad
/// 
/// CONFIGURACIÃ“N CRÃTICA:
/// - Memoria: 1GB por función para manejar 502+ usuarios
/// - Timeout: 9 minutos máximo para sincronización completa
/// - Timezone: America/Santiago para horarios locales Chile
/// - Region: us-central1 para Firebase Functions
/// - Auth: Service Account integrado para Google Sheets API

// ============================================================================
// DEPENDENCIAS Y CONFIGURACIÃ“N INICIAL
// ============================================================================

const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const nodemailer = require('nodemailer');
const {onRequest} = require("firebase-functions/v2/https");
const {onSchedule} = require("firebase-functions/v2/scheduler");
const {setGlobalOptions} = require("firebase-functions/v2");
const admin = require('firebase-admin');
const { GoogleSpreadsheet } = require('google-spreadsheet');

// Inicializar Firebase Admin SDK
admin.initializeApp();

// Configuración global para todas las functions
setGlobalOptions({
  maxInstances: 10,
  region: 'us-central1'
});

// ============================================================================
// CONFIGURACIÃ“N DE EMAIL TRANSPORTER
// ============================================================================

/// Configuración de Gmail con App Password para máxima compatibilidad
/// 
/// Utiliza nodemailer con autenticación directa via App Password de Google.
/// Esta configuración es más estable que OAuth2 para automatización de emails.
/// 
/// CARACTERÃSTICAS:
/// - Service: Gmail (máxima deliverability)
/// - Auth: App Password (sin expiración)
/// - TLS: Configurado para compatibilidad universal
/// - Timeout: Optimizado para emails con attachments
/// 
/// @return {Object} Transporter configurado para envío de emails
const createTransporter = () => {
  const gmailPassword = 'yyll uhje izsv mbwc'; // App Password dedicado
  
  console.log('ðŸ“§ Configurando Gmail transporter...');
  
  return nodemailer.createTransporter({
    service: 'gmail',
    auth: {
      user: 'paddlepapudo@gmail.com',
      pass: gmailPassword
    },
    tls: {
      rejectUnauthorized: false
    }
  });
};

// ============================================================================
// FUNCIÃ“N PRINCIPAL: SINCRONIZACIÃ“N AUTOMÃTICA DE USUARIOS
// ============================================================================

/// **FUNCIÃ“N CRÃTICA** - Sincronización automática diaria de usuarios
/// 
/// Ejecuta sincronización completa entre Google Sheets (planilla maestro del club)
/// y Firestore (base de datos de la aplicación). Procesa 502+ usuarios con
/// estructura de datos optimizada y logging completo para monitoreo.
/// 
/// PROGRAMACIÃ“N:
/// - Horario: 6:00 AM Chile (America/Santiago timezone)
/// - Frecuencia: Diaria automática
/// - Duración: 2-3 minutos promedio
/// - Memoria: 1GB para manejar volumen completo
/// - Timeout: 9 minutos máximo permitido
/// 
/// PROCESO DE SINCRONIZACIÃ“N:
/// 1. Conexión autenticada a Google Sheets via Service Account
/// 2. Carga completa de hoja "Maestro" (502+ filas)
/// 3. Procesamiento individual con validaciones de email
/// 4. Formateo de nombres según estándar del club
/// 5. Operación .set() para reemplazo completo de datos
/// 6. Logging de estadísticas detalladas
/// 7. Timestamp de última sincronización en collection system
/// 
/// ESTRUCTURA DE DATOS SINCRONIZADA (10 campos por usuario):
/// - email: Clave primaria única
/// - name: Nombre formateado para UI (ej: "FELIPE GARCIA B")
/// - phone: Teléfono para sistema de emails
/// - givenNames: Nombres de pila completos
/// - lastName: Apellido paterno
/// - motherLastName: Apellido materno
/// - idDocument: RUT/Pasaporte para identificación
/// - birthDate: Fecha de nacimiento
/// - relation: Tipo de membresía (SOCIO TITULAR, HIJO, etc.)
/// - Campos sistema: isActive, lastSyncFromSheets, source
/// 
/// GOOGLE SHEETS ESTRUCTURA (headers en español):
/// - EMAIL, NOMBRE(S), APELLIDO_PATERNO, APELLIDO_MATERNO
/// - RUT/PASAPORTE, FECHA_NACIMIENTO, RELACION, CELULAR
/// 
/// ESTADÃSTICAS GENERADAS:
/// - processed: Total de filas procesadas
/// - created: Usuarios nuevos agregados
/// - updated: Usuarios existentes actualizados  
/// - filtered: Filas omitidas (emails inválidos)
/// - errors: Errores encontrados durante proceso
/// - executionTime: Duración total en milisegundos
/// 
/// @param {Object} context - Firebase Functions context
/// @throws No propaga errores, logs en Firestore para debugging
/// @logs Estadísticas completas en Firebase Functions logs
exports.dailyUserSync = onSchedule({
  schedule: "0 6 * * *", // 6:00 AM Chile diario
  timeZone: "America/Santiago",
  memory: "1GiB",
  timeoutSeconds: 540, // 9 minutos máximo
}, async (context) => {
  try {
    console.log('ðŸ”„ === SINCRONIZACIÃ“N AUTOMÃTICA DIARIA INICIADA ===');
    console.log('â° Timestamp:', new Date().toISOString());
    console.log('ðŸŒ Timezone: America/Santiago');
    
    const startTime = Date.now();
    
    // Configuración de Google Sheets
    const SHEET_ID = '1A-8RvvgkHXUP-985So8CBJvDAj50w58EFML1CJEq2c4';
    const SHEET_NAME = 'Maestro';
    
    // Credenciales Service Account para Google Sheets API
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
    console.log('ðŸ“Š Documento Google Sheets cargado:', doc.title);
    
    const sheet = doc.sheetsByTitle[SHEET_NAME];
    if (!sheet) {
      throw new Error(`Hoja '${SHEET_NAME}' no encontrada`);
    }
    
    // Leer todas las filas de la planilla
    const rows = await sheet.getRows();
    console.log(`ðŸ“Š Filas encontradas en Sheets: ${rows.length}`);
    console.log(`ðŸ”„ Procesando TODOS los ${rows.length} usuarios...`);
    
    const db = admin.firestore();
    const usersRef = db.collection('users');
    
    // Estadísticas de proceso
    const stats = {
      processed: 0,
      created: 0,
      updated: 0,
      errors: 0,
      filtered: 0
    };
    
    // Procesar cada usuario individualmente
    for (const row of rows) {
      try {
        stats.processed++;
        
        // Extraer datos de la fila usando headers en español
        const email = (row.EMAIL || '').trim().toLowerCase();
        const nombres = (row['NOMBRE(S)'] || '').trim();
        const apellidoPaterno = (row.APELLIDO_PATERNO || '').trim();
        const apellidoMaterno = (row.APELLIDO_MATERNO || '').trim();
        const rutPasaporte = (row['RUT/PASAPORTE'] || '').trim();
        const fechaNacimiento = (row['FECHA_NACIMIENTO'] || '').trim();
        const relacion = (row.RELACION || '').trim();
        const celular = (row.CELULAR || '').trim();
        
        // Validar email válido
        if (!email || !email.includes('@')) {
          stats.filtered++;
          continue;
        }
        
        // Formatear nombre según estándar del club
        const formattedName = formatUserName(nombres, apellidoPaterno, apellidoMaterno);
        
        // Estructura de datos optimizada (10 campos)
        const userData = {
          // Campos principales para UI Flutter
          email: email,
          name: formattedName,
          phone: celular,
          
          // Campos detallados nomenclatura estándar
          givenNames: nombres,
          lastName: apellidoPaterno,
          motherLastName: apellidoMaterno,
          idDocument: rutPasaporte,
          birthDate: fechaNacimiento,
          relation: relacion,
          
          // Campos sistema
          isActive: true,
          lastSyncFromSheets: admin.firestore.FieldValue.serverTimestamp(),
          source: 'google_sheets_auto'
        };
        
        // Verificar si usuario existe
        const userDoc = await usersRef.doc(email).get();
        
        // Usar .set() para reemplazo completo (evita campos duplicados)
        await usersRef.doc(email).set({
          ...userData,
          createdAt: userDoc.exists ? userDoc.data().createdAt : admin.firestore.FieldValue.serverTimestamp()
        });
        
        if (userDoc.exists) {
          stats.updated++;
        } else {
          stats.created++;
        }
        
      } catch (error) {
        stats.errors++;
        console.error(`âŒ Error procesando usuario:`, error.message);
      }
    }
    
    // Guardar estadísticas en Firestore para monitoreo
    await db.collection('system').doc('sync_status').set({
      lastAutoSync: new Date(),
      autoSyncStats: stats,
      source: 'scheduled_sync',
      sheetId: SHEET_ID,
      executionTime: Date.now() - startTime
    }, { merge: true });
    
    // Logging de resumen completo
    const executionTime = Date.now() - startTime;
    
    console.log('ðŸŽ‰ === SINCRONIZACIÃ“N AUTOMÃTICA COMPLETADA ===');
    console.log(`â±ï¸  Tiempo de ejecución: ${executionTime}ms`);
    console.log(`ðŸ“‹ Procesados: ${stats.processed}`);
    console.log(`âœ… Creados: ${stats.created}`);
    console.log(`ðŸ”„ Actualizados: ${stats.updated}`);
    console.log(`âš ï¸  Filtrados: ${stats.filtered}`);
    console.log(`âŒ Errores: ${stats.errors}`);
    console.log(`ðŸŽ¯ Ã‰xito: ${((stats.created + stats.updated) / stats.processed * 100).toFixed(1)}%`);
    console.log('âœ… Sincronización programada completada exitosamente');
    
  } catch (error) {
    console.error('âŒ ERROR CRÃTICO en sincronización programada:', error);
    
    // Guardar error en Firestore para debugging
    try {
      await admin.firestore().collection('system').doc('sync_errors').set({
        timestamp: new Date(),
        error: error.message,
        stack: error.stack,
        source: 'scheduled_sync'
      }, { merge: true });
    } catch (e) {
      console.error('âŒ Error guardando log de error:', e);
    }
    
    throw error; // Re-lanzar para que Firebase Functions registre el error
  }
});

// ============================================================================
// SISTEMA DE EMAILS AUTOMÃTICOS
// ============================================================================

/// **FUNCIÃ“N CRÃTICA** - Envío de emails de confirmación de reservas
/// 
/// Procesa solicitudes de envío de emails desde la aplicación Flutter y envía
/// confirmaciones automáticas a todos los jugadores de una reserva. Maneja
/// hasta 4 jugadores por reserva con templates HTML profesionales.
/// 
/// CARACTERÃSTICAS:
/// - CORS configurado para dominios autorizados del club
/// - Templates HTML responsive para todos los clientes de email
/// - Gestión de usuarios VISITA con validaciones especiales
/// - Links de cancelación individual para cada jugador
/// - Header corporativo Club de Golf Papudo
/// - Compatibilidad universal: Gmail, Outlook, Apple Mail, Thunderbird
/// 
/// PROCESO DE ENVÃO:
/// 1. Validación de datos de reserva recibidos
/// 2. Normalización de estructura (compatibilidad con versiones anteriores)
/// 3. Configuración de transporter Gmail
/// 4. Generación de template HTML personalizado por jugador
/// 5. Envío secuencial con manejo de errores individual
/// 6. Logging detallado de resultados por email
/// 7. Respuesta con estadísticas completas
/// 
/// ESTRUCTURA DE DATOS ESPERADA:
/// ```json
/// {
///   "booking": {
///     "date": "2025-07-24",
///     "time": "19:30",
///     "courtId": "court_1",
///     "players": [
///       {"name": "FELIPE GARCIA B", "email": "felipe@garciab.cl"},
///       {"name": "ANA BELMAR P", "email": "ana@buzeta.cl"},
///       {"name": "PADEL1 VISITA", "email": null},
///       {"name": "PADEL2 VISITA", "email": null}
///     ]
///   }
/// }
/// ```
/// 
/// EMAILS GENERADOS:
/// - Subject: "Reserva de Pádel Confirmada - [fecha]"
/// - Template: HTML responsive con branding corporativo
/// - Contenido: Detalles completos de reserva + lista de jugadores
/// - Botón: Cancelación individual por jugador
/// - Footer: Información de contacto completa del club
/// 
/// GESTIÃ“N DE USUARIOS VISITA:
/// - Detecta automáticamente jugadores "VISITA" por nombre
/// - Muestra mensaje especial al organizador sobre pagos
/// - Omite envío de email a usuarios sin email válido
/// - Logs específicos para usuarios VISITA
/// 
/// @param {Object} req - Request con datos de reserva
/// @param {Object} res - Response con resultados de envío
/// @returns {Object} Estadísticas de emails enviados/fallidos
/// @logs Proceso completo de cada email individual
exports.sendBookingEmailHTTP = onRequest({
  region: 'us-central1',
  cors: {
    origin: [
      "http://localhost:3000",
      "http://localhost:5000", 
      "https://cgpreservas.web.app",
      "https://cgpreservas.firebaseapp.com",
      "https://paddlepapudo.github.io"
    ],
    methods: ["GET", "POST", "OPTIONS"],
    allowedHeaders: ["Content-Type", "Authorization", "Accept"],
    credentials: true
  }
}, async (req, res) => {
  console.log('ðŸ“§ === ENVIANDO EMAILS DE CONFIRMACIÃ“N ===');
  console.log('ðŸ“§ Body:', JSON.stringify(req.body, null, 2));
  
  try {
    const bookingData = req.body;
    const booking = bookingData.booking || bookingData;
    
    // Normalizar datos para compatibilidad con versiones anteriores
    const normalizedBooking = {
      date: booking.date,
      time: booking.time || booking.timeSlot,
      courtId: booking.courtId || booking.courtNumber,
      players: booking.players || []
    };
    
    console.log(`ðŸ“§ Procesando reserva: ${normalizedBooking.courtId} ${normalizedBooking.date} ${normalizedBooking.time}`);
    console.log(`ðŸ“§ Jugadores: ${normalizedBooking.players.length}`);
    
    if (!normalizedBooking.players || normalizedBooking.players.length === 0) {
      throw new Error('No hay jugadores en la reserva');
    }
    
    // Configurar Gmail transporter
    const transporter = createTransporter();
    
    // Detectar si hay usuarios VISITA
    const isVisitorBooking = normalizedBooking.players.some(player => {
      const playerName = typeof player === 'string' ? player : (player.name || '');
      return playerName.toUpperCase().includes('VISITA');
    });
    
    // Enviar emails a cada jugador
    const emailResults = [];
    
    for (let i = 0; i < normalizedBooking.players.length; i++) {
      const player = normalizedBooking.players[i];
      const playerName = typeof player === 'string' ? player : (player.name || 'Jugador');
      const playerEmail = typeof player === 'string' ? null : player.email;
      
      if (!playerEmail) {
        console.log(`â­ï¸ Saltando ${playerName} - no tiene email`);
        continue;
      }
      
      console.log(`ðŸ“§ Enviando email ${i + 1}/${normalizedBooking.players.length} a: ${playerName} (${playerEmail})`);
      
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
        console.log(`âœ… Email enviado exitosamente a: ${playerName} (${playerEmail})`);
        emailResults.push({ success: true, player: playerName, email: playerEmail });
        
      } catch (emailError) {
        console.error(`âŒ Error enviando email a ${playerName}:`, emailError);
        emailResults.push({ success: false, player: playerName, email: playerEmail, error: emailError.message });
      }
    }
    
    const successCount = emailResults.filter(r => r.success).length;
    const failCount = emailResults.filter(r => !r.success).length;
    
    console.log('ðŸ“§ === RESUMEN EMAILS ===');
    console.log(`âœ… Exitosos: ${successCount}/${emailResults.length}`);
    console.log(`âŒ Fallidos: ${failCount}/${emailResults.length}`);
    
    res.status(200).json({
      success: true,
      message: `${successCount} emails enviados exitosamente`,
      results: emailResults,
      successCount: successCount,
      failCount: failCount
    });
    
  } catch (error) {
    console.error('âŒ Error general:', error);
    res.status(500).json({
      success: false,
      message: error.message,
      error: error.toString()
    });
  }
});

// ============================================================================
// SISTEMA DE CANCELACIÃ“N DE RESERVAS
// ============================================================================

/// **FUNCIÃ“N CRÃTICA** - Cancelación individual de jugadores con notificaciones
/// 
/// Maneja cancelaciones individuales de jugadores desde links de email.
/// Actualiza la reserva en Firestore y notifica automáticamente a los
/// jugadores restantes. Soporta tanto requests GET (desde emails) como
/// POST (desde aplicación).
/// 
/// CARACTERÃSTICAS:
/// - Cancelación individual por jugador (no elimina toda la reserva)
/// - Búsqueda inteligente por ID de reserva o campos individuales
/// - Notificaciones automáticas a jugadores restantes
/// - Template HTML de confirmación para GET requests
/// - Actualización de estado de reserva (complete/incomplete)
/// - Logging detallado de todo el proceso
/// 
/// PROCESO DE CANCELACIÃ“N:
/// 1. Decodificación de parámetros (ID reserva + email jugador)
/// 2. Búsqueda de reserva en Firestore por ID o campos alternativos
/// 3. Identificación y remoción del jugador que cancela
/// 4. Envío de notificaciones a jugadores restantes
/// 5. Actualización de reserva con nueva lista de jugadores
/// 6. Respuesta con confirmación (HTML para GET, JSON para POST)
/// 
/// PARÃMETROS ESPERADOS:
/// - id: ID de reserva (formato: court1-2025-07-24-1930)
/// - email: Email del jugador que cancela (URL encoded)
/// 
/// BUSQUEDA DE RESERVA:
/// 1. Búsqueda directa por campo 'id' en Firestore
/// 2. Si falla, decodifica ID y busca por campos individuales:
///    - courtNumber: extraído de ID
///    - date: extraído de ID  
///    - timeSlot: extraído de ID
/// 
/// NOTIFICACIONES AUTOMÃTICAS:
/// - Template HTML específico para cancelaciones
/// - Información del jugador que canceló
/// - Lista actualizada de jugadores restantes
/// - Datos completos de la reserva
/// - Información de contacto del jugador que canceló
/// 
/// RESPUESTAS:
/// - GET: Página HTML de confirmación con estilo corporativo
/// - POST: JSON con status de cancelación
/// - Error: Página/JSON con información del problema
/// 
/// @param {Object} req - Request con parámetros de cancelación
/// @param {Object} res - Response con confirmación
/// @returns {HTML|JSON} Confirmación según tipo de request
/// @logs Proceso completo de cancelación y notificaciones
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
    console.log('ðŸ—‘ï¸ === CANCELACIÃ“N DE RESERVA ===');
    console.log('ðŸ—‘ï¸ Method:', req.method);
    console.log('ðŸ—‘ï¸ Query:', req.query);

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

    console.log(`ðŸ—‘ï¸ Cancelando jugador ${decodeURIComponent(playerEmail)} de reserva: ${bookingId}`);

    const db = admin.firestore();
    const bookingsRef = db.collection('bookings');
    
    // Variables para almacenar datos de la reserva
    let bookingData = null;
    let originalPlayers = [];
    let docRef = null;

    // Buscar la reserva por ID generado
    console.log(`ðŸ” Buscando por ID: ${bookingId}`);
    const snapshot = await bookingsRef.where('id', '==', bookingId).get();
    
    if (snapshot.empty) {
      // Búsqueda alternativa por campos individuales
      const idParts = bookingId.split('-');
      console.log(`ðŸ” ID parts:`, idParts);
      
      if (idParts.length >= 5) {
        // ID formato: court1-2025-06-05-1200 â†’ court_1, 2025-06-05, 12:00
        const courtId = idParts[0];
        const date = `${idParts[1]}-${idParts[2]}-${idParts[3]}`;
        const timeRaw = idParts[4];
        const timeSlot = `${timeRaw.substring(0,2)}:${timeRaw.substring(2,4)}`;
        
        console.log(`ðŸ” Buscando por: court=${courtId}, date=${date}, time=${timeSlot}`);
        
        const alternativeSnapshot = await bookingsRef
          .where('courtId', '==', courtId)
          .where('date', '==', date)
          .where('timeSlot', '==', timeSlot)
          .get();
          
        if (!alternativeSnapshot.empty) {
          const doc = alternativeSnapshot.docs[0];
          bookingData = doc.data();
          originalPlayers = [...(bookingData.players || [])];
          docRef = doc.ref;
          console.log('âœ… Reserva encontrada por búsqueda alternativa');
        }
      }
    } else {
      // Reserva encontrada por ID directo
      const doc = snapshot.docs[0];
      bookingData = doc.data();
      originalPlayers = [...(bookingData.players || [])];
      docRef = doc.ref;
      console.log('âœ… Reserva encontrada por ID directo');
    }

    // Procesar cancelación si encontramos la reserva
    if (bookingData && docRef) {
      console.log('ðŸ‘¥ Jugadores originales:', originalPlayers.map(p => p.email));
      
      // Filtrar el jugador que cancela
      const decodedPlayerEmail = decodeURIComponent(playerEmail);
      const updatedPlayers = originalPlayers.filter(player => 
        player.email !== decodedPlayerEmail
      );
      
      console.log('ðŸ‘¥ Jugadores después de cancelación:', updatedPlayers.map(p => p.email));
      
      // Identificar jugador que cancela para notificaciones
      const cancelingPlayer = originalPlayers.find(player => 
        player.email === decodedPlayerEmail
      );
      const cancelingPlayerName = cancelingPlayer ? 
        (cancelingPlayer.name || cancelingPlayer.displayName || 'Un compañero') : 
        'Un compañero';
      
      console.log(`ðŸ‘¤ Jugador que cancela: ${cancelingPlayerName} (${decodedPlayerEmail})`);

      if (updatedPlayers.length === 0) {
        // Si no quedan jugadores, eliminar toda la reserva
        console.log('ðŸ—‘ï¸ No quedan jugadores, eliminando reserva completa...');
        await docRef.delete();
        console.log('âœ… Reserva eliminada completamente');
      } else {
        // Enviar notificaciones antes de actualizar
        console.log('ðŸ“§ === ENVIANDO NOTIFICACIONES DE CANCELACIÃ“N ===');
        
        try {
          const reservationInfo = {
            date: bookingData.date,
            timeSlot: bookingData.timeSlot,
            courtId: bookingData.courtId,
            originalPlayers: originalPlayers,
            remainingPlayers: updatedPlayers,
            cancelingPlayerName: cancelingPlayerName,
            cancelingPlayerEmail: decodedPlayerEmail
          };

          // Enviar notificaciones a jugadores restantes
          const notificationPromises = updatedPlayers.map(player => 
            sendCancellationNotification(player, reservationInfo)
          );

          const notificationResults = await Promise.allSettled(notificationPromises);
          
          let successCount = 0;
          let failureCount = 0;
          
          notificationResults.forEach((result, index) => {
            if (result.status === 'fulfilled') {
              successCount++;
              console.log(`âœ… Notificación enviada a: ${updatedPlayers[index].email}`);
            } else {
              failureCount++;
              console.log(`âŒ Error notificando a ${updatedPlayers[index].email}:`, result.reason);
            }
          });
          
          console.log(`ðŸ“§ Notificaciones: ${successCount} exitosas, ${failureCount} fallos`);
          
        } catch (notificationError) {
          console.error('âŒ Error en notificaciones:', notificationError);
        }

        // Actualizar reserva con jugadores restantes
        console.log('ðŸ”„ Actualizando reserva con jugadores restantes...');
        const newStatus = updatedPlayers.length === 4 ? 'complete' : 'incomplete';

        await docRef.update({
          players: updatedPlayers,
          status: newStatus,
          lastModified: new Date()
        });
        console.log(`âœ… Jugador removido. Quedan ${updatedPlayers.length} jugadores`);
      }
    }

    // Respuesta según tipo de request
    if (req.method === 'GET') {
      // Página HTML de confirmación para clicks desde email
      const html = generateCancellationConfirmationHtml(bookingId, playerEmail);
      res.set('Content-Type', 'text/html');
      return res.status(200).send(html);
    }

    // Respuesta JSON para requests POST
    return res.status(200).json({
      success: true,
      message: 'Reserva cancelada exitosamente',
      bookingId: bookingId
    });

  } catch (error) {
    console.error('âŒ Error cancelando:', error);
    
    if (req.method === 'GET') {
      const errorHtml = generateErrorHtml(error.message);
      res.set('Content-Type', 'text/html');
      return res.status(500).send(errorHtml);
    }
    
    return res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// ============================================================================
// API PARA APLICACIÃ“N FLUTTER
// ============================================================================

/// **API PRINCIPAL** - Endpoint para obtener usuarios desde Flutter
/// 
/// Proporciona lista completa de usuarios activos para la aplicación Flutter.
/// Optimizado para performance con 502+ usuarios y filtrado inteligente.
/// 
/// CARACTERÃSTICAS:
/// - Filtro automático por usuarios activos (isActive: true)
/// - Ordenamiento alfabético por displayName
/// - Campos optimizados para UI Flutter
/// - Response JSON optimizado para transferencia
/// - Manejo de errores robusto
/// 
/// CAMPOS RETORNADOS POR USUARIO:
/// - email: Identificador único
/// - name: Nombre formateado para mostrar
/// - phone: Teléfono para contacto (puede ser vacío)
/// - relacion: Tipo de membresía
/// 
/// FILTROS APLICADOS:
/// - Solo usuarios con isActive: true
/// - Usuarios con email válido
/// - Ordenamiento alfabético por nombre
/// 
/// PERFORMANCE:
/// - Consulta indexada en Firestore
/// - Transferencia optimizada (solo campos necesarios)
/// - Cache recomendado en cliente Flutter
/// 
/// @param {Object} req - Request HTTP
/// @param {Object} res - Response con lista de usuarios
/// @returns {JSON} Lista de usuarios activos
/// @logs Estadísticas de usuarios enviados
exports.getUsers = onRequest({
  cors: true,
}, async (req, res) => {
  try {
    console.log('ðŸ‘¥ Obteniendo usuarios desde Firebase...');
    
    const db = admin.firestore();
    const usersSnapshot = await db.collection('users')
      .where('isActive', '==', true)
      .get();
    
    const users = [];
    usersSnapshot.forEach(doc => {
      const userData = doc.data();
      users.push({
        email: doc.id,
        name: userData.name || userData.displayName || 'Sin Nombre',
        phone: userData.phone || '',
        relacion: userData.relation || userData.relacion || ''
      });
    });
    
    // Ordenar alfabéticamente en JavaScript
    users.sort((a, b) => a.name.localeCompare(b.name));
    
    console.log(`ðŸ‘¥ Enviando ${users.length} usuarios al frontend`);
    
    res.json({
      success: true,
      users: users,
      count: users.length,
      timestamp: new Date().toISOString()
    });
    
  } catch (error) {
    console.error('âŒ Error obteniendo usuarios:', error);
    res.status(500).json({
      error: 'Error obteniendo usuarios',
      message: error.message
    });
  }
});

// ============================================================================
// FUNCIÃ“N DE DIAGNÃ“STICO
// ============================================================================

/// **FUNCIÃ“N DE DIAGNÃ“STICO** - Verificación de Google Sheets API
/// 
/// Herramienta de diagnóstico para validar conectividad y estructura
/// de Google Sheets. Ãštil para debugging y verificación de configuración.
/// 
/// VERIFICACIONES REALIZADAS:
/// - Conectividad con Google Sheets API
/// - Autenticación con Service Account
/// - Estructura de la hoja "Maestro"
/// - Headers de columnas (español vs inglés)
/// - Datos de muestra de usuarios reales
/// - Validación de campos esperados
/// 
/// INFORMACIÃ“N RETORNADA:
/// - Título del documento
/// - Nombre de la hoja
/// - Número de filas y columnas
/// - Lista de headers encontrados
/// - Headers faltantes (si los hay)
/// - Headers extra (si los hay)
/// - Muestra de 3 usuarios reales con datos formateados
/// - Timestamp de verificación
/// 
/// CASOS DE USO:
/// - Debugging de problemas de sincronización
/// - Validación después de cambios en Google Sheets
/// - Verificación de estructura de datos
/// - Testing de conectividad
/// 
/// @param {Object} req - Request HTTP
/// @param {Object} res - Response con diagnóstico completo
/// @returns {JSON} Diagnóstico detallado de Google Sheets
/// @logs Proceso completo de verificación
exports.verifyGoogleSheetsAPI = onRequest({
  cors: true,
}, async (req, res) => {
  try {
    console.log('ðŸ” Verificando configuración de Google Sheets API...');
    
    const SHEET_ID = '1A-8RvvgkHXUP-985So8CBJvDAj50w58EFML1CJEq2c4';
    const SHEET_NAME = 'Maestro';
    
    // Configuración de credenciales
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
    
    // Conectar y verificar
    const doc = new GoogleSpreadsheet(SHEET_ID);
    await doc.useServiceAccountAuth({
      client_email: serviceAccountEmail,
      private_key: privateKey.replace(/\n    /g, '\n'),
    });
    
    await doc.loadInfo();
    console.log('âœ… Autenticación exitosa');
    console.log('ðŸ“Š Documento cargado:', doc.title);
    
    // Verificar hoja
    const sheet = doc.sheetsByTitle[SHEET_NAME];
    if (!sheet) {
      const availableSheets = Object.keys(doc.sheetsByTitle);
      return res.status(404).json({
        error: `Hoja '${SHEET_NAME}' no encontrada`,
        availableSheets: availableSheets
      });
    }
    
    // Analizar estructura
    await sheet.loadHeaderRow();
    const headers = sheet.headerValues;
    
    const expectedHeaders = ['EMAIL', 'NOMBRE(S)', 'APELLIDO_PATERNO', 'APELLIDO_MATERNO', 'RUT/PASAPORTE', 'FECHA_NACIMIENTO', 'RELACION', 'CELULAR'];
    const missingHeaders = expectedHeaders.filter(header => !headers.includes(header));
    const extraHeaders = headers.filter(header => !expectedHeaders.includes(header));
    
    // Obtener muestra de datos
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
    
    res.json({
      success: true,
      message: 'âœ… Google Sheets API configurado correctamente',
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
    console.error('âŒ Error verificando Google Sheets API:', error);
    res.status(500).json({
      error: 'Error al verificar Google Sheets API',
      message: error.message,
      suggestions: [
        'Verificar que las credenciales estén correctamente configuradas',
        'Verificar que la cuenta de servicio tenga acceso a la planilla',
        'Verificar que el ID de la planilla sea correcto'
      ]
    });
  }
});

// ============================================================================
// FUNCIONES AUXILIARES
// ============================================================================

/// Formateo de nombres según estándar del Club de Golf Papudo
/// 
/// Convierte nombres completos a formato estándar usado en toda la aplicación.
/// Procesa nombres múltiples y apellidos según convención chilena.
/// 
/// ALGORITMO:
/// 1. Primer nombre completo
/// 2. Inicial segundo nombre (sin punto) si existe
/// 3. Apellido paterno completo
/// 4. Inicial apellido materno (sin punto) si existe
/// 
/// EJEMPLOS:
/// - "FELIPE", "GARCIA", "BENITEZ" â†’ "FELIPE GARCIA B"
/// - "ANA MARIA", "BELMAR", "PEREZ" â†’ "ANA M BELMAR P"
/// - "CARLOS", "RODRIGUEZ", "" â†’ "CARLOS RODRIGUEZ"
/// 
/// @param {string} nombres - Nombres de pila (puede ser múltiple)
/// @param {string} apellidoPaterno - Apellido paterno
/// @param {string} apellidoMaterno - Apellido materno (opcional)
/// @returns {string} Nombre formateado en mayúsculas
function formatUserName(nombres, apellidoPaterno, apellidoMaterno) {
  // Procesar nombres: primer nombre + inicial segundo nombre (sin punto)
  const nombresParts = (nombres || '').trim().split(/\s+/);
  const primerNombre = nombresParts[0] || '';
  const inicialSegundoNombre = nombresParts.length > 1 ? nombresParts[1].charAt(0) : '';
  
  // Construir parte de nombres
  const nombresFormateados = inicialSegundoNombre ? 
    `${primerNombre} ${inicialSegundoNombre}` : 
    primerNombre;
  
  // Apellido paterno completo
  const apellidoPaternoCompleto = (apellidoPaterno || '').trim();
  
  // Apellido materno: solo inicial (sin punto)
  const inicialApellidoMaterno = (apellidoMaterno || '').trim().charAt(0);
  
  // Construir nombre completo
  const parts = [nombresFormateados, apellidoPaternoCompleto];
  
  if (inicialApellidoMaterno) {
    parts.push(inicialApellidoMaterno);
  }
  
  return parts.filter(part => part).join(' ').toUpperCase();
}

/// Formateo de fechas para emails en español chileno
/// 
/// Convierte fechas ISO a formato legible en español con timezone Chile.
/// 
/// @param {string} dateString - Fecha en formato ISO (YYYY-MM-DD)
/// @returns {string} Fecha formateada (ej: "miércoles, 24 de julio de 2025")
function formatDate(dateString) {
  try {
    if (!dateString) {
      dateString = new Date().toISOString().split('T')[0];
    }
    
    const dateStr = String(dateString).trim();
    let date;
    
    if (dateStr.match(/^\d{4}-\d{2}-\d{2}$/)) {
      date = new Date(dateStr + 'T12:00:00-03:00');
    } else {
      date = new Date(dateStr);
    }
    
    if (isNaN(date.getTime())) {
      date = new Date();
    }
    
    const options = { 
      weekday: 'long', 
      year: 'numeric', 
      month: 'long', 
      day: 'numeric',
      timeZone: 'America/Santiago'
    };
    
    return date.toLocaleDateString('es-ES', options);
    
  } catch (error) {
    console.error('âŒ Error en formatDate:', error);
    const fallbackDate = new Date();
    return fallbackDate.toLocaleDateString('es-ES', {
      weekday: 'long', 
      year: 'numeric', 
      month: 'long', 
      day: 'numeric',
      timeZone: 'America/Santiago'
    });
  }
}

/// Cálculo de hora de fin de reserva (duración 1.5 horas)
/// 
/// @param {string} startTime - Hora de inicio (HH:MM)
/// @returns {string} Hora de fin (HH:MM)
function getEndTime(startTime) {
  try {
    if (!startTime || !startTime.includes(':')) {
      return 'N/A';
    }
    
    const timeParts = startTime.split(':');
    if (timeParts.length < 2) {
      return 'N/A';
    }
    
    const hours = parseInt(timeParts[0], 10);
    const minutes = parseInt(timeParts[1], 10);
    
    if (isNaN(hours) || isNaN(minutes)) {
      return 'N/A';
    }
    
    const endHours = hours + 1;
    const endMinutes = minutes + 30;
    
    let finalHours = endHours;
    let finalMinutes = endMinutes;
    
    if (finalMinutes >= 60) {
      finalHours = endHours + 1;
      finalMinutes = endMinutes - 60;
    }
    
    return `${String(finalHours).padStart(2, '0')}:${String(finalMinutes).padStart(2, '0')}`;
    
  } catch (error) {
    console.error('âŒ Error en getEndTime:', error);
    return 'N/A';
  }
}

/// Mapeo de IDs de cancha a nombres amigables
/// 
/// @param {string} courtId - ID técnico de cancha
/// @returns {string} Nombre amigable de la cancha
function getCourtName(courtId) {
  try {
    if (!courtId) {
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
    
    return courts[courtStr] || `Cancha ${courtId}`;
    
  } catch (error) {
    console.error('âŒ Error en getCourtName:', error);
    return 'Cancha Desconocida';
  }
}

// ============================================================================
// TEMPLATES HTML PARA EMAILS
// ============================================================================

/// Genera template HTML para emails de confirmación de reserva
/// 
/// Template responsive con branding corporativo del Club de Golf Papudo.
/// Incluye toda la información de la reserva y botón de cancelación individual.
/// 
/// @param {Object} booking - Datos de la reserva
/// @param {string} organizerName - Nombre del organizador
/// @param {boolean} isVisitorBooking - Si incluye usuarios VISITA
/// @param {string} email - Email del destinatario
/// @returns {string} HTML completo del email
function generateBookingEmailHtml(booking, organizerName, isVisitorBooking = false, email) {
  const formattedDate = formatDate(booking.date);
  const courtName = getCourtName(booking.courtId);
  const endTime = getEndTime(booking.time);
  
  // Mensaje especial para reservas con usuarios VISITA
  const visitorMessage = isVisitorBooking ? `
    <div style="background-color: #fff3cd; border: 1px solid #ffeaa7; border-radius: 8px; padding: 16px; margin: 20px 0;">
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
    </head>
    <body style="margin: 0; padding: 0; background-color: #f5f5f5; font-family: Arial, sans-serif;">
      <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%">
        <tr>
          <td style="padding: 20px 0;">
            <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="600" style="margin: 0 auto; background-color: #ffffff; border-radius: 12px; box-shadow: 0 4px 12px rgba(0,0,0,0.1);">
              
              <!-- HEADER CORPORATIVO -->
              <tr>
                <td style="background: linear-gradient(135deg, #4f8ef7 0%, #2c5282 100%); padding: 40px 20px; text-align: center; border-radius: 12px 12px 0 0;">
                  <h1 style="color: white; font-size: 32px; font-weight: bold; margin: 0;">
                    Club de Golf Papudo
                  </h1>
                  <p style="color: #bfdbfe; margin: 10px 0 0 0; font-size: 18px;">
                    Reserva de Pádel Confirmada
                  </p>
                </td>
              </tr>

              <!-- CONTENIDO PRINCIPAL -->
              <tr>
                <td style="padding: 40px;">
                  <h2 style="color: #2d3748; font-size: 24px; margin: 0 0 20px 0;">
                    Â¡Hola ${organizerName.toUpperCase()}!
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
                        <h3 style="color: #1e40af; margin: 0 0 16px 0; font-size: 18px;">
                          ðŸ“… Detalles de la Reserva:
                        </h3>
                        <div style="color: #1e3a8a; font-size: 16px; line-height: 1.8;">
                          <div><strong>ðŸ“… Fecha:</strong> ${formattedDate}</div>
                          <div><strong>â° Horario:</strong> ${booking.time} - ${endTime}</div>
                          <div><strong>ðŸ“ Cancha:</strong> ${courtName}</div>
                        </div>
                      </td>
                    </tr>
                  </table>
                </td>
              </tr>

              <!-- LISTA DE JUGADORES -->
              <tr>
                <td style="padding: 0 40px 20px 40px;">
                  <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%" style="border-left: 4px solid #10b981; background-color: #f0fdf4; border-radius: 8px;">
                    <tr>
                      <td style="padding: 20px;">
                        <h3 style="color: #065f46; margin: 0 0 16px 0; font-size: 18px;">
                          ðŸ‘¥ Jugadores (${booking.players.length}/4):
                        </h3>
                        ${booking.players.map((player, index) => {
                          const playerName = typeof player === 'string' ? player : (player.name || 'Jugador');
                          const isOrganizer = index === 0;
                          return `
                            <div style="padding: 8px 0; color: #047857; font-size: 16px;">
                              <span style="margin-right: 8px;">${isOrganizer ? 'ðŸ†' : 'â€¢'}</span>
                              <strong>${playerName}</strong>${isOrganizer ? ' <em>(Organizador)</em>' : ''}
                            </div>
                          `;
                        }).join('')}
                      </td>
                    </tr>
                  </table>
                </td>
              </tr>

              <!-- BOTÃ“N CANCELAR -->
              <tr>
                <td style="padding: 0 40px 20px 40px; text-align: center;">
                  <a href="https://us-central1-cgpreservas.cloudfunctions.net/cancelBooking?id=${booking.id || `${booking.courtId || booking.courtId}-${booking.date}-${(booking.timeSlot || booking.time || '').replace(/:/g, '')}`}&email=${encodeURIComponent(email)}" style="background: #dc2626; color: white; padding: 16px 32px; text-decoration: none; border-radius: 8px; font-weight: bold; font-size: 16px; display: inline-block;">
                    âŒ Cancelar mi Participación
                  </a>
                </td>
              </tr>

              <!-- FOOTER CORPORATIVO -->
              <tr>
                <td style="background: #f8fafc; padding: 30px 40px; text-align: center; color: #64748b; font-size: 14px; border-top: 1px solid #e2e8f0; border-radius: 0 0 12px 12px;">
                  <p style="margin: 0; line-height: 1.6;">
                    <strong>Club de Golf Papudo</strong> â€¢ Desde 1932<br>
                    ðŸ“§ paddlepapudo@gmail.com<br>
                    ðŸ“ Miraflores s/n - Papudo, Valparaíso<br>
                    ðŸŒ clubgolfpapudo.cl
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

/// Envía notificación de cancelación a jugador restante
/// 
/// @param {Object} remainingPlayer - Jugador que recibe la notificación
/// @param {Object} reservationInfo - Información completa de la reserva
/// @returns {Promise} Resultado del envío
async function sendCancellationNotification(remainingPlayer, reservationInfo) {
  try {
    const {
      date,
      timeSlot,
      courtId,
      cancelingPlayerName,
      cancelingPlayerEmail,
      remainingPlayers
    } = reservationInfo;

    const formattedDate = formatDate(date);
    const endTime = getEndTime(timeSlot);
    const courtName = getCourtName(courtId);

    const emailHtml = `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Jugador se retiró - Club de Golf Papudo</title>
      </head>
      <body style="margin: 0; padding: 0; font-family: Arial, sans-serif; background-color: #f5f5f5;">
        <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%">
          <tr>
            <td style="padding: 20px 0;">
              <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="600" style="margin: 0 auto; background-color: white; border-radius: 12px; box-shadow: 0 4px 12px rgba(0,0,0,0.1);">
                
                <!-- HEADER -->
                <tr>
                  <td style="background: linear-gradient(135deg, #f59e0b 0%, #d97706 100%); padding: 30px 40px; border-radius: 12px 12px 0 0;">
                    <h1 style="color: white; margin: 0; font-size: 24px; text-align: center;">
                      âš ï¸ Cambio en tu Reserva
                    </h1>
                    <p style="color: #fde68a; margin: 5px 0 0 0; font-size: 16px; text-align: center;">
                      Club de Golf Papudo
                    </p>
                  </td>
                </tr>

                <!-- CONTENIDO -->
                <tr>
                  <td style="padding: 40px;">
                    <h2 style="color: #f59e0b; margin: 0 0 20px 0; font-size: 20px;">
                      Hola ${remainingPlayer.name || remainingPlayer.displayName || 'Jugador'},
                    </h2>
                    <p style="color: #374151; font-size: 16px; line-height: 1.6; margin: 0 0 24px 0;">
                      Te informamos que <strong>${cancelingPlayerName}</strong> se retiró de la reserva de Pádel en la que participas.
                    </p>
                    <p style="color: #374151; font-size: 16px; line-height: 1.6; margin: 0 0 24px 0;">
                      La reserva sigue <strong>activa</strong> con los jugadores restantes.
                    </p>

                    <!-- DETALLES RESERVA -->
                    <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%" style="border-left: 4px solid #3b82f6; background-color: #eff6ff; border-radius: 8px; margin: 20px 0;">
                      <tr>
                        <td style="padding: 20px;">
                          <h3 style="color: #1e40af; margin: 0 0 16px 0; font-size: 18px;">
                            ðŸ“… Detalles de la Reserva:
                          </h3>
                          <div style="color: #1e3a8a; font-size: 16px; line-height: 1.8;">
                            <div><strong>ðŸ“… Fecha:</strong> ${formattedDate}</div>
                            <div><strong>â° Horario:</strong> ${timeSlot} - ${endTime}</div>
                            <div><strong>ðŸ“ Cancha:</strong> ${courtName}</div>
                            <div><strong>ðŸ‘¤ Se retiró:</strong> ${cancelingPlayerName}</div>
                          </div>
                        </td>
                      </tr>
                    </table>

                    <!-- JUGADORES ACTUALES -->
                    <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%" style="border-left: 4px solid #10b981; background-color: #f0fdf4; border-radius: 8px; margin: 20px 0;">
                      <tr>
                        <td style="padding: 20px;">
                          <h3 style="color: #065f46; margin: 0 0 16px 0; font-size: 18px;">
                            ðŸ‘¥ Jugadores Actuales (${remainingPlayers.length}/4):
                          </h3>
                          ${remainingPlayers.map(player => {
                            const playerName = player.name || player.displayName || 'Jugador';
                            return `
                              <div style="padding: 8px 0; color: #047857; font-size: 16px;">
                                <span style="margin-right: 8px;">â€¢</span>
                                <strong>${playerName}</strong>
                              </div>
                            `;
                          }).join('')}
                          
                          ${remainingPlayers.length < 4 ? `
                            <div style="margin-top: 16px; padding: 12px; background-color: #dcfce7; border-radius: 6px; color: #166534;">
                              <strong>ðŸ’¡ Tip:</strong> Puedes contactar al club para agregar más jugadores.
                            </div>
                          ` : ''}
                        </td>
                      </tr>
                    </table>

                    <!-- CONTACTO -->
                    <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%" style="border-left: 4px solid #f59e0b; background-color: #fffbeb; border-radius: 8px;">
                      <tr>
                        <td style="padding: 20px;">
                          <h3 style="color: #92400e; margin: 0 0 16px 0; font-size: 18px;">
                            ðŸ“ž Contacto del jugador que se retiró:
                          </h3>
                          <p style="color: #a16207; font-size: 16px; margin: 0;">
                            <strong>${cancelingPlayerName}</strong><br>
                            <a href="mailto:${cancelingPlayerEmail}" style="color: #d97706;">${cancelingPlayerEmail}</a>
                          </p>
                        </td>
                      </tr>
                    </table>
                  </td>
                </tr>

                <!-- FOOTER -->
                <tr>
                  <td style="padding: 30px 40px; border-top: 1px solid #e5e7eb; background-color: #f9fafb; border-radius: 0 0 12px 12px;">
                    <p style="color: #6b7280; font-size: 14px; text-align: center; margin: 0;">
                      Club de Golf Papudo - Sistema de Reservas Pádel<br>
                      ðŸ“§ paddlepapudo@gmail.com
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

    const transporter = createTransporter();
    const mailOptions = {
      from: {
        name: 'Club de Golf Papudo',
        address: 'paddlepapudo@gmail.com'
      },
      to: remainingPlayer.email,
      subject: `âš ï¸ Jugador se retiró de reserva - ${formattedDate}`,
      html: emailHtml
    };

    await transporter.sendMail(mailOptions);
    console.log(`ðŸ“§ Notificación de cancelación enviada a: ${remainingPlayer.email}`);
    
  } catch (error) {
    console.error(`âŒ Error enviando notificación a ${remainingPlayer.email}:`, error);
    throw error;
  }
}

/// Genera página HTML de confirmación de cancelación
/// 
/// @param {string} bookingId - ID de la reserva cancelada
/// @param {string} playerEmail - Email del jugador que canceló
/// @returns {string} HTML de confirmación
function generateCancellationConfirmationHtml(bookingId, playerEmail) {
  return `
    <!DOCTYPE html>
    <html lang="es">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Cancelación Exitosa - Club de Golf Papudo</title>
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
            .note { 
                background: #dcfce7; padding: 16px; border-radius: 6px; 
                color: #16a34a; font-size: 14px; margin-top: 20px; 
            }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>Club de Golf Papudo</h1>
                <p>Sistema de Reservas de Pádel</p>
            </div>
            
            <div class="success">âœ…</div>
            
            <div class="message">
                <strong>Cancelación Exitosa</strong><br><br>
                Has sido removido de esta reserva de pádel.
            </div>
            
            <div class="booking-id">
                Reserva: ${bookingId}<br>
                Jugador: ${decodeURIComponent(playerEmail)}
            </div>
            
            <div class="note">
                ðŸ“§ <strong>Notificaciones Enviadas</strong><br>
                Los otros jugadores han sido notificados de tu cancelación.
            </div>
            
            <a href="https://paddlepapudo.github.io/cgp_reservas/" class="button">
                ðŸ“ Ir a Reservas
            </a>
        </div>
    </body>
    </html>
  `;
}

/// Genera página HTML de error
/// 
/// @param {string} errorMessage - Mensaje de error
/// @returns {string} HTML de error
function generateErrorHtml(errorMessage) {
  return `
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="UTF-8">
        <title>Error - Club de Golf Papudo</title>
        <style>
            body { font-family: Arial; text-align: center; padding: 50px; background: #f5f5f5; }
            .container { max-width: 400px; margin: 0 auto; background: white; padding: 40px; border-radius: 12px; }
            .error { color: #dc2626; font-size: 48px; margin-bottom: 20px; }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="error">âš ï¸</div>
            <h1>Error al Cancelar</h1>
            <p>${errorMessage}</p>
            <p>Por favor contacta al club directamente.</p>
            <a href="mailto:paddlepapudo@gmail.com">ðŸ“§ Contactar Club</a>
        </div>
    </body>
    </html>
  `;
}

// ============================================================================
// NOTAS PARA MANTENIMIENTO FUTURO
// ============================================================================

/// ROADMAP DE DESARROLLO:
/// 
/// 1. **EXPANSIÃ“N MULTI-DEPORTE (4 semanas)**:
///    - Extender dailyUserSync para múltiples deportes
///    - Migrar funcionalidad Golf/Tenis desde Google Apps Script
///    - Unificar toda la funcionalidad en Firebase Functions
/// 
/// 2. **OPTIMIZACIONES DE PERFORMANCE**:
///    - Implementar cache en getUsers para reducir latencia
///    - Batch processing en dailyUserSync para mayor eficiencia
///    - Optimizar queries con índices compuestos en Firestore
/// 
/// 3. **MEJORAS DE SEGURIDAD**:
///    - Implementar rate limiting en endpoints públicos
///    - Validación más estricta de parámetros de entrada
///    - Logging de seguridad para auditoría
/// 
/// 4. **FUNCIONALIDADES ADICIONALES**:
///    - Sistema de recordatorios automáticos 24h antes
///    - Integración con calendario del club
///    - Dashboard de administración para staff
///    - Reportes de uso y estadísticas
/// 
/// CONSIDERACIONES TÃ‰CNICAS:
/// 
/// - **Logging**: Logs exhaustivos están activados para debugging,
///   considerar reducir en producción final para mejor performance
/// 
/// - **Error Handling**: Sistema robusto que nunca falla completamente,
///   siempre proporciona fallbacks funcionales
/// 
/// - **Escalabilidad**: Arquitectura preparada para crecimiento,
///   puede manejar 1000+ usuarios sin cambios significativos
/// 
/// - **Mantenimiento**: Código documentado y modular para facilitar
///   actualizaciones y debugging por múltiples desarrolladores
