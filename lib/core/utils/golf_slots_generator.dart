// lib/core/utils/golf_slots_generator.dart
// SISTEMA DINÁMICO DE SLOTS GOLF - Cada 12 minutos con horarios estacionales

class GolfSlotsGenerator {
  
  // ✅ GENERAR SLOTS GOLF DINÁMICOS
  static List<TimeOfDay> generateDailySlots({DateTime? forDate}) {
    final targetDate = forDate ?? DateTime.now();
    final isWinter = _isWinterSeason(targetDate);
    
    // Horarios según temporada
    final startHour = 8;    // Siempre 08:00
    final endHour = isWinter ? 16 : 17;  // 16:00 invierno, 17:00 verano
    
    List<TimeOfDay> slots = [];
    int currentMinutes = startHour * 60; // 08:00 en minutos
    final endMinutes = endHour * 60;     // Hora final en minutos
    
    // Generar slots cada 12 minutos
    while (currentMinutes < endMinutes) { // < para no incluir el horario final
      final hour = currentMinutes ~/ 60;
      final minute = currentMinutes % 60;
      slots.add(TimeOfDay(hour: hour, minute: minute));
      currentMinutes += 12; // Incremento cada 12 minutos
    }
    
    return slots;
  }
  
  // ✅ DETECTAR TEMPORADA - Hemisferio Sur
  static bool _isWinterSeason(DateTime date) {
    final month = date.month;
    // Invierno: Mayo (5) a Agosto (8)
    // Verano: Septiembre (9) a Abril (4)
    return month >= 5 && month <= 8;
  }
  
  // ✅ OBTENER INFORMACIÓN TEMPORADA
  static String getCurrentSeasonInfo() {
    final now = DateTime.now();
    final isWinter = _isWinterSeason(now);
    final seasonName = isWinter ? 'Invierno' : 'Verano';
    final endTime = isWinter ? '16:00' : '17:00';
    
    return 'Temporada $seasonName - Salidas hasta $endTime';
  }
  
  // ✅ VALIDAR HORARIO DISPONIBLE
  static bool isSlotAvailable(TimeOfDay slot, {DateTime? forDate}) {
    final targetDate = forDate ?? DateTime.now();
    final isWinter = _isWinterSeason(targetDate);
    final maxHour = isWinter ? 16 : 17;
    
    // Verificar que esté dentro del horario operativo
    if (slot.hour < 8) return false;  // Antes de 08:00
    if (slot.hour >= maxHour) return false;  // Después del horario de temporada
    
    // Verificar que sea múltiplo de 12 minutos desde 08:00
    final slotMinutes = slot.hour * 60 + slot.minute;
    final startMinutes = 8 * 60; // 08:00
    final diffMinutes = slotMinutes - startMinutes;
    
    return diffMinutes >= 0 && diffMinutes % 12 == 0;
  }
  
  // ✅ PRÓXIMO SLOT DISPONIBLE
  static TimeOfDay? getNextAvailableSlot({DateTime? forDate}) {
    final now = DateTime.now();
    final currentTime = TimeOfDay.now();
    final slots = generateDailySlots(forDate: forDate);
    
    // Buscar próximo slot después de la hora actual
    for (final slot in slots) {
      if (_isAfter(slot, currentTime)) {
        return slot;
      }
    }
    
    return null; // No hay slots disponibles hoy
  }
  
  // ✅ HELPER: Comparar TimeOfDay
  static bool _isAfter(TimeOfDay time1, TimeOfDay time2) {
    final minutes1 = time1.hour * 60 + time1.minute;
    final minutes2 = time2.hour * 60 + time2.minute;
    return minutes1 > minutes2;
  }
  
  // ✅ FORMATEAR SLOT PARA DISPLAY
  static String formatSlotForDisplay(TimeOfDay slot) {
    final hour = slot.hour.toString().padLeft(2, '0');
    final minute = slot.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
  
  // ✅ OBTENER SLOTS COMO STRING PARA DEBUG
  static List<String> getSlotsAsString({DateTime? forDate}) {
    final slots = generateDailySlots(forDate: forDate);
    return slots.map((slot) => formatSlotForDisplay(slot)).toList();
  }
}

// ✅ EJEMPLO DE USO:
/*
// Obtener slots para hoy
final todaySlots = GolfSlotsGenerator.generateDailySlots();

// Obtener slots para fecha específica  
final futureSlots = GolfSlotsGenerator.generateDailySlots(
  forDate: DateTime(2025, 12, 25)
);

// Verificar si slot es válido
final isValid = GolfSlotsGenerator.isSlotAvailable(
  TimeOfDay(hour: 8, minute: 12)
);

// Próximo slot disponible
final nextSlot = GolfSlotsGenerator.getNextAvailableSlot();

// Información de temporada
final seasonInfo = GolfSlotsGenerator.getCurrentSeasonInfo();
// "Temporada Invierno - Salidas hasta 16:00"

// Slots como strings para debug
final slotsDebug = GolfSlotsGenerator.getSlotsAsString();
// ["08:00", "08:12", "08:24", "08:36", ..., "15:48"] (invierno)
// ["08:00", "08:12", "08:24", "08:36", ..., "16:48"] (verano)
*/