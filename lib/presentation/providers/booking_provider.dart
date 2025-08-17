/// lib/presentation/providers/booking_provider.dart
/// 
/// PROPÓSITO:
/// Provider central que gestiona todo el estado y lógica de negocio relacionada con reservas.
/// Este es el cerebro del sistema de reservas que orquesta validaciones complejas de conflictos,
/// estado reactivo, integración con múltiples servicios, y operaciones CRUD con emails automáticos.
/// 
/// RESPONSABILIDADES PRINCIPALES:
/// 1. **Estado de Reservas**: Gestiona lista de reservas filtradas por fecha/cancha
/// 2. **Validación de Conflictos**: Algoritmo complejo para detectar conflictos de jugadores
/// 3. **Navegación de Fechas**: Manejo de fechas disponibles con reglas de 72 horas
/// 4. **Operaciones CRUD**: Crear, leer, actualizar, eliminar reservas con validaciones
/// 5. **Sistema de Emails**: Orquesta envío automático de confirmaciones y cancelaciones
/// 6. **Estado de UI**: Proporciona datos reactivos para widgets de reservas
/// 
/// INTEGRACIONES:
/// - FirestoreService: Persistencia de datos en tiempo real
/// - EmailService: Envío automático de notificaciones
/// - ScheduleService: Lógica de horarios y fechas inteligente
/// - UserService: Auto-completado de usuario actual

import 'dart:async';
import 'package:flutter/material.dart';

// Entities
import '../../domain/entities/court.dart';
import '../../domain/entities/booking.dart';

// Services
import '../../core/services/firebase_user_service.dart';
import '../../core/services/schedule_service.dart';
import '../../core/services/user_service.dart';
import '../../data/services/email_service.dart';
import '../../data/services/firestore_service.dart';

// Constants
import '../../core/constants/app_constants.dart';

/// Provider principal para gestión de estado de reservas
/// 
/// Extiende ChangeNotifier para proporcionar estado reactivo a la UI.
/// Maneja toda la lógica de negocio relacionada con reservas incluyendo
/// validaciones de conflictos complejas, estados de carga, y sistema de emails.
class BookingProvider extends ChangeNotifier {
  // ============================================================================
  // ESTADO PRIVADO
  // ============================================================================
  
  /// Lista de canchas disponibles cargadas desde configuración
  List<Court> _courts = [];
  /// Lista de todas las reservas cargadas desde Firebase
  List<Booking> _bookings = [];
  /// ID de la cancha actualmente seleccionada (ej: "padel_court_1")
  String _selectedCourtId = 'padel_court_1';
  /// Fecha actualmente seleccionada para mostrar reservas  
  DateTime _selectedDate = DateTime.now();
  /// Estado de carga global del provider
  bool _isLoading = false;
  /// Mensaje de error actual (null si no hay errores)
  String? _error;
  
  /// Lista de fechas disponibles para navegación (4 días por defecto)
  List<DateTime> _availableDates = [];
  /// Índice actual en la lista de fechas disponibles
  int _currentDateIndex = 0;
  
  /// Estado específico para operaciones de envío de emails
  bool _isSendingEmails = false;
  
  // Streams subscriptions para limpiar recursos
  StreamSubscription? _courtsSubscription;
  StreamSubscription? _bookingsSubscription;
  
  // ============================================================================
  // GETTERS PÚBLICOS - Acceso de solo lectura al estado
  // ============================================================================
  
  /// Todas las canchas disponibles
  List<Court> get courts => _courts;
  /// Todas las reservas cargadas desde Firebase
  List<Booking> get bookings => _bookings;
  /// ID de la cancha actualmente seleccionada
  String get selectedCourtId => _selectedCourtId;
  /// Fecha actualmente seleccionada
  DateTime get selectedDate => _selectedDate;
  /// Estado de carga global
  bool get isLoading => _isLoading;
  /// Mensaje de error actual
  String? get error => _error;
  
  /// Lista de fechas disponibles para navegación
  List<DateTime> get availableDates => _availableDates;
  /// Índice actual en fechas disponibles
  int get currentDateIndex => _currentDateIndex;
  /// Total de días disponibles para navegación  
  int get totalAvailableDays => _availableDates.length;
  
  /// Estado específico de envío de emails
  bool get isSendingEmails => _isSendingEmails;
  
  // ============================================================================
  // COMPUTED PROPERTIES - Propiedades calculadas dinámicamente
  // ============================================================================
  
  /// Obtiene la cancha actualmente seleccionada
  /// 
  /// @return Court seleccionada o null si no se encuentra
  Court? get selectedCourt {
    try {
      return _courts.firstWhere((court) => court.id == _selectedCourtId);
    } catch (e) {
      return null;
    }
  }
  
