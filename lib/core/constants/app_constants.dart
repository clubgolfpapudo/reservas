// lib/core/constants/app_constants.dart - VERSIÓN ACTUALIZADA CON BRANDING CORPORATIVO
import 'package:flutter/material.dart';

abstract class AppConstants {
  // ═══════════════════════════════════════════════════════════════════════════
  // 🏢 BRANDING CORPORATIVO - CLUB DE GOLF PAPUDO (NUEVO)
  // ═══════════════════════════════════════════════════════════════════════════
  
  // Colores del logo oficial
  static const int corporateNavyBlue = 0xFF1B365D;      // Azul marino del logo
  static const int corporateGold = 0xFFFFD700;          // Dorado del logo
  static const int corporateRed = 0xFFDC143C;           // Rojo bandera del logo
  static const int corporateGreen = 0xFF7CB342;         // Verde golf del logo
  static const int corporateWhite = 0xFFFFFFFF;         // Blanco del logo
  static const int corporateLightBlue = 0xFF2C4B7D;     // Azul marino claro para gradientes
  
  // Información corporativa
  static const String clubName = 'Club de Golf Papudo';
  static const String clubYear = '1932';
  static const String systemTitle = 'Reservas y Servicios';
  
  // ═══════════════════════════════════════════════════════════════════════════
  // 🎨 COLORES POR DEPORTE (ACTUALIZADOS CON SEPARACIÓN)
  // ═══════════════════════════════════════════════════════════════════════════
  
  // PÁDEL - Azul diferenciado del corporativo
  static const int padelPrimary = 0xFF2E7AFF;           // Azul pádel (diferente del corporativo)
  static const int padelSecondary = 0xFF1E5AFF;
  
  // TENIS - Tierra batida auténtica
  static const int tennisPrimary = 0xFFD2691E;          // Chocolate/Terracota
  static const int tennisSecondary = 0xFFB8860B;        // DarkGoldenRod
  static const int tennisBackground = 0xFFFFF8DC;       // Cornsilk
  
  // GOLF - Verde corporativo del logo
  static const int golfPrimary = 0xFF7CB342;            // Verde del logo
  static const int golfSecondary = 0xFF558B2F;          // Verde oscuro
  static const int golfBackground = 0xFFF1F8E9;         // Verde muy claro
  
  // ═══════════════════════════════════════════════════════════════════════════
  // INFORMACIÓN DE LA APP (MANTENER ORIGINAL)
  // ═══════════════════════════════════════════════════════════════════════════
  static const String appName = 'CGP Reservas';
  static const String appVersion = '1.0.0';
  
  // ═══════════════════════════════════════════════════════════════════════════
  // CONFIGURACIÓN DE RESERVAS (MANTENER ORIGINAL)
  // ═══════════════════════════════════════════════════════════════════════════
  static const int maxDaysInAdvance = 4;
  static const int maxBookingsPerUserPerDay = 3;
  static const int requiredPlayersPerBooking = 4;
  static const int bookingDurationMinutes = 90;
  static const int childAgeLimit = 25; // Límite edad hijos de socios
  
  // ═══════════════════════════════════════════════════════════════════════════
  // HORARIOS DISPONIBLES - DINÁMICOS POR TEMPORADA (MANTENER ORIGINAL)
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
  // CANCHAS PÁDEL (MANTENER ORIGINAL)
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
  // 🎾 COLORES DE CANCHAS TENIS (ACTUALIZADO)
  // ═══════════════════════════════════════════════════════════════════════════
  static const int tennisCourt1Color = 0xFF00BCD4;      // Cyan (actualizado)
  static const int tennisCourt2Color = 0xFF00C851;      // Verde esmeralda
  static const int tennisCourt3Color = 0xFF8E44AD;      // Púrpura vibrante
  static const int tennisCourt4Color = 0xFFE91E63;      // Rosa/Fucsia (único de tenis)
  
  // ═══════════════════════════════════════════════════════════════════════════
  // 🏌️ COLORES DE CANCHAS GOLF (NUEVO)
  // ═══════════════════════════════════════════════════════════════════════════
  static const int golfCourse1Color = 0xFF4CAF50;       // Verde material
  static const int golfCourse2Color = 0xFF8BC34A;       // Verde claro
  static const int golfCourse3Color = 0xFF2E7D32;       // Verde oscuro
  
