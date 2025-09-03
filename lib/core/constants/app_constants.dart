// lib/core/constants/app_constants.dart - VERSIÓN REFACTORIZADA CON HORARIOS CENTRALIZADOS
import 'package:flutter/material.dart';

abstract class AppConstants {
  // ═══════════════════════════════════════════════════════════════════════════
  // 🏢 BRANDING CORPORATIVO - CLUB DE GOLF PAPUDO
  // ═══════════════════════════════════════════════════════════════════════════
  
  // Colores del logo oficial
  static const int corporateNavyBlue = 0xFF1B365D;
  static const int corporateGold = 0xFFFFD700;
  static const int corporateRed = 0xFFDC143C;
  static const int corporateGreen = 0xFF7CB342;
  static const int corporateWhite = 0xFFFFFFFF;
  static const int corporateLightBlue = 0xFF2C4B7D;
  
  // Información corporativa
  // static const String clubName = 'Club de Golf Papudo';
  static const String clubName = '';
  static const String clubYear = '1932';
  static const String systemTitle = 'Reservas y Servicios';
  
  // ═══════════════════════════════════════════════════════════════════════════
  // 🎨 COLORES POR DEPORTE
  // ═══════════════════════════════════════════════════════════════════════════
  
  static const int padelPrimary = 0xFF2E7AFF;
  static const int padelSecondary = 0xFF1E5AFF;
  
  static const int tennisPrimary = 0xFFD2691E;
  static const int tennisSecondary = 0xFFB8860B;
  static const int tennisBackground = 0xFFFFF8DC;
  
  static const int golfPrimary = 0xFF7CB342;
  static const int golfSecondary = 0xFF558B2F;
  static const int golfBackground = 0xFFF1F8E9;
  
  // ═══════════════════════════════════════════════════════════════════════════
  // ⏰ HORARIOS CENTRALIZADOS POR DEPORTE (REFACTORIZADO)
  // ═══════════════════════════════════════════════════════════════════════════
  
  // Configuración de horarios por deporte
  static const Map<String, Map<String, dynamic>> _sportScheduleConfig = {
    'padel': {
      'startTime': '09:00',
      'winterEndTime': '18:00',
      'summerEndTime': '21:00',
      'intervalMinutes': 90, // slots de 90 minutos
      'customSlots': true,   // usa slots predefinidos en lugar de intervalos
    },
    'tennis': {
      'startTime': '09:00',
      'winterEndTime': '18:00',
      'summerEndTime': '21:00',
      'intervalMinutes': 90, // slots de 90 minutos
      'customSlots': true,   // usa slots predefinidos en lugar de intervalos
    },
    'golf': {
      'startTime': '08:00',
      'winterEndTime': '16:00',
      'summerEndTime': '17:00',
      'intervalMinutes': 12,  // slots de 12 minutos
      'customSlots': false,   // genera slots automáticamente
    },
  };
  
  // Horarios predefinidos para Pádel y Tenis (invierno)
  static const List<String> _winterTimeSlots = [
    '09:00',
    '10:30',
    '12:00',
    '13:30',
    '15:00',
    '16:30',
  ];
  
  // Horarios predefinidos para Pádel y Tenis (verano)
  static const List<String> _summerTimeSlots = [
    '09:00',
    '10:30',
    '12:00',
    '13:30',
    '15:00',
    '16:30',
    '18:00',
    '19:30',
    '21:00',
  ];

  /// Genera horarios automáticamente para Golf basado en intervalos
  static List<String> _generateGolfTimeSlots(bool isSummer) {
    final config = _sportScheduleConfig['golf']!;
    final startTime = config['startTime'] as String;
    final endTime = isSummer ? config['summerEndTime'] as String : config['winterEndTime'] as String;
    final intervalMinutes = config['intervalMinutes'] as int;
    
    final slots = <String>[];
    DateTime current = DateTime.parse('2024-01-01 $startTime:00');
    final end = DateTime.parse('2024-01-01 $endTime:00');
    
    while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
      final timeString = '${current.hour.toString().padLeft(2, '0')}:${current.minute.toString().padLeft(2, '0')}';
      slots.add(timeString);
      current = current.add(Duration(minutes: intervalMinutes));
    }
    