  /// Nombre legible de la cancha seleccionada
  /// 
  /// @return String con nombre de cancha o "Cancha" por defecto
  String get selectedCourtName {
    return selectedCourt?.name ?? 'Cancha';
  }

  /// Lista filtrada de reservas para la fecha y cancha seleccionadas
  /// 
  /// Aplica filtros basados en:
  /// - Cancha seleccionada (_selectedCourtId)
  /// - Fecha seleccionada formateada para Firebase
  /// 
  /// @debug Incluye logs detallados para debugging
  /// @return Lista de reservas filtradas
  List<Booking> get currentBookings {
    final selectedDateStr = _formatDateForFirebase(_selectedDate);
    
    print('🔍 DEBUG RESERVAS FILTRADAS:');
    print('   Court seleccionada: $_selectedCourtId');
    print('   Fecha seleccionada: $selectedDateStr ($_selectedDate)');
    print('   Total bookings en _bookings: ${_bookings.length}');
    
    // 🔥 DEBUG: Mostrar TODAS las reservas primero
    for (var booking in _bookings) {
      print('   📋 ALL: ${booking.courtId} | ${booking.date} | ${booking.timeSlot} | ${booking.players.length} jugadores');
    }
    
    final filteredBookings = _bookings.where((booking) => 
      booking.courtId == _selectedCourtId && 
      booking.date == selectedDateStr
    ).toList();
    
    print('   Bookings filtradas: ${filteredBookings.length}');
    
    for (var booking in filteredBookings) {
      print('   ✅ FILTERED: ${booking.timeSlot} - ${booking.players.length} jugadores - ${booking.status}');
    }
    
    return filteredBookings;
  }

  /// Obtiene todas las reservas para una fecha específica (todas las canchas)
  /// 
  /// Utilizado para validaciones de conflictos entre canchas.
  /// No filtra por cancha, solo por fecha.
  /// 
  /// @param date Fecha para filtrar reservas
  /// @return Lista de reservas para la fecha especificada
  /// @debug Incluye logs para debugging de conflictos
  List<Booking> getAllBookingsForDate(DateTime date) {
    final dateStr = _formatDateForFirebase(date);
    final bookingsForDate = _bookings.where((booking) => booking.date == dateStr).toList();
    
    print('🔍 getAllBookingsForDate para $dateStr:');
    print('   Total en _bookings: ${_bookings.length}');
    print('   Para fecha específica: ${bookingsForDate.length}');
    
    for (var booking in bookingsForDate) {
      print('   📋 ${booking.courtId} ${booking.timeSlot} (${booking.players.length} jugadores)');
    }
    
    return bookingsForDate;
  }
  
  // ============================================================================
  // VALIDACIÓN DE CONFLICTOS
  // ============================================================================

