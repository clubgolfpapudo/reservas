// lib/core/services/email_service.dart - Template Golf específico

  // ✅ MÉTODO PRINCIPAL EMAIL SERVICE - Integrar Golf
  String getEmailTemplate(ReservationData reservation) {
    switch (reservation.sportType) {
      case SportType.golf:
        return _getGolfEmailTemplate(reservation);
      case SportType.padel:
        return _getPadelEmailTemplate(reservation); // Existing
      case SportType.tennis:
        return _getTennisEmailTemplate(reservation); // Existing
    }
  }
  
  // ✅ TEMPLATE EMAIL GOLF - Tema verde profesional
  String _getGolfEmailTemplate(ReservationData reservation) {
    final courtName = _getGolfCourtDisplayName(reservation.courtId);
    final formattedDate = DateFormat('EEEE, d \'de\' MMMM \'de\' yyyy', 'es_ES')
        .format(reservation.date);
    final formattedTime = reservation.startTime.format(context);
    
    return '''
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Reserva Golf Confirmada - Club</title>
</head>
<body style="margin: 0; padding: 0; font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; 
            background-color: #f0f4f0; line-height: 1.6;">
  <div style="max-width: 600px; margin: 0 auto; background-color: #ffffff; 
              border-radius: 12px; overflow: hidden; box-shadow: 0 8px 32px rgba(124, 179, 66, 0.15);">
    
    <!-- Header Golf Verde -->
    <div style="background: linear-gradient(135deg, #7CB342 0%, #689F38 100%); 
                padding: 40px 30px; text-align: center; position: relative;">
      <img src="https://raw.githubusercontent.com/paddlepapudo/cgp_reservas/main/assets/images/club_logo.png" 
           alt="Club Logo" style="height: 70px; margin-bottom: 20px; filter: brightness(1.1);">
      <h1 style="color: #ffffff; margin: 0; font-size: 32px; font-weight: 700; 
                 text-shadow: 0 2px 4px rgba(0,0,0,0.2);">
        🌟 Reserva Golf Confirmada
      </h1>
      <div style="width: 80px; height: 4px; background: rgba(255,255,255,0.3); 
                  margin: 15px auto 0 auto; border-radius: 2px;"></div>
    </div>

    <!-- Contenido Principal -->
    <div style="padding: 40px 30px;">
      
      <!-- Saludo personalizado -->
      <div style="margin-bottom: 30px;">
        <h2 style="color: #689F38; margin: 0 0 10px 0; font-size: 24px; font-weight: 600;">
          ⛳ Hola ${reservation.playerName}
        </h2>
        <p style="color: #555; margin: 0; font-size: 16px;">
          Tu reserva de golf ha sido <strong style="color: #7CB342;">confirmada exitosamente</strong>. 
          Te esperamos en el campo para disfrutar de una excelente jornada.
        </p>
      </div>

      <!-- Detalles de la reserva -->
      <div style="background: linear-gradient(135deg, #f8fdf6 0%, #f0f8eb 100%); 
                  border-radius: 12px; padding: 25px; margin-bottom: 30px;
                  border-left: 5px solid #7CB342;">
        <h3 style="color: #689F38; margin: 0 0 20px 0; font-size: 18px; font-weight: 600;">
          📋 Detalles de tu Reserva
        </h3>
        
        <div style="display: table; width: 100%;">
          <div style="display: table-row;">
            <div style="display: table-cell; padding: 8px 15px 8px 0; color: #666; font-weight: 500;">
              🏌️ Campo:
            </div>
            <div style="display: table-cell; padding: 8px 0; color: #333; font-weight: 600;">
              ${courtName}
            </div>
          </div>
          <div style="display: table-row;">
            <div style="display: table-cell; padding: 8px 15px 8px 0; color: #666; font-weight: 500;">
              📅 Fecha:
            </div>
            <div style="display: table-cell; padding: 8px 0; color: #333; font-weight: 600;">
              ${formattedDate}
            </div>
          </div>
          <div style="display: table-row;">
            <div style="display: table-cell; padding: 8px 15px 8px 0; color: #666; font-weight: 500;">
              ⏰ Hora:
            </div>
            <div style="display: table-cell; padding: 8px 0; color: #333; font-weight: 600;">
              ${formattedTime}
            </div>
          </div>
          <div style="display: table-row;">
            <div style="display: table-cell; padding: 8px 15px 8px 0; color: #666; font-weight: 500;">
              👥 Jugadores:
            </div>
            <div style="display: table-cell; padding: 8px 0; color: #333; font-weight: 600;">
              ${reservation.players.length} jugador${reservation.players.length > 1 ? 'es' : ''}
            </div>
          </div>
        </div>
      </div>

      <!-- Lista de jugadores -->
      <div style="margin-bottom: 30px;">
        <h3 style="color: #689F38; margin: 0 0 15px 0; font-size: 18px; font-weight: 600;">
          🏌️‍♂️ Jugadores Confirmados
        </h3>
        <div style="background: #ffffff; border: 2px solid #e8f5e8; border-radius: 8px; padding: 20px;">
          ${reservation.players.map((player) => '''
            <div style="padding: 10px 0; border-bottom: 1px solid #f0f8eb; display: flex; align-items: center;">
              <span style="width: 30px; height: 30px; background: #7CB342; color: white; 
                          border-radius: 50%; display: inline-flex; align-items: center; 
                          justify-content: center; font-weight: 600; margin-right: 15px; font-size: 14px;">
                ${player.name.split(' ').map((n) => n[0]).take(1).join('')}
              </span>
              <span style="color: #333; font-weight: 500; font-size: 16px;">
                ${player.name}
              </span>
            </div>
          ''').join('')}
        </div>
      </div>

      <!-- Información importante Golf -->
      <div style="background: linear-gradient(135deg, #fff9e6 0%, #f5f2e0 100%); 
                  border-radius: 12px; padding: 25px; margin-bottom: 30px;
                  border-left: 5px solid #FFA726;">
        <h3 style="color: #F57C00; margin: 0 0 15px 0; font-size: 18px; font-weight: 600;">
          ⚠️ Información Importante
        </h3>
        <ul style="color: #666; margin: 0; padding-left: 20px; line-height: 1.8;">
          <li><strong>Código de vestimenta:</strong> Vestimenta deportiva apropiada para golf</li>
          <li><strong>Llegada:</strong> Presentarse 15 minutos antes del horario reservado</li>
          <li><strong>Duración estimada:</strong> 2 horas aproximadamente</li>
          <li><strong>Cancelación:</strong> Contactar con 24 horas de anticipación</li>
        </ul>
      </div>

      <!-- Botón cancelación -->
      <div style="text-align: center; margin: 30px 0;">
        <a href="${reservation.cancellationUrl}" 
           style="display: inline-block; background: linear-gradient(135deg, #7CB342 0%, #689F38 100%); 
                  color: #ffffff; text-decoration: none; padding: 15px 35px; 
                  border-radius: 8px; font-weight: 600; font-size: 16px;
                  box-shadow: 0 4px 15px rgba(124, 179, 66, 0.3);
                  transition: all 0.3s ease;">
          🗓️ Gestionar Reserva
        </a>
      </div>
    </div>

    <!-- Footer -->
    <div style="background: #f8fdf6; padding: 30px; text-align: center; border-top: 3px solid #7CB342;">
      <p style="color: #689F38; margin: 0 0 10px 0; font-size: 18px; font-weight: 600;">
        ¡Disfruta tu jornada de golf! 🏌️‍♂️
      </p>
      <p style="color: #666; margin: 0; font-size: 14px;">
        Este email fue generado automáticamente por el Sistema de Reservas del Club
      </p>
    </div>
  </div>
</body>
</html>
    ''';
  }
  
  // ✅ Helper para nombres de tee Golf - Actualizado con nomenclatura real
  String _getGolfCourtDisplayName(String courtId) {
    switch (courtId) {
      case 'golf_tee_1':
        return 'Hoyo 1 (Salida Principal)';
      case 'golf_tee_10':
        return 'Hoyo 10 (Salida Alternativa)';
      default:
        return 'Campo de Golf';
    }
  }
}