    return slots;
  }

  /// Detecta si es temporada de verano (hemisferio sur)
  static bool _isSummerSeason([DateTime? date]) {
    date ??= DateTime.now();
    final month = date.month;
    return month >= 10 || month <= 3; // Octubre a Marzo
  }

  /// Obtiene horarios para un deporte específico
  static List<String> getTimeSlotsForSport(String sport, [DateTime? date]) {
    final isSummer = _isSummerSeason(date);
    
    switch (sport.toLowerCase()) {
      case 'padel':
      case 'tennis':
        return isSummer ? _summerTimeSlots : _winterTimeSlots;
      case 'golf':
        return _generateGolfTimeSlots(isSummer);
      default:
        return _winterTimeSlots; // Fallback
    }
  }

  /// Obtiene todos los horarios por deporte
  static Map<String, List<String>> getAllSportTimeSlots([DateTime? date]) {
    return {
      'padel': getTimeSlotsForSport('padel', date),
      'tennis': getTimeSlotsForSport('tennis', date),
      'golf': getTimeSlotsForSport('golf', date),
    };
  }

  /// Obtiene el último horario disponible para un deporte
  static String getLastTimeSlotForSport(String sport, [DateTime? date]) {
    final slots = getTimeSlotsForSport(sport, date);
    return slots.isNotEmpty ? slots.last : '16:00';
  }

  /// Obtiene fechas y horarios disponibles con ventana deslizante (solo Tenis/Pádel)
  static Map<DateTime, List<String>> getSlidingWindowSlots(String sport, DateTime fromTime) {
    final Map<DateTime, List<String>> result = {};
    
    // Solo aplicar ventana deslizante a Tenis y Pádel
    if (sport.toLowerCase() != 'tennis' && sport.toLowerCase() != 'padel') {
      return result;
    }
    
    final endTime = fromTime.add(Duration(hours: 72)); // 72 horas desde ahora
    DateTime currentDate = DateTime(fromTime.year, fromTime.month, fromTime.day);
    
    while (currentDate.isBefore(endTime) || currentDate.isAtSameMomentAs(DateTime(endTime.year, endTime.month, endTime.day))) {
      final allSlotsForDate = getTimeSlotsForSport(sport, currentDate);
      final availableSlots = <String>[];
      
      for (String timeSlot in allSlotsForDate) {
        final parts = timeSlot.split(':');
        final slotDateTime = DateTime(
          currentDate.year, 
          currentDate.month, 
          currentDate.day,
          int.parse(parts[0]),
          int.parse(parts[1])
        );
        
        // Solo incluir slots que estén dentro de la ventana de 72 horas
        if (slotDateTime.isAfter(fromTime) && slotDateTime.isBefore(endTime)) {
          availableSlots.add(timeSlot);
        }
      }
      
      if (availableSlots.isNotEmpty) {
        result[currentDate] = availableSlots;
      }
      
      currentDate = currentDate.add(Duration(days: 1));
    }
    
    return result;
  }

  /// Obtiene el primer horario disponible para un deporte
  static String getFirstTimeSlotForSport(String sport, [DateTime? date]) {
    final slots = getTimeSlotsForSport(sport, date);
    return slots.isNotEmpty ? slots.first : '08:00';
  }

  /// Verifica si un horario específico está disponible para un deporte
  static bool isTimeSlotAvailableForSport(String sport, String timeSlot, [DateTime? date]) {
    final slots = getTimeSlotsForSport(sport, date);
    return slots.contains(timeSlot);
  }

  /// Método legacy para compatibilidad con código existente
  static List<String> getAllTimeSlots([DateTime? date]) {
    // Por defecto devuelve horarios de pádel/tenis para mantener compatibilidad
    return getTimeSlotsForSport('padel', date);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🏌️ CONFIGURACIÓN ESPECÍFICA DE GOLF (MIGRADA)
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Verifica si Hoyo 10 está suspendido en un horario dado
  static bool isHoyo10Suspended(String timeSlot) {
    const suspensionStart = '10:12';
    const suspensionEnd = '12:48';
    
    final time = DateTime.parse('2024-01-01 $timeSlot:00');
    final suspensionStartTime = DateTime.parse('2024-01-01 $suspensionStart:00');
    final suspensionEndTime = DateTime.parse('2024-01-01 $suspensionEnd:00');
    
    return time.isAtSameMomentAs(suspensionStartTime) || 
           time.isAtSameMomentAs(suspensionEndTime) ||
           (time.isAfter(suspensionStartTime) && time.isBefore(suspensionEndTime));
  }

  /// Configuración específica de Golf
  static const int golfMaxPlayersPerBooking = 4;
  static const int golfMinPlayersPerBooking = 1;
  static const int golfBookingHorizonHours = 48; // vs 72 para tenis/pádel

  // ═══════════════════════════════════════════════════════════════════════════
  // 📱 CONFIGURACIÓN DE LA APP
  // ═══════════════════════════════════════════════════════════════════════════
  static const String appName = 'CGP Reservas';
  static const String appVersion = '1.0.0';
  
  // ═══════════════════════════════════════════════════════════════════════════
  // 🏟️ CONFIGURACIÓN DE RESERVAS
  // ═══════════════════════════════════════════════════════════════════════════
  static const int maxDaysInAdvance = 3;
  static const int maxBookingsPerUserPerDay = 3;
  static const int requiredPlayersPerBooking = 4;
  static const int bookingDurationMinutes = 90;
  static const int childAgeLimit = 25;

  // ═══════════════════════════════════════════════════════════════════════════
  // ⏱️ DURACIONES DE ANIMACIÓN
  // ═══════════════════════════════════════════════════════════════════════════
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  static const Duration fastAnimationDuration = Duration(milliseconds: 150);

  // ═══════════════════════════════════════════════════════════════════════════
  // 🏓 CANCHAS PÁDEL
  // ═══════════════════════════════════════════════════════════════════════════
  static const List<String> courtNames = [
    'PITE',
    'LILEN',
    'PLAIYA',
  ];
  
  static const Map<String, int> courtNumbers = {
    'PITE': 1,
    'LILEN': 2,
    'PLAIYA': 3,
  };
  
  static const Map<String, String> courtColors = {
    'PITE': '#FF6B35',
    'LILEN': '#00C851',
    'PLAIYA': '#8E44AD',
  };

  static const Map<String, String> courtColorsDark = {
    'PITE': '#E55527',
    'LILEN': '#007E33',
    'PLAIYA': '#6C3483',
  };
  
  // ═══════════════════════════════════════════════════════════════════════════
  // 🎾 COLORES DE CANCHAS TENIS
  // ═══════════════════════════════════════════════════════════════════════════
  static const int tennisCourt1Color = 0xFF00BCD4;
  static const int tennisCourt2Color = 0xFF00C851;
  static const int tennisCourt3Color = 0xFF8E44AD;
  static const int tennisCourt4Color = 0xFFE91E63;
  
  // ═══════════════════════════════════════════════════════════════════════════
  // 🏌️ COLORES DE CANCHAS GOLF
  // ═══════════════════════════════════════════════════════════════════════════
  static const int golfCourse1Color = 0xFF4CAF50;
  static const int golfCourse2Color = 0xFF8BC34A;
  static const int golfCourse3Color = 0xFF2E7D32;
  
  // ═══════════════════════════════════════════════════════════════════════════
  // 📅 DÍAS DE LA SEMANA
  // ═══════════════════════════════════════════════════════════════════════════
  static const List<int> allWeekdays = [1, 2, 3, 4, 5, 6, 7];
  static const List<int> weekdaysOnly = [1, 2, 3, 4, 5];
  static const List<int> filialAllowedDays = [2, 3, 4];
  
  static const Map<int, String> weekdayNames = {
    1: 'Lunes', 2: 'Martes', 3: 'Miércoles', 4: 'Jueves',
    5: 'Viernes', 6: 'Sábado', 7: 'Domingo',
  };
  
  static const Map<int, String> weekdayNamesShort = {
    1: 'LUN', 2: 'MAR', 3: 'MIE', 4: 'JUE',
    5: 'VIE', 6: 'SAB', 7: 'DOM',
  };
  
  // ═══════════════════════════════════════════════════════════════════════════
  // 👥 CATEGORÍAS DE USUARIOS Y REGLAS
  // ═══════════════════════════════════════════════════════════════════════════
  
  static const List<String> exemptEmails = [
    'reservaspapudo2@gmail.com',
    'reservaspapudo3@gmail.com',
    'reservaspapudo4@gmail.com',
    'reservaspapudo5@gmail.com',
  ];
  
  // Resto de configuraciones se mantienen igual...
  // [Mantengo el resto del archivo original por brevedad, pero incluirías todo]
  
  // ═══════════════════════════════════════════════════════════════════════════
  // 🗺️ MAPEOS MULTI-DEPORTE
  // ═══════════════════════════════════════════════════════════════════════════
  
  static const Map<String, String> courtIdToName = {
    // PÁDEL
    'padel_court_1': 'PITE',
    'padel_court_2': 'LILEN', 
    'padel_court_3': 'PLAIYA',
    
    // TENIS
    'tennis_court_1': 'Cancha 1',
    'tennis_court_2': 'Cancha 2',
    'tennis_court_3': 'Cancha 3',
    'tennis_court_4': 'Cancha 4',
    
    // GOLF
    'golf_tee_1': 'Hoyo 1-9',
    'golf_tee_10': 'Hoyo 10-18',
    'golf_course_3': 'Campo Práctica',
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // 🔧 MÉTODOS UTILITARIOS
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Obtiene el nombre de la cancha por ID
  static String getCourtName(String courtId) {
    switch (courtId) {
      // PÁDEL - Nombres reales de las canchas
      case 'PITE': return 'PITE';
      case 'LILEN': return 'LILEN';
      case 'PLAIYA': return 'PLAIYA';
      
      // PÁDEL - IDs genéricos (por compatibilidad)
      case 'padel_court_1': return 'PITE';
      case 'padel_court_2': return 'LILEN';
      case 'padel_court_3': return 'PLAIYA';
      
      // TENIS
      case 'tennis_court_1': return 'C.1';  // Actualizado para usar C.1
      case 'tennis_court_2': return 'C.2';  // Actualizado para usar C.2
      case 'tennis_court_3': return 'C.3';  // Actualizado para usar C.3
      case 'tennis_court_4': return 'C.4';  // Actualizado para usar C.4
      
      // GOLF
      case 'golf_tee_1': return 'Hoyo 1';
      case 'golf_tee_10': return 'Hoyo 10';
      
      default: return 'Cancha Desconocida';
    }
  }

  /// Obtiene el deporte basado en el courtId
  static String getCourtSport(String courtId) {
    if (courtId.startsWith('padel')) return 'padel';
    if (courtId.startsWith('tennis')) return 'tennis';
    if (courtId.startsWith('golf')) return 'golf';
    return 'unknown';
  }

  /// Obtiene el color de una cancha por courtId
  static Color getCourtColorById(String courtId) {
    const courtIdToColor = {
      'padel_court_1': 0xFFFF6B35,
      'padel_court_2': 0xFF00C851,
      'padel_court_3': 0xFF8E44AD,
      'tennis_court_1': tennisCourt1Color,
      'tennis_court_2': tennisCourt2Color,
      'tennis_court_3': tennisCourt3Color,
      'tennis_court_4': tennisCourt4Color,
      'golf_tee_1': golfCourse1Color,
      'golf_tee_10': golfCourse2Color,
      'golf_course_3': golfCourse3Color,
    };
    
    final colorInt = courtIdToColor[courtId] ?? corporateNavyBlue;
    return Color(colorInt);
  }

  // Métodos legacy de pádel (mantener compatibilidad)
  static String getCourtColor(String courtName) {
    return courtColors[courtName] ?? '#2196F3';
  }

  static int getCourtNumber(String courtName) {
    return courtNumbers[courtName] ?? 1;
  }
}