  // ═══════════════════════════════════════════════════════════════════════════
  // DÍAS DE LA SEMANA (MANTENER ORIGINAL)
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
  // CATEGORÍAS DE USUARIOS Y REGLAS (MANTENER ORIGINAL)
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
  // URLs Y ENLACES (MANTENER ORIGINAL)
  // ═══════════════════════════════════════════════════════════════════════════
  static const String webViewBaseUrl = 'https://tu-sistema-gas.com';
  static const String supportEmail = 'soporte@cgpreservas.com';
  static const String clubWebsite = 'https://clubgolfpapudo.com';
  static const String whatsappSupport = '+56912345678';
  
  // URLs ACTUALIZADAS DEL PROYECTO
  static const String productionUrl = 'https://paddlepapudo.github.io/cgp_reservas/';
  static const String firebaseProject = 'cgpreservas';
  static const String usersSheetId = '1A-8RvvgkHXUP-985So8CBJvDAj50w58EFML1CJEq2c4';
  
  // ═══════════════════════════════════════════════════════════════════════════
  // CONFIGURACIÓN DE CACHÉ Y SINCRONIZACIÓN (MANTENER ORIGINAL)
  // ═══════════════════════════════════════════════════════════════════════════
  static const Duration cacheExpiration = Duration(minutes: 5);
  static const Duration syncInterval = Duration(minutes: 2);
  static const Duration sessionTimeout = Duration(hours: 8);
  
  // ═══════════════════════════════════════════════════════════════════════════
  // TEXTOS Y MENSAJES (MANTENER ORIGINAL)
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
  // VALIDACIONES (MANTENER ORIGINAL)
  // ═══════════════════════════════════════════════════════════════════════════
  static const int minNameLength = 2;
  static const int maxNameLength = 50;
  static const int minPasswordLength = 6;
  
  // Regex para validaciones
  static const String emailRegex = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
  static const String phoneRegex = r'^\+?[1-9]\d{8,14}$';
  static const String membershipRegex = r'^[A-Z]{1,2}-\d{4,6}$'; // Ej: ST-001234
  
  // ═══════════════════════════════════════════════════════════════════════════
  // CONFIGURACIÓN DE NOTIFICACIONES (MANTENER ORIGINAL)
  // ═══════════════════════════════════════════════════════════════════════════
  static const Duration defaultReminderTime = Duration(hours: 24);
  static const List<int> reminderOptions = [1, 2, 6, 12, 24, 48]; // horas

  // ═══════════════════════════════════════════════════════════════════════════
  // 🔄 MAPEOS MULTI-DEPORTE (ACTUALIZADO CON SEPARACIÓN TOTAL)
  // ═══════════════════════════════════════════════════════════════════════════
  
  // Mapeo de canchas ID -> Nombre  
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
    
