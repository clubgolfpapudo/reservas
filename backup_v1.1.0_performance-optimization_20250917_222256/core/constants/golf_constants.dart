// lib/core/constants/golf_constants.dart
// Golf-specific constants for Club de Golf Papudo
// REFACTORIZADO: Los horarios ahora se obtienen de AppConstants

import '../constants/app_constants.dart';

class GolfConstants {
  // Sport identification
  static const String SPORT_NAME = 'Golf';
  static const String SPORT_ID = 'golf';

  // Tee configuration
  static const List<String> teeNames = [
    'Hoyo 1',
    'Hoyo 10'
  ];

  static const List<String> COURT_IDS = [
    'golf_tee_1',
    'golf_tee_10'
  ];

  // Colors for tees
  static const Map<String, int> teeColors = {
    'golf_tee_1': 0xFF4CAF50,  // Verde
    'golf_tee_10': 0xFF66BB6A, // Verde claro
  };

  // Player configuration
  static const int maxPlayersPerBooking = 4;
  static const int MIN_PLAYERS_PER_BOOKING = 1;

  // Booking horizon (48 hours vs 72 for tennis/paddle)
  static const int BOOKING_HORIZON_HOURS = 48;

  // ═══════════════════════════════════════════════════════════════════════════
  // ⏰ HORARIOS: DELEGADOS A AppConstants (REFACTORIZADO)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Obtiene horarios de golf usando AppConstants centralizado
  static List<String> getTimeSlots({bool? isSummer}) {
    DateTime? date;
    if (isSummer != null) {
      // Si se especifica la temporada, crear una fecha que corresponda
      final now = DateTime.now();
      date = isSummer 
        ? DateTime(now.year, 12, 15) // Diciembre (verano)
        : DateTime(now.year, 6, 15);  // Junio (invierno)
    }
    return AppConstants.getTimeSlotsForSport('golf', date);
  }

  /// Obtiene el último horario disponible del día
  static String getLastTimeSlot({bool? isSummer}) {
    DateTime? date;
    if (isSummer != null) {
      final now = DateTime.now();
      date = isSummer 
        ? DateTime(now.year, 12, 15)
        : DateTime(now.year, 6, 15);
    }
    return AppConstants.getLastTimeSlotForSport('golf', date);
  }

  /// Obtiene el primer horario disponible del día
  static String getFirstTimeSlot({bool? isSummer}) {
    DateTime? date;
    if (isSummer != null) {
      final now = DateTime.now();
      date = isSummer 
        ? DateTime(now.year, 12, 15)
        : DateTime(now.year, 6, 15);
    }
    return AppConstants.getFirstTimeSlotForSport('golf', date);
  }

  /// Verifica si un horario está disponible
  static bool isTimeSlotAvailable(String timeSlot, {bool? isSummer}) {
    DateTime? date;
    if (isSummer != null) {
      final now = DateTime.now();
      date = isSummer 
        ? DateTime(now.year, 12, 15)
        : DateTime(now.year, 6, 15);
    }
    return AppConstants.isTimeSlotAvailableForSport('golf', timeSlot, date);
  }

  // Season detection (mantener para compatibilidad)
  static bool get isSummer {
    final now = DateTime.now();
    final month = now.month;
    return month >= 10 || month <= 3;
  }

  // Horarios por defecto usando temporada actual
  static List<String> get DEFAULT_TIME_SLOTS => getTimeSlots();

  // ═══════════════════════════════════════════════════════════════════════════
  // 🏌️ LÓGICA ESPECÍFICA DE GOLF (MANTENIDA)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Verifica si Hoyo 10 está suspendido (delegado a AppConstants)
  static bool isHoyo10Suspended(String timeSlot) {
    return AppConstants.isHoyo10Suspended(timeSlot);
  }

  // Constantes específicas de golf que no aplican a otros deportes
  static const String SUSPENSION_START = "10:12";
  static const String SUSPENSION_END = "12:48";

  // Firebase collection names (golf-specific)
  static const String BOOKINGS_COLLECTION = 'golf_bookings';
  static const String COURTS_COLLECTION = 'golf_tees';

  // ═══════════════════════════════════════════════════════════════════════════
  // 🔧 MÉTODOS DE CONVENIENCIA (COMPATIBILIDAD)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Método de conveniencia para obtener configuración de Golf desde AppConstants
  static int get maxPlayers => AppConstants.golfMaxPlayersPerBooking;
  static int get minPlayers => AppConstants.golfMinPlayersPerBooking;
  static int get bookingHorizonHours => AppConstants.golfBookingHorizonHours;
}