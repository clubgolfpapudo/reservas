const {onRequest} = require("firebase-functions/v2/https");
const {setGlobalOptions} = require("firebase-functions/v2");
const nodemailer = require("nodemailer");
const {google} = require("googleapis");

// Configuración global
setGlobalOptions({maxInstances: 10});

const OAuth2 = google.auth.OAuth2;

/**
 * Creates Gmail transporter with OAuth2
 * @return {object} Nodemailer transporter
 */
const createTransporter = async () => {
  const oauth2Client = new OAuth2(
      process.env.GMAIL_CLIENT_ID,
      process.env.GMAIL_CLIENT_SECRET,
      "https://developers.google.com/oauthplayground",
  );

  oauth2Client.setCredentials({
    refresh_token: process.env.GMAIL_REFRESH_TOKEN,
  });

  const accessToken = await new Promise((resolve, reject) => {
    oauth2Client.getAccessToken((err, token) => {
      if (err) {
        console.error("Error obteniendo access token:", err);
        reject(new Error("Failed to create access token"));
      }
      resolve(token);
    });
  });

  return nodemailer.createTransporter({
    service: "gmail",
    auth: {
      type: "OAuth2",
      user: process.env.GMAIL_EMAIL,
      accessToken,
      clientId: process.env.GMAIL_CLIENT_ID,
      clientSecret: process.env.GMAIL_CLIENT_SECRET,
      refreshToken: process.env.GMAIL_REFRESH_TOKEN,
    },
  });
};