  /// **MÉTODO PRINCIPAL** - Valida si se puede crear una reserva
  /// 
  /// Implementa el algoritmo completo de validación de conflictos:
  /// 1. Verifica duplicados exactos (misma cancha, fecha, hora)
  /// 2. Detecta conflictos de jugadores entre diferentes canchas
  /// 3. Maneja casos especiales (usuarios VISITA)
  /// 4. Aplica reglas de negocio específicas del club
  /// 
  /// REGLAS IMPLEMENTADAS:
  /// - No puede haber dos reservas en el mismo slot de la misma cancha
  /// - Un jugador regular no puede estar en múltiples canchas al mismo tiempo
  /// - Usuarios VISITA (PADEL1-4 VISITA) pueden estar en múltiples reservas
  /// - Comparación de nombres case-insensitive con limpieza de espacios
  /// 
  /// @param courtId ID de la cancha (ej: "padel_court_1")
  /// @param date Fecha en formato YYYY-MM-DD
  /// @param timeSlot Hora en formato HH:MM
  /// @param playerNames Lista de nombres de jugadores a validar
  /// @return ValidationResult con resultado y razón si no es válida
  /// @debug Incluye logs extensivos para debugging paso a paso
  ValidationResult canCreateBooking(String courtId, String date, String timeSlot, List<String> playerNames) {
    print('\n🔍 VALIDACIÓN COMPLETA - INICIO');
    print('   Court: $courtId');
    print('   Fecha: $date'); 
    print('   Hora: $timeSlot');
    print('   Jugadores: ${playerNames.join(", ")}');
    print('   Total reservas en memoria: ${_bookings.length}');

    // 1. Verificar reserva duplicada exacta (mismo slot, misma cancha)
    final exactDuplicates = _bookings.where(
      (booking) => 
        booking.courtId == courtId && 
        booking.date == date && 
        booking.timeSlot == timeSlot,
    ).toList();

    print('🔍 Verificando duplicados exactos: ${exactDuplicates.length} encontrados');
    
    if (exactDuplicates.isNotEmpty) {
      final existingBooking = exactDuplicates.first;
      print('❌ VALIDACIÓN: Reserva duplicada detectada');
      print('   Jugadores existentes: ${existingBooking.players.map((p) => p.name).join(", ")}');
      return ValidationResult(
        isValid: false, 
        reason: 'Ya existe una reserva para este horario en esta cancha.'
      );
    }

    print('✅ Sin duplicados exactos, verificando conflictos de jugadores...');

    // 2. Verificar conflictos de jugadores en otras canchas
    final allBookingsForDate = getAllBookingsForDate(DateTime.parse(date));
    final conflictingBookings = allBookingsForDate.where((booking) => 
      booking.timeSlot == timeSlot && booking.courtId != courtId
    ).toList();

    print('🔍 Reservas en otras canchas para $timeSlot: ${conflictingBookings.length}');

    for (final booking in conflictingBookings) {
      print('   📋 Verificando ${booking.courtId}: ${booking.players.map((p) => p.name).join(", ")}');
      
      for (final existingPlayer in booking.players) {
        for (final newPlayerName in playerNames) {
          // Ignorar jugadores especiales VISITA
          if (_isSpecialVisitPlayer(newPlayerName) || _isSpecialVisitPlayer(existingPlayer.name)) {
            print('   ⚠️ Jugador VISITA detectado, omitiendo validación: $newPlayerName o ${existingPlayer.name}');
            continue;
          }

          // Verificar conflicto de nombre (case-insensitive y limpio)
          if (_playersMatch(existingPlayer.name, newPlayerName)) {
            print('❌ VALIDACIÓN: Conflicto detectado!');
            print('   Jugador: ${existingPlayer.name}');
            print('   Ya reservado en: ${booking.courtId} a las $timeSlot');
            return ValidationResult(
              isValid: false,
              reason: 'El jugador "${existingPlayer.name}" ya tiene una reserva a las $timeSlot en ${_getCourtDisplayName(booking.courtId)}.'
            );
          }
        }
      }
    }

    print('✅ VALIDACIÓN: Sin conflictos detectados - reserva permitida');
    print('🔍 VALIDACIÓN COMPLETA - FIN\n');
    return ValidationResult(isValid: true, reason: null);
  }

  /// Verifica si un jugador es especial (tipo VISITA)
  /// 
  /// Los usuarios VISITA pueden estar en múltiples reservas simultáneas.
  /// Formatos reconocidos: PADEL1 VISITA, PADEL2 VISITA, etc.
  /// 
  /// @param playerName Nombre del jugador a verificar
  /// @return true si es usuario VISITA, false en caso contrario
  bool _isSpecialVisitPlayer(String playerName) {
    final cleanName = playerName.trim().toUpperCase();
    return ['PADEL1 VISITA', 'PADEL2 VISITA', 'PADEL3 VISITA', 'PADEL4 VISITA']
        .contains(cleanName);
  }

  /// Compara nombres de jugadores con limpieza y case-insensitive
  /// 
  /// Implementa comparación robusta que:
  /// - Elimina espacios en blanco
  /// - Convierte a mayúsculas
  /// - Maneja variaciones de nombres
  /// 
  /// @param name1 Primer nombre a comparar
  /// @param name2 Segundo nombre a comparar
  /// @return true si los nombres coinciden, false en caso contrario
  bool _playersMatch(String name1, String name2) {
    final clean1 = name1.trim().toUpperCase();
    final clean2 = name2.trim().toUpperCase();
    return clean1 == clean2;
  }

  /// Obtiene nombre amigable de cancha para mostrar en mensajes
  /// 
  /// Convierte IDs técnicos a nombres legibles para usuarios.
  /// 
  /// @param courtId ID técnico de la cancha
  /// @return Nombre legible de la cancha
  String _getCourtDisplayName(String courtId) {
    switch (courtId) {
      // PÁDEL
      case 'padel_court_1': return 'PITE';
      case 'padel_court_2': return 'LILEN';
      case 'padel_court_3': return 'PLAIYA';
      // TENIS
      case 'tennis_court_1': return 'CANCHA_1';
      case 'tennis_court_2': return 'CANCHA_2';
      case 'tennis_court_3': return 'CANCHA_3';
      case 'tennis_court_4': return 'CANCHA_4';
      default: return courtId;
    }
  }
  
  // ============================================================================
  // ESTADÍSTICAS PARA UI - Cálculos para widgets compactos
  // ============================================================================

