// lib/core/constants/app_constants.dart - VERSIÓN CORREGIDA
import 'package:flutter/material.dart'; // ✅ AGREGAR este import

abstract class AppConstants {
  // ═══════════════════════════════════════════════════════════════════════════
  // INFORMACIÓN DE LA APP
  // ═══════════════════════════════════════════════════════════════════════════
  static const String appName = 'CGP Reservas';
  static const String appVersion = '1.0.0';
  static const String clubName = 'Club de Golf Papudo';
  
  // ═══════════════════════════════════════════════════════════════════════════
  // CONFIGURACIÓN DE RESERVAS
  // ═══════════════════════════════════════════════════════════════════════════
  static const int maxDaysInAdvance = 4;
  static const int maxBookingsPerUserPerDay = 3;
  static const int requiredPlayersPerBooking = 4;
  static const int bookingDurationMinutes = 90;
  static const int childAgeLimit = 25; // Límite edad hijos de socios
  
  // ═══════════════════════════════════════════════════════════════════════════
  // HORARIOS DISPONIBLES - DINÁMICOS POR TEMPORADA
  // ═══════════════════════════════════════════════════════════════════════════
  
  // Horarios base (invierno)
  static const List<String> winterTimeSlots = [
    '09:00',
    '10:30',
    '12:00',
    '13:30',
    '15:00',
    '16:30',
    '18:00',
    '19:30',
  ];
  
  // Horarios extendidos (verano) - incluye 21:00
  static const List<String> summerTimeSlots = [
    '09:00',
    '10:30',
    '12:00',
    '13:30',
    '15:00',
    '16:30',
    '18:00',
    '19:30',
    '21:00',  // ← NUEVO horario de verano
  ];
  
  // ✅ MÉTODO DINÁMICO: Obtiene horarios según temporada
  static List<String> getAllTimeSlots([DateTime? date]) {
    date ??= DateTime.now();
    final month = date.month;
    
    // Verano en Chile: octubre a marzo
    final isSummer = (month >= 10 || month <= 3);
    
    return isSummer ? summerTimeSlots : winterTimeSlots;
  }
  
  // Mantener compatibilidad con código existente
  static const List<String> allTimeSlots = winterTimeSlots;
  
  // Horarios restringidos para visitas
  static const List<String> visitTimeSlots = [
    '09:00',
    '10:30',
    '15:00',
    '16:30',
  ];
  
  // Horarios restringidos para filial
  static const List<String> filialTimeSlots = [
    '09:00',
    '10:30',
    '12:00',
    '13:30',
  ];
  
  // ═══════════════════════════════════════════════════════════════════════════
  // CANCHAS
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
  
  // ✅ COLORES ACTUALIZADOS CON PROPUESTA
  static const Map<String, String> courtColors = {
    'PITE': '#FF6B35',     // 🟠 Naranja Intenso
    'LILEN': '#00C851',    // 🟢 Verde Esmeralda  
    'PLAIYA': '#8E44AD',   // 🟣 Púrpura Vibrante
  };

  // ✅ COLORES OSCUROS PARA SOMBRAS/BORDES
  static const Map<String, String> courtColorsDark = {
    'PITE': '#E55527',     // Naranja más oscuro
    'LILEN': '#007E33',    // Verde más oscuro
    'PLAIYA': '#6C3483',   // Púrpura más oscuro
  };
  
  // ═══════════════════════════════════════════════════════════════════════════
  // DÍAS DE LA SEMANA
  // ═══════════════════════════════════════════════════════════════════════════
  static const List<int> allWeekdays = [1, 2, 3, 4, 5, 6, 7]; // Lun-Dom
  static const List<int> weekdaysOnly = [1, 2, 3, 4, 5];      // Lun-Vie
  static const List<int> filialAllowedDays = [2, 3, 4];       // Mar-Jue
  
  static const Map<int, String> weekdayNames = {
    1: 'Lunes',
    2: 'Martes',
    3: 'Miércoles',
    4: 'Jueves',
    5: 'Viernes',
    6: 'Sábado',
    7: 'Domingo',
  };
  