exports.sendBookingEmail = onRequest({
  cors: true,
  secrets: ["GMAIL_EMAIL", "GMAIL_CLIENT_ID", "GMAIL_CLIENT_SECRET", 
    "GMAIL_REFRESH_TOKEN"],
}, async (req, res) => {
  if (req.method === "OPTIONS") {
    res.status(204).send("");
    return;
  }

  try {
    const {to, playerName, isOrganizer, booking, icsContent} = req.body;

    console.log(`📧 Enviando email a: ${playerName} (${to})`);

    const transporter = await createTransporter();

    const emailHtml = generateBookingEmailHtml({
      playerName,
      isOrganizer,
      booking,
    });

    const mailOptions = {
      from: `Club de Golf Papudo <${process.env.GMAIL_EMAIL}>`,
      to: to,
      subject: `Reserva de Pádel Confirmada - ${formatDate(booking.date)}`,
      html: emailHtml,
      attachments: [
        {
          filename: "reserva-padel.ics",
          content: icsContent,
          contentType: "text/calendar",
        },
      ],
    };

    const result = await transporter.sendMail(mailOptions);
    console.log(`✅ Email enviado a ${playerName}:`, result.messageId);

    res.status(200).json({
      success: true,
      messageId: result.messageId,
      recipient: playerName,
    });
  } catch (error) {
    console.error("❌ Error enviando email:", error);
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

exports.sendCancellationEmail = onRequest({
  cors: true,
  secrets: ["GMAIL_EMAIL", "GMAIL_CLIENT_ID", "GMAIL_CLIENT_SECRET", 
    "GMAIL_REFRESH_TOKEN"],
}, async (req, res) => {
  if (req.method === "OPTIONS") {
    res.status(204).send("");
    return;
  }

  try {
    const {to, playerName, cancelingPlayerName, booking} = req.body;

    console.log(`📧 Enviando cancelación a: ${playerName} (${to})`);

    const transporter = await createTransporter();

    const emailHtml = generateCancellationEmailHtml({
      playerName,
      cancelingPlayerName,
      booking,
    });

    const mailOptions = {
      from: `Club de Golf Papudo <${process.env.GMAIL_EMAIL}>`,
      to: to,
      subject: `Reserva de Pádel Cancelada - ${formatDate(booking.date)}`,
      html: emailHtml,
    };

    const result = await transporter.sendMail(mailOptions);
    console.log(`✅ Cancelación enviada a ${playerName}:`, result.messageId);

    res.status(200).json({
      success: true,
      messageId: result.messageId,
    });
  } catch (error) {
    console.error("❌ Error enviando cancelación:", error);
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

/**
 * Generate HTML for booking confirmation email
 * @param {object} data Email data
 * @return {string} HTML content
 */
function generateBookingEmailHtml({playerName, isOrganizer, booking}) {
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
                    <a href="#" class="button button-primary">
                    📅 Añadir al Calendario</a>
                    <a href="https://cgpreservas.web.app/cancel/${booking.id}" 
                    class="button button-secondary">❌ Cancelar Reserva</a>
                </div>

                <div style="background: #fef3cd; padding: 16px; 
                border-radius: 6px; margin: 20px 0;">
                    <strong>💡 Tip:</strong> Este evento se ha añadido 
                    automáticamente a tu calendario. 
                    El archivo adjunto (.ics) te permite agregarlo 
                    manualmente si es necesario.
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

/**
 * Generate HTML for cancellation email
 * @param {object} data Email data
 * @return {string} HTML content
 */
function generateCancellationEmailHtml({playerName, cancelingPlayerName,
  booking}) {
  const courtName = getCourtName(booking.courtNumber);

  return `
    <!DOCTYPE html>
    <html lang="es">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Reserva Cancelada - Pádel Papudo</title>
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
                background: linear-gradient(135deg, #dc2626, #b91c1c); 
                color: white; padding: 40px 20px; text-align: center; 
            }
            .content { padding: 30px; }
            .info-box { 
                background: #fef2f2; border: 1px solid #fecaca; 
                border-radius: 8px; padding: 16px; margin: 20px 0; 
            }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>🚫 Reserva Cancelada</h1>
                <p>Club de Golf Papudo - Pádel</p>
            </div>
            
            <div class="content">
                <h2>Hola ${playerName},</h2>
                
                <div class="info-box">
                    <p><strong>${cancelingPlayerName}</strong> ha cancelado 
                    la reserva de pádel programada para:</p>
                    <ul>
                        <li><strong>Fecha:</strong> ${formatDate(booking.date)}</li>
                        <li><strong>Hora:</strong> ${booking.timeSlot}</li>
                        <li><strong>Cancha:</strong> ${courtName}</li>
                    </ul>
                </div>
                
                <p>Si deseas hacer una nueva reserva, puedes usar 
                la aplicación del club o contactarnos directamente.</p>
                
                <p>Saludos cordiales,<br>
                <strong>Club de Golf Papudo</strong></p>
            </div>

            <div style="background: #f8fafc; padding: 20px; 
            text-align: center; color: #64748b; font-size: 14px;">
                <p>
                    <strong>Club de Golf Papudo</strong> • Desde 1932<br>
                    📧 <a href="mailto:paddlepapudo@gmail.com" 
                    style="color: #1e3a8a;">paddlepapudo@gmail.com</a>
                </p>
            </div>
        </div>
    </body>
    </html>
  `;
}

/**
 * Get court display name
 * @param {string} courtNumber Court identifier
 * @return {string} Display name
 */
function getCourtName(courtNumber) {
  const courts = {
    "court_1": "Cancha 1 - PITE",
    "court_2": "Cancha 2 - LILEN",
    "court_3": "Cancha 3 - PLAIYA",
  };
  return courts[courtNumber] || courtNumber;
}

/**
 * Format date for display
 * @param {string} dateStr Date string
 * @return {string} Formatted date
 */
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

/**
 * Get end time for booking
 * @param {string} startTime Start time
 * @return {string} End time
 */
function getEndTime(startTime) {
  const [hours, minutes] = startTime.split(":").map(Number);
  const endDate = new Date();
  endDate.setHours(hours, minutes);
  endDate.setTime(endDate.getTime() + 90 * 60000);
  return endDate.toTimeString().slice(0, 5);
}