  /// Calcula estadísticas basadas solo en horarios visibles en pantalla
  /// 
  /// Optimización para widgets compactos que solo muestran ciertos horarios.
  /// Evita procesar horarios no visibles para mejor performance.
  /// 
  /// @param visibleTimeSlots Lista de horarios actualmente visibles en UI
  /// @return Map con conteos de: complete, incomplete, available
  Map<String, int> getStatsForVisibleTimeSlots(List<String> visibleTimeSlots) {
    int completeCount = 0;
    int incompleteCount = 0;
    int availableCount = 0;
    
    for (final timeSlot in visibleTimeSlots) {
      final booking = getBookingForTimeSlot(timeSlot);
      
      if (booking == null) {
        availableCount++;
      } else if (booking.status == BookingStatus.complete) {
        completeCount++;
      } else if (booking.status == BookingStatus.incomplete) {
        incompleteCount++;
      }
    }
    
    return {
      'complete': completeCount,
      'incomplete': incompleteCount,
      'available': availableCount,
    };
  }

  // Métodos de conveniencia que mantienen la API existente
  int getCompleteBookingsCount(List<String> visibleTimeSlots) {
    return getStatsForVisibleTimeSlots(visibleTimeSlots)['complete'] ?? 0;
  }

  int getIncompleteBookingsCount(List<String> visibleTimeSlots) {
    return getStatsForVisibleTimeSlots(visibleTimeSlots)['incomplete'] ?? 0;
  }

  int getAvailableBookingsCount(List<String> visibleTimeSlots) {
    return getStatsForVisibleTimeSlots(visibleTimeSlots)['available'] ?? 0;
  }

  /// NUEVO: Estado de emails para mostrar en UI
  String get emailStatus {
    if (_isSendingEmails) {
      return 'Enviando confirmaciones...';
    }
    return '';
  }
  
  // ============================================================================
  // MÉTODOS AUXILIARES - Búsqueda y verificación de slots
  // ============================================================================

  /// **MÉTODO CRÍTICO** - Busca reserva específica para un horario
  /// 
  /// Busca en las reservas filtradas (currentBookings) una reserva
  /// que coincida exactamente con el timeSlot especificado.
  /// 
  /// @param timeSlot Horario a buscar en formato HH:MM
  /// @return Booking encontrada o null si no existe
  Booking? getBookingForTimeSlot(String timeSlot) {
    for (var booking in currentBookings) {
      if (booking.timeSlot == timeSlot) {
        return booking;
      }
    }
    return null;
  }

  /// Verifica si un slot de tiempo está disponible
  /// 
  /// @param timeSlot Horario a verificar
  /// @return true si está disponible, false si está ocupado
  bool isTimeSlotAvailable(String timeSlot) {
    return getBookingForTimeSlot(timeSlot) == null;
  }

  // ============================================================================
  // INICIALIZACIÓN - Setup del provider
  // ============================================================================
  
  /// Constructor que inicia la inicialización automática
  BookingProvider() {
    _initializeProvider();
  }
  
  /// Inicializa el provider con todos los datos necesarios
  /// 
  /// Secuencia de inicialización:
  /// 1. Genera fechas disponibles usando ScheduleService
  /// 2. Carga canchas desde configuración estática
  /// 3. Carga reservas desde Firebase con streams en tiempo real
  /// 4. Inicializa usuario actual para auto-completado
  Future<void> _initializeProvider() async {
    print('🔥 Inicializando BookingProvider con Firebase...');
    _generateAvailableDates();
    await _loadCourts();
    await _loadBookings();
    
    // 🔥 AGREGAR ESTA LÍNEA:
    await initializeCurrentUser();
  }

  /// Inicializa datos del usuario actual para auto-completado
  /// 
  /// Obtiene email y nombre del usuario actual desde UserService
  /// y los cachea para uso en formularios de reserva.
  /// 
  /// @throws No propaga errores, usa fallback en caso de fallo
  Future<void> initializeCurrentUser() async {
    try {
      final email = await UserService.getCurrentUserEmail();
      final name = await UserService.getCurrentUserName();
      
      print('🔥 Auto-completando primer jugador: $name ($email)');
      
      // Exponer usuario actual para formularios
      _currentUserEmail = email;
      _currentUserName = name;
      
      notifyListeners();
    } catch (e) {
      print('❌ Error inicializando usuario actual: $e');
    }
  }

  // Agregar estas propiedades privadas al inicio de la clase
  String? _currentUserEmail;
  String? _currentUserName;

  // Agregar estos getters públicos
  String? get currentUserEmail => _currentUserEmail;
  String? get currentUserName => _currentUserName;
  bool get hasCurrentUser => _currentUserEmail != null && _currentUserName != null;

