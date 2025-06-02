// ============================================================================
// lib/data/services/ics_generator.dart
// ============================================================================

import '../../domain/entities/booking.dart';

class IcsGenerator {
  // ============================================================================
  // GENERAR ARCHIVO .ICS PARA CALENDARIO
  // ============================================================================
  
  static String generateBookingIcs(Booking booking) {
    final now = DateTime.now();
    final timestamp = _formatDateTime(now);
    
    // Parsear fecha y hora
    final dateParts = booking.date.split('-');
    final timeParts = booking.timeSlot.split(':');
    
    final year = int.parse(dateParts[0]);
    final month = int.parse(dateParts[1]);
    final day = int.parse(dateParts[2]);
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);
    
    final startDateTime = DateTime(year, month, day, hour, minute);
    final endDateTime = startDateTime.add(const Duration(hours: 1, minutes: 30));
    
    // Información de la cancha
    final courtName = _getCourtName(booking.courtNumber);
    
    // Lista de jugadores
    final playerNames = booking.players.map((p) => p.name).join(', ');
    
    // Generar UID único
    final uid = '${booking.id ?? timestamp}@cgpreservas.com';
    
    return '''BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//Club de Golf Papudo//Padel Reservas//ES
CALSCALE:GREGORIAN
METHOD:REQUEST
BEGIN:VEVENT
UID:$uid
DTSTAMP:$timestamp
DTSTART:${_formatDateTime(startDateTime)}
DTEND:${_formatDateTime(endDateTime)}
SUMMARY:Pádel - $courtName
DESCRIPTION:Reserva de pádel confirmada\\n\\nJugadores: $playerNames\\n\\nClub de Golf Papudo\\nDesde 1932
LOCATION:$courtName, Club de Golf Papudo, Papudo
ORGANIZER;CN=Club de Golf Papudo:mailto:paddlepapudo@gmail.com
STATUS:CONFIRMED
TRANSP:OPAQUE
BEGIN:VALARM
TRIGGER:-PT15M
ACTION:DISPLAY
DESCRIPTION:Recordatorio: Pádel en $courtName en 15 minutos
END:VALARM
END:VEVENT
END:VCALENDAR''';
  }
  
  // ============================================================================
  // UTILIDADES PARA FORMATO ICS
  // ============================================================================
  
  static String _formatDateTime(DateTime dateTime) {
    // Formato: YYYYMMDDTHHMMSSZ
    return '${dateTime.year}'
        '${dateTime.month.toString().padLeft(2, '0')}'
        '${dateTime.day.toString().padLeft(2, '0')}'
        'T'
        '${dateTime.hour.toString().padLeft(2, '0')}'
        '${dateTime.minute.toString().padLeft(2, '0')}'
        '${dateTime.second.toString().padLeft(2, '0')}'
        'Z';
  }

  static String _getCourtName(String courtNumber) {
    switch (courtNumber) {
      case 'court_1':
        return 'Cancha 1 - PITE';
      case 'court_2':
        return 'Cancha 2 - LILEN';
      case 'court_3':
        return 'Cancha 3 - PLAIYA';
      default:
        return courtNumber;
    }
  }
  
  // ============================================================================
  // GENERAR .ICS PARA CANCELACIÓN
  // ============================================================================
  
  static String generateCancellationIcs(Booking booking) {
    final now = DateTime.now();
    final timestamp = _formatDateTime(now);
    
    // Mismo UID para cancelar el evento original
    final uid = '${booking.id ?? timestamp}@cgpreservas.com';
    
    return '''BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//Club de Golf Papudo//Padel Reservas//ES
CALSCALE:GREGORIAN
METHOD:CANCEL
BEGIN:VEVENT
UID:$uid
DTSTAMP:$timestamp
SUMMARY:CANCELADO - Pádel
DESCRIPTION:Esta reserva de pádel ha sido cancelada.
STATUS:CANCELLED
END:VEVENT
END:VCALENDAR''';
  }
}