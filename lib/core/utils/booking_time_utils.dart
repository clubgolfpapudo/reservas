// lib/core/utils/booking_time_utils.dart
class BookingTimeUtils {
  // Horarios predefinidos tennis/padel (invierno) - intervalos de 90 minutos
  static const List<String> winterTimeSlots = [
    "09:00", "10:30", "12:00", "13:30", "15:00", "16:30"
  ];
  
  // Horarios predefinidos tennis/padel (verano) - intervalos de 90 minutos  
  static const List<String> summerTimeSlots = [
    "09:00", "10:30", "12:00", "13:30", "15:00", "16:30", "18:00", "19:30"
  ];
  
  static DateTime get now => DateTime.now();
  
  // Ventana de 72 horas desde ahora
  static DateTime get maxBookingDate => now.add(Duration(hours: 72));
  
  // Siguiente slot disponible para tennis/padel
  static DateTime get earliestBookingTime {
    final currentTime = now;
    final currentSlots = _getCurrentSeasonSlots();
    
    // Encontrar el siguiente slot disponible hoy
    final nextSlot = _findNextAvailableSlot(currentTime, currentSlots);
    return nextSlot;
  }
  
  // Determinar si estamos en temporada de verano
  static bool _isSummerSeason() {
    final currentDate = DateTime.now();
    // Verano en Chile: Octubre a Marzo
    return currentDate.month >= 10 || currentDate.month <= 3;
  }
  
  // Obtener slots según temporada
  static List<String> _getCurrentSeasonSlots() {
    return _isSummerSeason() ? summerTimeSlots : winterTimeSlots;
  }
  
  // Encontrar el siguiente slot disponible desde el momento actual
  static DateTime _findNextAvailableSlot(DateTime currentTime, List<String> slots) {
    for (String slot in slots) {
      final slotTime = _parseTimeSlot(currentTime, slot);
      if (slotTime.isAfter(currentTime)) {
        return slotTime;
      }
    }
    
    // Si no hay slots hoy, empezar mañana a las 9:00
    return DateTime(
      currentTime.year,
      currentTime.month,
      currentTime.day + 1,
      9, 0
    );
  }
  
  // Validar si una fecha/hora está dentro de la ventana
  static bool isWithinBookingWindow(DateTime dateTime) {
    return dateTime.isAfter(earliestBookingTime) && 
           dateTime.isBefore(maxBookingDate);
  }
  
  // Filtrar slots disponibles por fecha (para tennis/padel)
  static List<String> getAvailableTimeSlots(DateTime date) {
    final allSlots = _getCurrentSeasonSlots();
    
    if (date.isSameDay(DateTime.now())) {
      // Para hoy, filtrar slots pasados
      return allSlots.where((slot) {
        final slotTime = _parseTimeSlot(date, slot);
        return isWithinBookingWindow(slotTime);
      }).toList();
    }
    
    return allSlots; // Para días futuros, todos los slots de la temporada
  }
  
  static DateTime _parseTimeSlot(DateTime date, String timeSlot) {
    final timeParts = timeSlot.split(':');
    return DateTime(
      date.year,
      date.month,
      date.day,
      int.parse(timeParts[0]),
      int.parse(timeParts[1])
    );
  }
  
  static DateTime parseTimeSlot(String timeSlot) {
    // Limpiar el timeSlot de cualquier texto extra (AM/PM, espacios)
    final cleanTime = timeSlot.replaceAll(RegExp(r'[^\d:]'), '');
    final parts = cleanTime.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, hour, minute);
  }

  static bool isWithin4Hours(String timeSlot1, String timeSlot2) {
    final time1 = parseTimeSlot(timeSlot1);
    final time2 = parseTimeSlot(timeSlot2);
    
    final difference = time1.difference(time2).abs();
    return difference.inHours < 4;
  }
}

extension DateTimeExtension on DateTime {
  bool isSameDay(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }
}
