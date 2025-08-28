// lib/core/utils/booking_window_service.dart
// SERVICIO VENTANA DE RESERVAS - Diferente por deporte

import '../enums/sport_type.dart';

class BookingWindowService {
  
  // ✅ OBTENER VENTANA DE RESERVAS POR DEPORTE
  static int getBookingWindowHours(SportType sportType) {
    switch (sportType) {
      case SportType.golf:
        return 48; // 2 días (48 horas)
      case SportType.padel:
      case SportType.tennis:
        return 72; // 3 días (72 horas)
    }
  }
  
  // ✅ OBTENER FECHA MÁXIMA RESERVA
  static DateTime getMaxBookingDate(SportType sportType) {
    final now = DateTime.now();
    final windowHours = getBookingWindowHours(sportType);
    return now.add(Duration(hours: windowHours));
  }
  
  // ✅ VERIFICAR SI FECHA ESTÁ DENTRO DE VENTANA
  static bool isDateWithinBookingWindow(DateTime date, SportType sportType) {
    final now = DateTime.now();
    final maxDate = getMaxBookingDate(sportType);
    
    // Fecha debe ser hoy o futura, pero dentro de la ventana
    return date.isAfter(now.subtract(Duration(days: 1))) && 
           date.isBefore(maxDate.add(Duration(days: 1)));
  }
  
  // ✅ OBTENER FECHAS DISPONIBLES PARA RESERVA
  static List<DateTime> getAvailableBookingDates(SportType sportType) {
    final now = DateTime.now();
    final windowHours = getBookingWindowHours(sportType);
    final days = (windowHours / 24).floor();
    
    List<DateTime> dates = [];
    
    // Incluir desde hoy hasta el límite de días
    for (int i = 0; i <= days; i++) {
      final date = DateTime(now.year, now.month, now.day).add(Duration(days: i));
      dates.add(date);
    }
    
    return dates;
  }
  
  // ✅ MENSAJE INFORMATIVO VENTANA
  static String getBookingWindowMessage(SportType sportType) {
    final windowHours = getBookingWindowHours(sportType);
    final days = (windowHours / 24).floor();
    
    switch (sportType) {
      case SportType.golf:
        return 'Reservas disponibles hasta $days días desde ahora';
      case SportType.padel:
      case SportType.tennis:
        return 'Reservas disponibles hasta $days días desde ahora';
    }
  }
  
  // ✅ VALIDAR FECHA SELECCIONADA
  static ValidationResult validateSelectedDate(DateTime date, SportType sportType) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDay = DateTime(date.year, date.month, date.day);
    
    // No puede ser fecha pasada
    if (selectedDay.isBefore(today)) {
      return ValidationResult(
        isValid: false,
        reason: 'No puedes reservar en fechas pasadas',
      );
    }
    
    // Debe estar dentro de la ventana
    if (!isDateWithinBookingWindow(date, sportType)) {
      final days = (getBookingWindowHours(sportType) / 24).floor();
      final sportName = _getSportDisplayName(sportType);
      
      return ValidationResult(
        isValid: false,
        reason: 'Las reservas de $sportName solo están disponibles '
                'hasta $days días desde ahora',
      );
    }
    
    return ValidationResult(isValid: true);
  }
  
  // ✅ OBTENER NOMBRE DEPORTE PARA DISPLAY
  static String _getSportDisplayName(SportType sportType) {
    switch (sportType) {
      case SportType.golf:
        return 'Golf';
      case SportType.padel:
        return 'Pádel';
      case SportType.tennis:
        return 'Tenis';
    }
  }
  
  // ✅ INFORMACIÓN DEBUG VENTANA
  static Map<String, dynamic> getBookingWindowInfo(SportType sportType) {
    final windowHours = getBookingWindowHours(sportType);
    final maxDate = getMaxBookingDate(sportType);
    final availableDates = getAvailableBookingDates(sportType);
    
    return {
      'sport': _getSportDisplayName(sportType),
      'windowHours': windowHours,
      'windowDays': (windowHours / 24).floor(),
      'maxBookingDate': maxDate,
      'availableDatesCount': availableDates.length,
      'message': getBookingWindowMessage(sportType),
    };
  }
}

// ✅ RESULTADO VALIDACIÓN (reutilizar clase)
class ValidationResult {
  final bool isValid;
  final String? reason;
  
  ValidationResult({
    required this.isValid,
    this.reason,
  });
}

// ✅ EJEMPLOS DE USO:
/*
// Golf - 48 horas
final golfWindow = BookingWindowService.getBookingWindowHours(SportType.golf);
// Returns: 48

final golfMaxDate = BookingWindowService.getMaxBookingDate(SportType.golf);
// Returns: DateTime 2 días desde ahora

final golfDates = BookingWindowService.getAvailableBookingDates(SportType.golf);
// Returns: [Hoy, Mañana, Pasado mañana] (3 fechas)

// Pádel/Tenis - 72 horas  
final padelWindow = BookingWindowService.getBookingWindowHours(SportType.padel);
// Returns: 72

final padelDates = BookingWindowService.getAvailableBookingDates(SportType.padel);
// Returns: [Hoy, Mañana, Pasado mañana, Día +3] (4 fechas)

// Validación fecha
final validation = BookingWindowService.validateSelectedDate(
  DateTime(2025, 9, 1), 
  SportType.golf
);

if (!validation.isValid) {
  print(validation.reason); // Mensaje específico por deporte
}
*/