    // GOLF (preparado para futura expansión)
    'golf_course_1': 'Hoyo 1-9',
    'golf_course_2': 'Hoyo 10-18',
    'golf_course_3': 'Campo Práctica',
  };

  // Mapeo de canchas Nombre -> ID
  static const Map<String, String> courtNameToId = {
    // PÁDEL
    'PITE': 'padel_court_1',
    'LILEN': 'padel_court_2',
    'PLAIYA': 'padel_court_3',
    
    // TENIS
    'Cancha 1': 'tennis_court_1',
    'Cancha 2': 'tennis_court_2',
    'Cancha 3': 'tennis_court_3',
    'Cancha 4': 'tennis_court_4',
    
    // GOLF
    'Hoyo 1-9': 'golf_course_1',
    'Hoyo 10-18': 'golf_course_2',
    'Campo Práctica': 'golf_course_3',
  };

  // Mapeo de colores por court ID
  static const Map<String, int> courtIdToColor = {
    // PÁDEL
    'padel_court_1': 0xFFFF6B35,  // Naranja intenso
    'padel_court_2': 0xFF00C851,  // Verde esmeralda
    'padel_court_3': 0xFF8E44AD,  // Púrpura vibrante
    
    // TENIS
    'tennis_court_1': tennisCourt1Color,
    'tennis_court_2': tennisCourt2Color,
    'tennis_court_3': tennisCourt3Color,
    'tennis_court_4': tennisCourt4Color,
    
    // GOLF
    'golf_course_1': golfCourse1Color,
    'golf_course_2': golfCourse2Color,
    'golf_course_3': golfCourse3Color,
  };

  // Listas de canchas por deporte
  static const List<String> padelCourts = [
    'padel_court_1',
    'padel_court_2', 
    'padel_court_3',
  ];

  static const List<String> tennisCourts = [
    'tennis_court_1',
    'tennis_court_2',
    'tennis_court_3',
    'tennis_court_4',
  ];

  static const List<String> golfCourses = [
    'golf_course_1',
    'golf_course_2',
    'golf_course_3',
  ];

  // Horarios disponibles para reservas (alias de allTimeSlots)
  static List<String> get availableTimeSlots => getAllTimeSlots();

  // Duraciones de animación
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  static const Duration fastAnimationDuration = Duration(milliseconds: 150);
  
  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTODOS UTILITARIOS (MANTENER ORIGINALES + NUEVOS)
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
  
  /// Obtiene el color de una cancha (HEX string) - PÁDEL LEGACY
  static String getCourtColor(String courtName) {
    return courtColors[courtName] ?? '#2196F3';
  }

  /// ✅ NUEVO: Obtiene el color oscuro de una cancha (HEX string) - PÁDEL LEGACY
  static String getCourtColorDark(String courtName) {
    return courtColorsDark[courtName] ?? '#1976D2';
  }

  /// ✅ NUEVO: Convierte color hex a Color de Flutter - PÁDEL LEGACY
  static Color getCourtColorAsColor(String courtName) {
    final hexColor = getCourtColor(courtName);
    return Color(int.parse(hexColor.substring(1, 7), radix: 16) + 0xFF000000);
  }

  /// ✅ NUEVO: Obtiene color oscuro como Color de Flutter - PÁDEL LEGACY
  static Color getCourtColorDarkAsColor(String courtName) {
    final hexColor = getCourtColorDark(courtName);
    return Color(int.parse(hexColor.substring(1, 7), radix: 16) + 0xFF000000);
  }
  
  /// Obtiene el número de una cancha - PÁDEL LEGACY
  static int getCourtNumber(String courtName) {
    return courtNumbers[courtName] ?? 1;
  }
  
  /// Verifica si un email está exento de restricciones
  static bool isExemptEmail(String email) {
    return exemptEmails.contains(email.toLowerCase());
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🔄 MÉTODOS MULTI-DEPORTE (NUEVOS)
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Obtiene el nombre de la cancha por ID
  static String getCourtName(String courtId) {
    return courtIdToName[courtId] ?? 'Desconocida';
  }

  /// Obtiene el ID de la cancha por nombre
  static String getCourtId(String courtName) {
    return courtNameToId[courtName] ?? 'court_1';
  }

  /// Obtiene el deporte basado en el courtId
  static String getSportFromCourtId(String courtId) {
    if (courtId.startsWith('padel_')) return 'Pádel';
    if (courtId.startsWith('tennis_')) return 'Tenis';
    if (courtId.startsWith('golf_')) return 'Golf';
    return 'Desconocido';
  }
  
  /// Obtiene las canchas para un deporte específico
  static List<String> getCourtsForSport(String sport) {
    switch (sport.toLowerCase()) {
      case 'pádel':
      case 'padel':
        return padelCourts;
      case 'tenis':
      case 'tennis':
        return tennisCourts;
      case 'golf':
        return golfCourses;
      default:
        return [];
    }
  }
  
  /// Obtiene el color primario para un deporte
  static int getPrimaryColorForSport(String sport) {
    switch (sport.toLowerCase()) {
      case 'pádel':
      case 'padel':
        return padelPrimary;
      case 'tenis':
      case 'tennis':
        return tennisPrimary;
      case 'golf':
        return golfPrimary;
      default:
        return corporateNavyBlue; // Default corporativo
    }
  }

  /// Obtiene el color de una cancha por courtId
  static Color getCourtColorById(String courtId) {
    final colorInt = courtIdToColor[courtId] ?? corporateNavyBlue;
    return Color(colorInt);
  }

  class GolfConstants {
    // ✅ CONFIGURACIÓN ESPECÍFICA GOLF
    static const String SPORT_ID = 'golf';
    static const String DISPLAY_NAME = 'Golf';
    static const String DESCRIPTION = 'Campo de golf de 18 hoyos, par 68';
    
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
}