  static const Map<int, String> weekdayNamesShort = {
    1: 'LUN',
    2: 'MAR',
    3: 'MIE',
    4: 'JUE',
    5: 'VIE',
    6: 'SAB',
    7: 'DOM',
  };
  
  // ═══════════════════════════════════════════════════════════════════════════
  // CATEGORÍAS DE USUARIOS Y REGLAS
  // ═══════════════════════════════════════════════════════════════════════════
  
  // Correos exentos de restricciones (del sistema original)
  static const List<String> exemptEmails = [
    'reservaspapudo2@gmail.com',
    'reservaspapudo3@gmail.com',
    'reservaspapudo4@gmail.com',
    'reservaspapudo5@gmail.com',
  ];
  
  // Configuración de pagos por categoría
  static const Map<String, bool> categoryPaymentRequired = {
    'admin': false,
    'socio_titular': false,
    'hijo_socio': false,
    'visita': true,
    'filial': true,
  };
  
  // Tarifas por categoría (en pesos chilenos)
  static const Map<String, double> categoryRates = {
    'admin': 0.0,
    'socio_titular': 0.0,
    'hijo_socio': 0.0,
    'visita': 15000.0,      // $15.000 por hora
    'filial': 12000.0,      // $12.000 por hora
  };
  
  // Horarios permitidos por categoría
  static const Map<String, List<String>> categoryAllowedTimes = {
    'admin': allTimeSlots,
    'socio_titular': allTimeSlots,
    'hijo_socio': allTimeSlots,
    'visita': visitTimeSlots,
    'filial': filialTimeSlots,
  };
  
  // Días permitidos por categoría
  static const Map<String, List<int>> categoryAllowedDays = {
    'admin': allWeekdays,
    'socio_titular': allWeekdays,
    'hijo_socio': allWeekdays,
    'visita': weekdaysOnly,
    'filial': filialAllowedDays,
  };
  
  // ═══════════════════════════════════════════════════════════════════════════
  // URLs Y ENLACES
  // ═══════════════════════════════════════════════════════════════════════════
  static const String webViewBaseUrl = 'https://tu-sistema-gas.com';
  static const String supportEmail = 'soporte@cgpreservas.com';
  static const String clubWebsite = 'https://clubgolfpapudo.com';
  static const String whatsappSupport = '+56912345678';
  
  // ═══════════════════════════════════════════════════════════════════════════
  // CONFIGURACIÓN DE CACHÉ Y SINCRONIZACIÓN
  // ═══════════════════════════════════════════════════════════════════════════
  static const Duration cacheExpiration = Duration(minutes: 5);
  static const Duration syncInterval = Duration(minutes: 2);
  static const Duration sessionTimeout = Duration(hours: 8);
  
  // ═══════════════════════════════════════════════════════════════════════════
  // TEXTOS Y MENSAJES
  // ═══════════════════════════════════════════════════════════════════════════
  static const String welcomeMessage = 'Bienvenido a CGP Reservas';
  static const String loadingMessage = 'Cargando reservas...';
  static const String noConnectionMessage = 'Sin conexión a internet';
  static const String errorMessage = 'Ha ocurrido un error. Intenta nuevamente.';
  
  // Mensajes por categoría
  static const Map<String, String> categoryWelcomeMessages = {
    'admin': 'Panel de Administración',
    'socio_titular': 'Bienvenido, Socio',
    'hijo_socio': 'Bienvenido, Familiar',
    'visita': 'Bienvenido, Visitante',
    'filial': 'Bienvenido, Filial',
  };
  
  // ═══════════════════════════════════════════════════════════════════════════
  // VALIDACIONES
  // ═══════════════════════════════════════════════════════════════════════════
  static const int minNameLength = 2;
  static const int maxNameLength = 50;
  static const int minPasswordLength = 6;
  