  /// Genera lista de fechas disponibles usando ScheduleService
  /// 
  /// Utiliza ScheduleService para determinar la fecha inicial inteligente
  /// basada en horarios del club y genera 4 días consecutivos.
  /// 
  /// Configuración:
  /// - 4 días disponibles por defecto
  /// - Fecha inicial determinada por ScheduleService (puede ser hoy o mañana)
  /// - Índice inicial en 0
  void _generateAvailableDates() {
    _availableDates.clear();
    
    // 🔥 USAR FECHA INTELIGENTE en lugar de DateTime.now()
    final startDate = ScheduleService.getDefaultDisplayDate();
    
    print('🔥 ScheduleService determinó fecha de inicio: $startDate');
    final debugInfo = ScheduleService.getScheduleDebugInfo();
    print('🔥 Info debug horarios: $debugInfo');
    
    for (int i = 0; i < 4; i++) {
      final date = DateTime(startDate.year, startDate.month, startDate.day + i);
      _availableDates.add(date);
    }
    
    // Establecer fecha inicial como la determinada por ScheduleService
    _selectedDate = _availableDates[0];
    _currentDateIndex = 0;
    
    print('✅ Fechas disponibles generadas: ${_availableDates.length}');
    print('✅ Fecha seleccionada inicial: $_selectedDate');
  }
  
