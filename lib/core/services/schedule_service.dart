// lib/core/services/schedule_service.dart
import 'package:flutter/material.dart';

/// Servicio para manejar horarios de reservas según temporada (verano/invierno)
/// y determinar la fecha de apertura apropiada de la aplicación

class ScheduleService {
  // Horarios por temporada en Chile
  static const TimeOfDay _winterLastReservation = TimeOfDay(hour: 19, minute: 30);
  static const TimeOfDay _summerLastReservation = TimeOfDay(hour: 21, minute: 0);
  
  /// Determina si estamos en horario de verano en Chile
  /// Horario de verano: segundo domingo de octubre a primer domingo de abril
  static bool _isSummerTime(DateTime date) {
    final month = date.month;
    final day = date.day;
    
    // Aproximación: octubre a marzo (se puede refinar con fechas exactas)
    if (month >= 10 || month <= 3) {
      // Verificaciones más específicas para octubre y abril
      if (month == 10) {
        // En octubre, generalmente comienza el segundo domingo
        return day >= 8; // Aproximación
      } else if (month == 4) {
        // En abril, generalmente termina el primer domingo
        return day <= 7; // Aproximación
      }
      return true; // Noviembre, diciembre, enero, febrero, marzo
    }
    
    return false; // Abril-septiembre (invierno)
  }
  
  /// Obtiene la última hora de reserva según la temporada
  static TimeOfDay getLastReservationTime([DateTime? date]) {
    date ??= DateTime.now();
    return _isSummerTime(date) ? _summerLastReservation : _winterLastReservation;
  }
  
  /// Determina qué fecha mostrar al abrir la app
  static DateTime getDefaultDisplayDate() {
    final now = DateTime.now();
    final lastReservationTime = getLastReservationTime(now);
    
    // Convertir TimeOfDay a DateTime para comparar
    final lastReservationToday = DateTime(
      now.year, 
      now.month, 
      now.day,
      lastReservationTime.hour,
      lastReservationTime.minute
    );
    
    // Si ya pasó la última hora, mostrar mañana
    if (now.isAfter(lastReservationToday)) {
      return DateTime(now.year, now.month, now.day + 1);
    }
    
    return DateTime(now.year, now.month, now.day); // Mostrar hoy
  }
  
  /// Obtiene información de debug sobre el horario actual
  static Map<String, dynamic> getScheduleDebugInfo() {
    final now = DateTime.now();
    final isSummer = _isSummerTime(now);
    final lastTime = getLastReservationTime(now);
    final defaultDate = getDefaultDisplayDate();
    
    return {
      'currentTime': now.toString(),
      'isSummerTime': isSummer,
      'lastReservationTime': '${lastTime.hour}:${lastTime.minute.toString().padLeft(2, '0')}',
      'defaultDisplayDate': defaultDate.toString(),
      'showingTomorrow': !_isSameDay(defaultDate, now),
    };
  }
  
  static bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && 
           date1.month == date2.month && 
           date1.day == date2.day;
  }
}