  // Regex para validaciones
  static const String emailRegex = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
  static const String phoneRegex = r'^\+?[1-9]\d{8,14}$';
  static const String membershipRegex = r'^[A-Z]{1,2}-\d{4,6}$'; // Ej: ST-001234
  
  // ═══════════════════════════════════════════════════════════════════════════
  // CONFIGURACIÓN DE NOTIFICACIONES
  // ═══════════════════════════════════════════════════════════════════════════
  static const Duration defaultReminderTime = Duration(hours: 24);
  static const List<int> reminderOptions = [1, 2, 6, 12, 24, 48]; // horas

  // ═══════════════════════════════════════════════════════════════════════════
  // CONSTANTES PARA DISEÑO COMPACTO (NUEVAS)
  // ═══════════════════════════════════════════════════════════════════════════
  
  // Mapeo de canchas ID -> Nombre  
  static const Map<String, String> courtIdToName = {
    'court_1': 'PITE',
    'court_2': 'LILEN', 
    'court_3': 'PLAIYA',
  };

  // Mapeo de canchas Nombre -> ID
  static const Map<String, String> courtNameToId = {
    'PITE': 'court_1',
    'LILEN': 'court_2',
    'PLAIYA': 'court_3',
  };

  // Horarios disponibles para reservas (alias de allTimeSlots)
  static List<String> get availableTimeSlots => getAllTimeSlots();

  // Duraciones de animación
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  static const Duration fastAnimationDuration = Duration(milliseconds: 150);
  
  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTODOS UTILITARIOS
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Obtiene los horarios permitidos para una categoría de usuario
  static List<String> getAllowedTimeSlotsForRole(String role) {
    return categoryAllowedTimes[role] ?? allTimeSlots;
  }
  
  /// Obtiene los días permitidos para una categoría de usuario
  static List<int> getAllowedDaysForRole(String role) {
    return categoryAllowedDays[role] ?? allWeekdays;
  }
  
  /// Verifica si una categoría debe pagar
  static bool doesRoleRequirePayment(String role) {
    return categoryPaymentRequired[role] ?? false;
  }
  
  /// Obtiene la tarifa para una categoría
  static double getRateForRole(String role) {
    return categoryRates[role] ?? 0.0;
  }
  
  /// Obtiene el nombre del día de la semana
  static String getWeekdayName(int weekday, {bool short = false}) {
    final names = short ? weekdayNamesShort : weekdayNames;
    return names[weekday] ?? '';
  }
  
  /// Obtiene el color de una cancha (HEX string)
  static String getCourtColor(String courtName) {
    return courtColors[courtName] ?? '#2196F3';
  }

  /// ✅ NUEVO: Obtiene el color oscuro de una cancha (HEX string)
  static String getCourtColorDark(String courtName) {
    return courtColorsDark[courtName] ?? '#1976D2';
  }

  /// ✅ NUEVO: Convierte color hex a Color de Flutter
  static Color getCourtColorAsColor(String courtName) {
    final hexColor = getCourtColor(courtName);
    return Color(int.parse(hexColor.substring(1, 7), radix: 16) + 0xFF000000);
  }

  /// ✅ NUEVO: Obtiene color oscuro como Color de Flutter
  static Color getCourtColorDarkAsColor(String courtName) {
    final hexColor = getCourtColorDark(courtName);
    return Color(int.parse(hexColor.substring(1, 7), radix: 16) + 0xFF000000);
  }
  
  /// Obtiene el número de una cancha
  static int getCourtNumber(String courtName) {
    return courtNumbers[courtName] ?? 1;
  }
  
  /// Verifica si un email está exento de restricciones
  static bool isExemptEmail(String email) {
    return exemptEmails.contains(email.toLowerCase());
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTODOS NUEVOS PARA DISEÑO COMPACTO
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Obtiene el nombre de la cancha por ID
  static String getCourtName(String courtId) {
    return courtIdToName[courtId] ?? 'Desconocida';
  }

  /// Obtiene el ID de la cancha por nombre
  static String getCourtId(String courtName) {
    return courtNameToId[courtName] ?? 'court_1';
  }
}