  // Helper para formatear fechas
  String _formatDate(DateTime date) {
    const months = [
      '', 'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    
    return '${date.day} de ${months[date.month]}';
  }

  // 🔥 HELPER para formatear fecha para Firebase (YYYY-MM-DD)
  String _formatDateForFirebase(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
  
  // ============================================================================
  // CARGA DE DATOS DESDE FIREBASE - SIN CAMBIOS
  // ============================================================================
  
  /// Carga canchas desde configuración estática
  /// 
  /// Crea objetos Court con configuración hardcodeada para las 3 canchas
  /// del club. En una implementación futura podría cargar desde Firebase.
  /// 
  /// Canchas configuradas:
  /// - PITE (padel_court_1)
  /// - LILEN (padel_court_2) 
  /// - PLAIYA (padel_court_3)
  /// 
  /// @throws Captura errores y los convierte en _setError()
  Future<void> _loadCourts() async {
    try {
      _setLoading(true);
      
      final now = DateTime.now();
      _courts = [
        // PÁDEL - Mantener IDs originales
        Court(
          id: 'padel_court_1',  // 🔧 CAMBIAR: era 'court_1'
          name: 'PITE',
          description: 'Cancha de pádel PITE',
          number: 1,
          displayOrder: 1,
          status: 'active',
          isAvailableForBooking: true,
          createdAt: now,
          updatedAt: now,
        ),
        Court(
          id: 'padel_court_2',  // 🔧 CAMBIAR: era 'court_2'
          name: 'LILEN',
          description: 'Cancha de pádel LILEN',
          number: 2,
          displayOrder: 2,
          status: 'active',
          isAvailableForBooking: true,
          createdAt: now,
          updatedAt: now,
        ),
        Court(
          id: 'padel_court_3',  // 🔧 CAMBIAR: era 'court_3'
          name: 'PLAIYA',
          description: 'Cancha de pádel PLAIYA',
          number: 3,
          displayOrder: 3,
          status: 'active',
          isAvailableForBooking: true,
          createdAt: now,
          updatedAt: now,
        ),
        // TENIS - Nuevos IDs únicos
        Court(
          id: 'tennis_court_1',  // 🔧 CAMBIAR: era 'court_4'
          name: 'CANCHA_1',
          description: 'Cancha de tenis 1',
          number: 4,
          displayOrder: 4,
          status: 'active',
          isAvailableForBooking: true,
          createdAt: now,
          updatedAt: now,
        ),
        Court(
          id: 'tennis_court_2',  // 🔧 NUEVO
          name: 'CANCHA_2',
          description: 'Cancha de tenis 2',
          number: 5,
          displayOrder: 5,
          status: 'active',
          isAvailableForBooking: true,
          createdAt: now,
          updatedAt: now,
        ),
        Court(
          id: 'tennis_court_3',  // 🔧 NUEVO
          name: 'CANCHA_3',
          description: 'Cancha de tenis 3',
          number: 6,
          displayOrder: 6,
          status: 'active',
          isAvailableForBooking: true,
          createdAt: now,
          updatedAt: now,
        ),
        Court(
          id: 'tennis_court_4',  // 🔧 NUEVO
          name: 'CANCHA_4',
          description: 'Cancha de tenis 4',
          number: 7,
          displayOrder: 7,
          status: 'active',
          isAvailableForBooking: true,
          createdAt: now,
          updatedAt: now,
        ),
      ];
      
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('Error cargando canchas: $e');
    }
  }
  
  /// Carga reservas desde Firebase con streams en tiempo real
  /// 
  /// Configura un stream que escucha cambios en las reservas de la fecha
  /// seleccionada y actualiza automáticamente la UI cuando hay cambios.
  /// 
  /// Características:
  /// - Stream en tiempo real de Firebase
  /// - Filtrado por fecha seleccionada
  /// - Actualización automática de UI
  /// - Logs detallados para debugging
  /// - Manejo robusto de errores
  /// 
  /// @sideEffect Actualiza _bookings y notifica listeners automáticamente
  Future<void> _loadBookings() async {
    try {
      print('📋 Cargando reservas desde Firestore...');
      
      // Cancelar suscripción anterior si existe
      _bookingsSubscription?.cancel();
      
      // 🔥 CARGAR RESERVAS DE LA FECHA SELECCIONADA
      _bookingsSubscription = FirestoreService.getBookingsByDate(_selectedDate).listen(
        (bookings) {
          print('✅ Reservas cargadas desde Firebase: ${bookings.length}');
          
          _bookings = bookings;
          
          // 🔥 DEBUG: mostrar reservas cargadas CON DETALLES COMPLETOS
          for (var booking in _bookings) {
            print('   📋 LOADED: courtId="${booking.courtId}" | date="${booking.date}" | timeSlot="${booking.timeSlot}" | players=${booking.players.length} | status="${booking.status}"');
            for (var player in booking.players.take(2)) {
              print('      - ${player.name} (${player.email})');
            }
          }
          
          // 🔥 FORZAR NOTIFICACIÓN INMEDIATA PARA ACTUALIZAR COLORES
          notifyListeners();
        },
        onError: (error) {
          print('❌ Error en stream de reservas: $error');
          _setError('Error cargando reservas: $error');
        },
      );
    } catch (e) {
      print('❌ Error configurando stream de reservas: $e');
      _setError('Error cargando reservas: $e');
    }
  }
  
  // ============================================================================
  // ACCIONES DEL USUARIO - Cambios de estado por interacción
  // ============================================================================
  
  /// Selecciona una cancha específica
  /// 
  /// @param courtId ID de la cancha a seleccionar
  /// @sideEffect Actualiza _selectedCourtId y notifica listeners si hay cambio
    void selectCourt(String courtId) {
    if (_selectedCourtId != courtId) {
      _selectedCourtId = courtId;
      notifyListeners();
    }
  }
  
  void selectDate(DateTime date) {
    if (_selectedDate != date) {
      _selectedDate = date;
      
      _currentDateIndex = _availableDates.indexWhere((d) => 
        d.year == date.year && d.month == date.month && d.day == date.day);
      
      if (_currentDateIndex == -1) _currentDateIndex = 0;
      
      _loadBookings();
      notifyListeners();
    }
  }
  
  void selectDateByIndex(int index) {
    if (index >= 0 && index < _availableDates.length && index != _currentDateIndex) {
      _currentDateIndex = index;
      _selectedDate = _availableDates[index];
      _loadBookings();
      notifyListeners();
    }
  }
  
  void nextDate() {
    if (_currentDateIndex < _availableDates.length - 1) {
      selectDateByIndex(_currentDateIndex + 1);
    }
  }
  
  void previousDate() {
    if (_currentDateIndex > 0) {
      selectDateByIndex(_currentDateIndex - 1);
    }
  }
  
  bool get canGoToPreviousDate => _currentDateIndex > 0;
  bool get canGoToNextDate => _currentDateIndex < _availableDates.length - 1;

  // ============================================================================
  // FILTRADO DE HORARIOS POR REGLA 72 HORAS - SIN CAMBIOS
  // ============================================================================
  
  List<String> getAvailableTimeSlotsForDate(DateTime date) {
    final now = DateTime.now();
    final isToday = date.year == now.year && 
                   date.month == now.month && 
                   date.day == now.day;
    
    final daysDifference = date.difference(DateTime(now.year, now.month, now.day)).inDays;
    final isLastDay = daysDifference == 3;
    
    final currentHour = now.hour;
    final currentMinute = now.minute;
    final currentTimeInMinutes = currentHour * 60 + currentMinute;
    
    // 🔥 USAR HORARIOS DINÁMICOS según la fecha seleccionada
    final allTimeSlots = AppConstants.getAllTimeSlots(date);
    
    final filteredSlots = allTimeSlots.where((timeSlot) {
      final parts = timeSlot.split(':');
      final slotHour = int.parse(parts[0]);
      final slotMinute = int.parse(parts[1]);
      final slotTimeInMinutes = slotHour * 60 + slotMinute;
      
      if (isToday) {
        return slotTimeInMinutes > (currentTimeInMinutes);
      } else if (isLastDay) {
        return slotTimeInMinutes <= currentTimeInMinutes;
      } else {
        return true;
      }
    }).toList();
    
    return filteredSlots;
  }
  
  // 🔥 MEJORADO: Refresh más agresivo
  Future<void> refresh() async {
    print('🔄 Refrescando datos...');
    await _loadBookings();
    
    // Forzar una segunda notificación después de un pequeño delay
    await Future.delayed(const Duration(milliseconds: 100));
    notifyListeners();
    print('🔄 Refresh completado - UI actualizada');
  }

  // ============================================================================
  // OPERACIONES CRUD - Creación, actualización y eliminación de reservas
  // ============================================================================
  
  /// Crea una reserva básica con validación completa
  /// 
  /// Método original que crea reservas sin envío automático de emails.
  /// Incluye validación completa de conflictos antes de persistir.
  /// 
  /// PROCESO:
  /// 1. Activa estado de carga
  /// 2. Valida conflictos usando canCreateBooking()
  /// 3. Persiste en Firebase usando FirestoreService
  /// 4. Maneja errores y actualiza estado
  /// 
  /// @param booking Objeto Booking completo a crear
  /// @throws Exception Si validación falla o hay errores de Firebase
  Future<void> createBooking(Booking booking) async {
    try {
      _setLoading(true);
      print('➕ Creando nueva reserva...');
      
      // 🔥 VALIDACIÓN COMPLETA
      final playerNames = booking.players.map((p) => p.name).toList();
      final validation = canCreateBooking(
        booking.courtId, 
        booking.date, 
        booking.timeSlot, 
        playerNames
      );
      
      if (!validation.isValid) {
        throw Exception(validation.reason!);
      }
      
      final bookingId = await FirestoreService.createBooking(booking);
      print('✅ Reserva creada con ID: $bookingId');
      
      _setLoading(false);
    } catch (e) {
      print('❌ Error creando reserva: $e');
      _setLoading(false);
      rethrow;
    }
  }

  /// **MÉTODO PRINCIPAL** - Crea reserva con envío automático de emails
  /// 
  /// Método completo que combina creación de reserva con sistema de notificaciones.
  /// Este es el método preferido para crear reservas desde la UI.
  /// 
  /// PROCESO COMPLETO:
  /// 1. Validación de conflictos con algoritmo completo
  /// 2. Creación de objeto Booking con datos completos
  /// 3. Persistencia en Firebase con transacciones
  /// 4. Envío automático de emails de confirmación a todos los jugadores
  /// 5. Actualización de estados de carga específicos para cada paso
  /// 
  /// ESTADOS DE CARGA:
  /// - _isLoading: Para operaciones de Firebase
  /// - _isSendingEmails: Para operaciones de email específicamente
  /// 
  /// @param courtId ID de la cancha
  /// @param date Fecha en formato YYYY-MM-DD
  /// @param timeSlot Hora en formato HH:MM
  /// @param players Lista completa de BookingPlayer con emails y teléfonos
  /// @return true si todo fue exitoso, false si hubo errores
  /// @throws Exception Si validación falla o hay errores críticos
  Future<bool> createBookingWithEmails({
    required String courtId,  // ← NUEVO PARÁMETRO
    required String date,
    required String timeSlot,
    required List<BookingPlayer> players,
  }) async {
    try {
      _setLoading(true);
      print('📝 Creando reserva con emails automáticos...');
      
      // 1. Validación completa (usar método existente)
      final playerNames = players.map((p) => p.name).toList();
      final validation = canCreateBooking(courtId, date, timeSlot, playerNames);
      
      if (!validation.isValid) {
        throw Exception(validation.reason!);
      }
      
      // 2. Crear reserva en Firebase (usar método existente)
      final booking = Booking(
        courtId: courtId,
        date: date,
        timeSlot: timeSlot,
        players: players,
        status: BookingStatus.complete,
        createdAt: DateTime.now(),
      );
      
      print('📝 Guardando en Firebase...');
      final bookingId = await FirestoreService.createBooking(booking);
      
      if (bookingId.isEmpty) {
        throw Exception('Error al crear reserva en Firebase');
      }
      
      // 3. Actualizar booking con ID para emails
      final savedBooking = booking.copyWith(id: bookingId);
      
      // 4. Enviar emails de confirmación
      print('📧 Enviando emails de confirmación...');
      _isSendingEmails = true;
      notifyListeners();
      
      final emailsSent = await EmailService.sendBookingConfirmation(savedBooking);
      
      _isSendingEmails = false;
      _setLoading(false);
      
      if (emailsSent) {
        print('✅ Reserva creada y emails enviados exitosamente');
        return true;
      } else {
        print('⚠️ Reserva creada pero algunos emails fallaron');
        // Considerar exitoso aunque algunos emails fallen
        return true;
      }
      
    } catch (e) {
      print('❌ Error creando reserva con emails: $e');
      _isSendingEmails = false;
      _setLoading(false);
      rethrow; // Mantener manejo de errores existente
    }
  }

  /// Cancela reserva con notificaciones automáticas a participantes
  /// 
  /// Proceso completo de cancelación que incluye:
  /// 1. Recuperación de datos completos de la reserva
  /// 2. Envío de notificaciones a todos los demás participantes
  /// 3. Eliminación de la reserva de Firebase
  /// 4. Manejo de estados de carga específicos
  /// 
  /// @param bookingId ID único de la reserva a cancelar
  /// @param cancelingPlayer Datos del jugador que cancela la reserva
  /// @return true si la cancelación fue exitosa
  /// @throws Exception si la reserva no existe o hay errores de red
  Future<bool> cancelBookingWithNotifications({
    required String bookingId,
    required BookingPlayer cancelingPlayer,
  }) async {
    try {
      _setLoading(true);
      print('🗑️ Cancelando reserva con notificaciones...');
      
      // 1. Obtener datos completos de la reserva
      final booking = await _getBookingById(bookingId);
      if (booking == null) {
        throw Exception('Reserva no encontrada');
      }
      
      // 2. Enviar notificaciones a otros jugadores
      print('📧 Enviando notificaciones de cancelación...');
      _isSendingEmails = true;
      notifyListeners();
      
      final notificationsSent = await EmailService.sendCancellationNotification(
        booking: booking,
        cancelingPlayer: cancelingPlayer,
      );
      
      // 3. Eliminar reserva de Firebase
      await FirestoreService.deleteBooking(bookingId);
      
      _isSendingEmails = false;
      _setLoading(false);
      
      if (notificationsSent) {
        print('✅ Reserva cancelada y notificaciones enviadas');
      } else {
        print('⚠️ Reserva cancelada pero algunas notificaciones fallaron');
      }
      
      return true;
      
    } catch (e) {
      print('❌ Error cancelando reserva: $e');
      _isSendingEmails = false;
      _setLoading(false);
      rethrow;
    }
  }

  // 🔥 HELPER: Obtener reserva por ID (buscar en memoria o Firebase)
  Future<Booking?> _getBookingById(String bookingId) async {
    try {
      // Buscar en las reservas cargadas primero
      for (final booking in _bookings) {
        if (booking.id == bookingId) {
          return booking;
        }
      }
      
      // Si no se encuentra, consultar Firebase directamente
      return await FirestoreService.getBookingById(bookingId);
    } catch (e) {
      print('❌ Error obteniendo reserva: $e');
      return null;
    }
  }

  // ============================================================================
  // GESTIÓN DE ESTADO INTERNO - Control de loading, errores y notificaciones
  // ============================================================================
  
  /// Actualiza estado de carga y notifica listeners
  /// 
  /// @param loading Nuevo estado de carga
  /// @sideEffect Limpia errores cuando se activa carga, notifica listeners
  void _setLoading(bool loading) {
    _isLoading = loading;
    if (loading) _error = null;
    notifyListeners();
  }
  
  /// Establece mensaje de error y desactiva carga
  /// 
  /// @param error Mensaje de error a mostrar
  /// @sideEffect Desactiva loading, notifica listeners
  void _setError(String error) {
    _error = error;
    _isLoading = false;
    notifyListeners();
  }
  
  void clearError() {
    _error = null;
    notifyListeners();
  }
  
  @override
  void dispose() {
    _courtsSubscription?.cancel();
    _bookingsSubscription?.cancel();
    super.dispose();
  }
}

/// Clase para encapsular resultados de validación de reservas
/// 
/// Utilizada por canCreateBooking() para retornar tanto el resultado
/// booleano como la razón específica del fallo si la validación no pasa.
/// 
/// PROPÓSITO:
/// - Proporcionar feedback específico sobre por qué falló una validación
/// - Permitir mostrar mensajes de error detallados al usuario
/// - Encapsular lógica de validación en un tipo seguro
/// 
/// CASOS DE USO:
/// - Validaciones de conflictos de horarios
/// - Verificación de reglas de negocio
/// - Feedback detallado en UI
class ValidationResult {
  /// Indica si la validación fue exitosa
  final bool isValid;
  /// Razón específica del fallo (null si isValid es true)
  final String? reason;

  ValidationResult({required this.isValid, this.reason});
}
