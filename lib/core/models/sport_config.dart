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
      // ✅ VALIDACIONES GOLF - Sin restricciones especiales
      customValidations: {
        'handicap_required': false,    // No requiere handicap
        'categories_required': false,  // No requiere categorías
        'seasonal_hours': true,        // Horarios por temporada
        'tee_restrictions': true,      // Restricciones entre Hoyo 1 y 10
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