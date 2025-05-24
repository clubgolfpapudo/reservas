// lib/core/constants/app_constants.dart
abstract class AppConstants {
  // ═══════════════════════════════════════════════════════════════════════════
  // INFORMACIÓN DE LA APP
  // ═══════════════════════════════════════════════════════════════════════════
  static const String appName = 'CGP Reservas';
  static const String appVersion = '1.0.0';
  static const String clubName = 'Club de Golf y Pádel';
  
  // ═══════════════════════════════════════════════════════════════════════════
  // CONFIGURACIÓN DE RESERVAS
  // ═══════════════════════════════════════════════════════════════════════════
  static const int maxDaysInAdvance = 4;
  static const int maxBookingsPerUserPerDay = 3;
  static const int requiredPlayersPerBooking = 4;
  static const int bookingDurationMinutes = 90;
  static const int childAgeLimit = 25; // Límite edad hijos de socios
  
  // ═══════════════════════════════════════════════════════════════════════════
  // HORARIOS DISPONIBLES
  // ═══════════════════════════════════════════════════════════════════════════
  static const List<String> allTimeSlots = [
    '09:00',
    '10:30',
    '12:00',
    '13:30',
    '15:00',
    '16:30',
    '18:00',
    '19:30',
  ];
  
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
  
  static const Map<String, String> courtColors = {
    'PITE': '#FF5722',    // Naranja
    'LILEN': '#2196F3',   // Azul
    'PLAIYA': '#4CAF50',  // Verde
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
  static const String clubWebsite = 'https://clubgolfpadel.com';
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
  
  /// Obtiene el color de una cancha
  static String getCourtColor(String courtName) {
    return courtColors[courtName] ?? '#2196F3';
  }
  
  /// Obtiene el número de una cancha
  static int getCourtNumber(String courtName) {
    return courtNumbers[courtName] ?? 1;
  }
  
  /// Verifica si un email está exento de restricciones
  static bool isExemptEmail(String email) {
    return exemptEmails.contains(email.toLowerCase());
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// CONSTANTES DE FIREBASE
// ═══════════════════════════════════════════════════════════════════════════════
abstract class FirebaseConstants {
  // Colecciones
  static const String bookingsCollection = 'bookings';
  static const String courtsCollection = 'courts';
  static const String usersCollection = 'users';
  static const String settingsCollection = 'settings';
  
  // Documentos de configuración
  static const String generalSettingsDoc = 'general';
  static const String schedulesSettingsDoc = 'schedules';
  
  // Campos comunes para queries
  static const String createdAtField = 'metadata.createdAt';
  static const String updatedAtField = 'metadata.updatedAt';
  static const String statusField = 'status';
  static const String dateField = 'dateTime.date';
  static const String timeField = 'dateTime.time';
  static const String courtIdField = 'courtId';
  static const String activePlayersCountField = 'activePlayersCount';
  static const String roleField = 'role';
  static const String isActiveField = 'isActive';
  
  // Valores de estado
  static const String statusComplete = 'complete';
  static const String statusIncomplete = 'incomplete';
  static const String statusCancelled = 'cancelled';
  
  // Valores de rol
  static const String roleAdmin = 'admin';
  static const String roleSocioTitular = 'socio_titular';
  static const String roleHijoSocio = 'hijo_socio';
  static const String roleVisita = 'visita';
  static const String roleFilial = 'filial';
}

// ═══════════════════════════════════════════════════════════════════════════════
// CONSTANTES DE RUTAS
// ═══════════════════════════════════════════════════════════════════════════════
abstract class RouteConstants {
  static const String splash = '/';
  static const String home = '/home';
  static const String login = '/login';
  static const String register = '/register';
  static const String booking = '/booking';
  static const String bookingWebView = '/booking/webview';
  static const String bookingConfirmation = '/booking/confirmation';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String dateSelection = '/date-selection';
  static const String userManagement = '/admin/users';
  static const String bookingManagement = '/admin/bookings';
}