// lib/core/models/court.dart - Agregar configuración Golf
// BASADO EN ANÁLISIS DEL SISTEMA GOLF ACTUAL

class Court {
  // Existing code...
  
  // ✅ CANCHAS GOLF - Configuración real: Hoyo 1 y Hoyo 10 (mismo campo, 18 hoyos)
  static List<Court> getGolfCourts() {
    return [
      Court(
        id: 'golf_tee_1',
        name: 'Hoyo 1', 
        displayName: 'Hoyo 1 (Salida Principal)',
        color: Color(0xFF7CB342), // Verde golf principal
      ),
      Court(
        id: 'golf_tee_10',
        name: 'Hoyo 10',
        displayName: 'Hoyo 10 (Salida Alternativa)', 
        color: Color(0xFF689F38), // Verde golf secundario
      ),
    ];
  }
}

// lib/core/models/sport_config.dart - Configuración específica Golf
class SportConfig {
  // Existing code...
  
  // ✅ CONFIGURACIÓN GOLF - Reglas exactas según especificaciones
  static SportConfig getGolfConfig() {
    return SportConfig(
      sportType: SportType.golf,
      maxPlayers: 4, // Máximo 4 jugadores por grupo
      minPlayers: 1, // Mínimo 1 jugador (individual permitido)
      slotDuration: Duration(minutes: 12), // Salidas cada 12 minutos
      operatingHours: _getSeasonalOperatingHours(), // Horarios por temporada
      // ✅ SLOTS GOLF - Cada 12 minutos desde 08:00
      availableSlots: _generateGolfSlots(),
      // ✅ VALIDACIONES GOLF - Especificaciones exactas
      customValidations: {
        'handicap_required': false,           // No requiere handicap
        'scoring_system': false,              // Sin sistema scoring por ahora
        'categories_required': false,         // No requiere categorías
        'seasonal_hours': true,               // Horarios por temporada
        'booking_window_hours': 48,           // 48 horas vs 72 Pádel/Tenis
        'simultaneous_tee_restriction': true, // No puede reservar Hoyo 1 Y 10 simultáneamente
        'show_both_tees': true,               // Mostrar ambos tees en vista 3 columnas
        'view_type': 'three_column',          // HORA | HOYO 1 | HOYO 10
      },
    );
  }
  
  // ✅ HORARIOS ESTACIONALES - Invierno hasta 16:00, Verano hasta 17:00
  static TimeRange _getSeasonalOperatingHours() {
    final now = DateTime.now();
    final isWinter = _isWinterSeason(now);
    
    return TimeRange(
      start: TimeOfDay(hour: 8, minute: 0),  // Siempre inicia 08:00
      end: TimeOfDay(
        hour: isWinter ? 16 : 17,           // 16:00 invierno, 17:00 verano
        minute: 0,
      ),
    );
  }
  
  // ✅ DETECTAR TEMPORADA - Invierno: Mayo-Agosto, Verano: Septiembre-Abril
  static bool _isWinterSeason(DateTime date) {
    final month = date.month;
    return month >= 5 && month <= 8; // Mayo a Agosto = Invierno (Hemisferio Sur)
  }
  
  // ✅ GENERAR SLOTS CADA 12 MINUTOS - Desde 08:00 hasta horario estacional
  static List<TimeOfDay> _generateGolfSlots() {
    final now = DateTime.now();
    final isWinter = _isWinterSeason(now);
    final endHour = isWinter ? 16 : 17;
    
    List<TimeOfDay> slots = [];
    int currentMinutes = 8 * 60; // 08:00 en minutos
    final endMinutes = endHour * 60; // Hora final en minutos
    
    while (currentMinutes <= endMinutes) {
      final hour = currentMinutes ~/ 60;
      final minute = currentMinutes % 60;
      slots.add(TimeOfDay(hour: hour, minute: minute));
      currentMinutes += 12; // Incrementar 12 minutos
    }
    
    return slots;
  }
}

// lib/core/constants/app_constants.dart - Constantes Golf
class GolfConstants {
  // ✅ CONFIGURACIÓN ESPECÍFICA GOLF
  static const String SPORT_ID = 'golf';
  static const String DISPLAY_NAME = 'Golf';
  static const String DESCRIPTION = 'Campo de golf de 18 hoyos, par 68';
  
  // ✅ VENTANA RESERVAS - 48 horas vs 72 Pádel/Tenis
  static const int BOOKING_WINDOW_HOURS = 48;  // 2 días vs 3 días otros deportes
  
  // ✅ COLORES TEMA GOLF
  static const Color PRIMARY_COLOR = Color(0xFF7CB342);
  static const Color SECONDARY_COLOR = Color(0xFF689F38);
  static const Color ACCENT_COLOR = Color(0xFF8BC34A);
  
  // ✅ CONFIGURACIÓN VISTA - 3 columnas única para Golf
  static const String VIEW_TYPE = 'three_column';  // HORA | HOYO 1 | HOYO 10
  static const bool SHOW_BOTH_TEES = true;         // Siempre mostrar ambos tees
  static const bool AUTO_SELECT_COURT = false;     // No auto-seleccionar (mostrar ambos)
  
  // ✅ COLORES TEMA GOLF
  static const Color PRIMARY_COLOR = Color(0xFF7CB342);
  static const Color SECONDARY_COLOR = Color(0xFF689F38);
  static const Color ACCENT_COLOR = Color(0xFF8BC34A);
  
  // ✅ REGLAS ESPECÍFICAS GOLF - Actualizadas según especificaciones reales
  static const int MAX_PLAYERS_PER_GROUP = 4;  // Máximo 4 jugadores
  static const int MIN_PLAYERS_PER_GROUP = 1;  // Mínimo 1 jugador
  static const Duration SLOT_INTERVAL = Duration(minutes: 12); // Cada 12 minutos
  
  // ✅ HORARIOS ESTACIONALES
  static const String SUMMER_START = '08:00';   // Inicio siempre 08:00
  static const String SUMMER_END = '17:00';     // Verano hasta 17:00
  static const String WINTER_END = '16:00';     // Invierno hasta 16:00
  
  // ✅ CONFIGURACIÓN TEES
  static const String TEE_1_ID = 'golf_tee_1';  // Hoyo 1 (Principal)
  static const String TEE_10_ID = 'golf_tee_10'; // Hoyo 10 (Alternativa)
  
  // ✅ MENSAJES GOLF ACTUALIZADOS
  static const String BOOKING_SUCCESS_MESSAGE = '⛳ Reserva Golf confirmada';
  static const String BOOKING_EMAIL_SUBJECT = '🌟 Confirmación Reserva Golf - Club';
  static const String CONFLICT_MESSAGE = 'Ya tienes una reserva de Golf en este horario';
  static const String SEASONAL_INFO = 'Horarios varían según temporada: Verano hasta 17:00, Invierno hasta 16:00';
}