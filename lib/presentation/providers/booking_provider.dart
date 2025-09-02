/// lib/presentation/providers/booking_provider.dart
/// 
/// CAMBIOS IMPLEMENTADOS:
/// ✅ Estados dinámicos según deporte y número de jugadores
/// ✅ Pádel: Siempre BookingStatus.complete (4 jugadores obligatorio)
/// ✅ Tenis: BookingStatus.incomplete para 2-3 jugadores, complete para 4
/// ✅ Parámetro initialStatus en createBookingWithEmails
/// ✅ Validación flexible por deporte

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Entities
import '../../domain/entities/court.dart';
import '../../domain/entities/booking.dart';
import '../../domain/entities/user.dart';

// Services
import '../../core/services/firebase_user_service.dart';
import '../../core/services/schedule_service.dart';
import '../../core/services/user_service.dart';
import '../../data/services/email_service.dart';
import '../../data/services/firestore_service.dart';

// Constants
import '../../core/constants/app_constants.dart';

/// Provider principal para gestión de estado de reservas
class BookingProvider extends ChangeNotifier {
  // ============================================================================
  // ESTADO PRIVADO
  // ============================================================================
  
  List<BookingPlayer> _users = [];
  List<Court> _courts = [];
  List<Booking> _bookings = [];
  String _selectedCourtId = 'padel_court_1';
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  String? _error;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<BookingPlayer>? users;
  
  List<DateTime> _availableDates = [];
  int _currentDateIndex = 0;
  
  bool _isSendingEmails = false;
  
  // Streams subscriptions para limpiar recursos
  StreamSubscription? _courtsSubscription;
  StreamSubscription? _bookingsSubscription;
  
  // ============================================================================
  // GETTERS PÚBLICOS
  // ============================================================================
  
  // AGREGAR estos métodos después de las propiedades privadas
  DateTime _getSmartInitialDate() {
    final now = DateTime.now();
    final currentHour = now.hour;
    final currentMinute = now.minute;
    
    // Después de 4:01 PM - mostrar desde mañana
    if (currentHour > 16 || (currentHour == 16 && currentMinute >= 1)) {
      return now.add(Duration(days: 1));
    }
    
    // Antes de 8:01 AM - mostrar desde hoy
    if (currentHour < 8 || (currentHour == 8 && currentMinute == 0)) {
      return now;
    }
    
    // Entre 8:01 AM y 4:00 PM - mostrar desde hoy
    return now;
  }

  int _getAvailableDaysCount() {
    final now = DateTime.now();
    final currentHour = now.hour;
    final currentMinute = now.minute;
    
    // Entre 8:01 AM y 4:00 PM - 3 días disponibles
    if ((currentHour == 8 && currentMinute >= 1) || 
        (currentHour > 8 && currentHour < 16) || 
        (currentHour == 16 && currentMinute == 0)) {
      return 3;
    }
    
    // Resto del tiempo - 2 días disponibles
    return 2;
  }

  // Método público para inicializar fechas inteligentes de golf
  void initializeGolfDates() {
    final smartDate = _getSmartInitialDate();
    final daysCount = _getAvailableDaysCount();
    
    _selectedDate = smartDate;
    _availableDates = List.generate(daysCount, (index) => 
        smartDate.add(Duration(days: index)));
    
    notifyListeners();
  }

  List<Court> get courts => _courts;
  List<Booking> get bookings => _bookings;
  String get selectedCourtId => _selectedCourtId;
  DateTime get selectedDate => _selectedDate;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  List<DateTime> get availableDates => _availableDates;
  int get currentDateIndex => _currentDateIndex;
  int get totalAvailableDays => _availableDates.length;
  
  bool get isSendingEmails => _isSendingEmails;
  
  // ============================================================================
  // COMPUTED PROPERTIES
  // ============================================================================
  
  Court? get selectedCourt {
    try {
      return _courts.firstWhere((court) => court.id == _selectedCourtId);
    } catch (e) {
      return null;
    }
  }
  
  String get selectedCourtName {
    return selectedCourt?.name ?? 'Cancha';
  }

  List<Booking> get currentBookings {
    final selectedDateStr = _formatDateForFirebase(_selectedDate);
    
    print('🔍 DEBUG RESERVAS FILTRADAS:');
    print('   Court seleccionada: $_selectedCourtId');
    print('   Fecha seleccionada: $selectedDateStr ($_selectedDate)');
    print('   Total bookings en _bookings: ${_bookings.length}');
    
    // Debug: Mostrar TODAS las reservas primero
    for (var booking in _bookings) {
      print('   📋 ALL: ${booking.courtId} | ${booking.date} | ${booking.timeSlot} | ${booking.players.length} jugadores');
    }
    
    final filteredBookings = _bookings.where((booking) {
      if (_selectedCourtId?.startsWith('golf_') == true) {
        // Para golf: incluir ambos hoyos
        return (booking.courtId == 'golf_tee_1' || booking.courtId == 'golf_tee_10') &&
              booking.date == selectedDateStr;
      } else {
        // Para tennis/paddle: filtrar solo por cancha seleccionada
        return booking.courtId == _selectedCourtId &&
              booking.date == selectedDateStr;
      }
    }).toList();
    
    return filteredBookings;
  }

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
  // ✅ NUEVO: DETERMINACIÓN DE ESTADO INICIAL POR DEPORTE
  // ============================================================================

  /// Determina el estado inicial de una reserva según el deporte y número de jugadores
  /// 
  /// REGLAS:
  /// - PÁDEL: Siempre BookingStatus.complete (requiere exactamente 4 jugadores)
  /// - TENIS: BookingStatus.incomplete para 2-3 jugadores, complete para 4+
  /// 
  /// @param courtId ID de la cancha para identificar el deporte
  /// @param playerCount Número de jugadores en la reserva
  /// @return BookingStatus apropiado según las reglas de negocio
  BookingStatus determineInitialBookingStatus(String courtId, int playerCount) {
    print('🎯 DETERMINANDO ESTADO INICIAL:');
    print('   Court ID: $courtId');
    print('   Jugadores: $playerCount');
    
    if (courtId.startsWith('padel_')) {
      print('   → PÁDEL detectado: BookingStatus.complete');
      return BookingStatus.complete;
    } else if (courtId.startsWith('tennis_')) {
      print('   → TENIS detectado: BookingStatus.complete');
      return BookingStatus.complete;
    }
    
    print('   → FALLBACK: BookingStatus.complete');
    return BookingStatus.complete;
  }

  // ============================================================================
  // VALIDACIÓN DE CONFLICTOS - CON VALIDACIÓN POR DEPORTE
  // ============================================================================

  /// ✅ MEJORADO: Valida si se puede crear una reserva con reglas específicas por deporte
  ValidationResult canCreateBooking(String courtId, String date, String timeSlot, List<String> playerNames) {
    print('\n🔍 VALIDACIÓN COMPLETA - INICIO');
    print('   Court: $courtId');
    print('   Fecha: $date'); 
    print('   Hora: $timeSlot');
    print('   Jugadores: ${playerNames.join(", ")}');
    print('   Total reservas en memoria: ${_bookings.length}');

    // ✅ NUEVO: Validación específica por deporte ANTES de conflictos
    final sport = _getSportFromCourtId(courtId);
    final playerCount = playerNames.length;
    
    print('🎯 VALIDANDO LÍMITES POR DEPORTE:');
    print('   Deporte detectado: $sport');
    print('   Jugadores proporcionados: $playerCount');
    
    if (sport == 'PADEL') {
      // ✅ FIX: Solo validar límites al crear la reserva, no al abrir modal
      if (playerCount < 1) {
        print('❌ VALIDACIÓN: Pádel requiere al menos el organizador');
        return ValidationResult(
          isValid: false,
          reason: 'Se requiere al menos un jugador.'
        );
      } else if (playerCount > 4) {
        print('❌ VALIDACIÓN: Pádel permite máximo 4 jugadores');
        return ValidationResult(
          isValid: false,
          reason: 'Pádel permite máximo 4 jugadores. Tienes $playerCount.'
        );
      }
      print('✅ VALIDACIÓN: Pádel con $playerCount jugador(es) - validación inicial OK');
    } else if (sport == 'TENIS') {
      if (playerCount < 1) {
        print('❌ VALIDACIÓN: Tenis requiere al menos el organizador');
        return ValidationResult(
          isValid: false,
          reason: 'Se requiere al menos un jugador.'
        );
      } else if (playerCount > 4) {
        print('❌ VALIDACIÓN: Tenis permite máximo 4 jugadores');
        return ValidationResult(
          isValid: false,
          reason: 'Tenis permite máximo 4 jugadores. Tienes $playerCount.'
        );
      }
      print('✅ VALIDACIÓN: Tenis con $playerCount jugador(es) - validación inicial OK');
    }

    print('✅ LÍMITES POR DEPORTE: Validación exitosa');

    // El resto del método sigue igual...
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

  /// ✅ NUEVO: Extrae el deporte del ID de cancha
  String _getSportFromCourtId(String courtId) {
    if (courtId.startsWith('padel_')) return 'PADEL';
    if (courtId.startsWith('tennis_')) return 'TENIS';
    if (courtId.startsWith('golf_')) return 'GOLF';
    return 'UNKNOWN';
  }

  /// Verifica si un jugador es especial (tipo VISITA)
  bool _isSpecialVisitPlayer(String playerName) {
    final cleanName = playerName.trim().toUpperCase();
    return ['PADEL1 VISITA', 'PADEL2 VISITA', 'PADEL3 VISITA', 'PADEL4 VISITA']
        .contains(cleanName);
  }

  /// Compara nombres de jugadores con limpieza y case-insensitive
  bool _playersMatch(String name1, String name2) {
    final clean1 = name1.trim().toUpperCase();
    final clean2 = name2.trim().toUpperCase();
    return clean1 == clean2;
  }

  /// Obtiene nombre amigable de cancha para mostrar en mensajes
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
  // ESTADÍSTICAS PARA UI
  // ============================================================================

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

  String get emailStatus {
    if (_isSendingEmails) {
      return 'Enviando confirmaciones...';
    }
    return '';
  }
  
  // ============================================================================
  // MÉTODOS AUXILIARES
  // ============================================================================

  Booking? getBookingForTimeSlot(String timeSlot) {
    for (var booking in currentBookings) {
      if (booking.timeSlot == timeSlot) {
        return booking;
      }
    }
    return null;
  }

  bool isTimeSlotAvailable(String timeSlot) {
    return getBookingForTimeSlot(timeSlot) == null;
  }

  // ============================================================================
  // INICIALIZACIÓN
  // ============================================================================
  
  BookingProvider() {
    _initializeProvider();
  }
  
  Future<void> _initializeProvider() async {
    print('🔥 Inicializando BookingProvider con Firebase...');
    _generateAvailableDates();
    await _loadCourts();
    await _loadBookings();
    await initializeCurrentUser();
  }

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

  Future<void> addPlayerToBooking(String bookingId, String playerId, String playerName) async {
    try {
      await _firestore
        .collection('bookings')
        .doc(bookingId)
        .update({
          'players': FieldValue.arrayUnion([{'id': playerId, 'name': playerName}]),
        });
    } catch (e) {
      print('Error al agregar jugador: $e');
    }
  }

  // Propiedades privadas para usuario actual
  String? _currentUserEmail;
  String? _currentUserName;

  // Getters públicos para usuario actual
  String? get currentUserEmail => _currentUserEmail;
  String? get currentUserName => _currentUserName;
  bool get hasCurrentUser => _currentUserEmail != null && _currentUserName != null;

  void _generateAvailableDates() {
    _availableDates.clear();
    
    final now = DateTime.now();
    
    // Para golf: 48 horas exactas, para otros deportes: 4 días
    final bool isGolf = _selectedCourtId?.startsWith('golf_') ?? false;
    
    if (isGolf) {
      // Golf: 48 horas exactas desde ahora
      final DateTime endTime = now.add(Duration(hours: 48));
      DateTime current = DateTime(now.year, now.month, now.day);
      
      while (current.isBefore(endTime.add(Duration(days: 1)))) {
        _availableDates.add(current);
        current = current.add(Duration(days: 1));
      }
    } else {
      // Tennis/Paddle: lógica original (4 días)
      for (int i = 0; i < 4; i++) {
        _availableDates.add(now.add(Duration(days: i)));
      }
    }
    
    _currentDateIndex = 0;
    _selectedDate = _availableDates.first;
  }
  
  String _formatDate(DateTime date) {
    const months = [
      '', 'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    
    return '${date.day} de ${months[date.month]}';
  }

  String _formatDateForFirebase(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
  
  // ============================================================================
  // CARGA DE DATOS DESDE FIREBASE
  // ============================================================================
  
  Future<void> _loadCourts() async {
    try {
      _setLoading(true);
      
      final now = DateTime.now();
      _courts = [
        // PÁDEL - Mantener IDs originales
        Court(
          id: 'padel_court_1',
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
          id: 'padel_court_2',
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
          id: 'padel_court_3',
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
          id: 'tennis_court_1',
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
          id: 'tennis_court_2',
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
          id: 'tennis_court_3',
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
          id: 'tennis_court_4',
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
  
  Future<void> _loadBookings() async {
    try {
      print('Cargando reservas desde Firestore...');
      _bookingsSubscription?.cancel();
      
      _bookingsSubscription = FirestoreService.getBookingsByDate(_selectedDate).listen(
        (bookings) {
          if (_selectedCourtId?.startsWith('golf_') == true) {
            // Para golf: usar TODAS las reservas sin filtrar por courtId
            _bookings = bookings;
          } else {
            // Para tennis/paddle: usar todas las reservas
            _bookings = bookings;
          }
          
          print('Reservas cargadas: ${_bookings.length}');
          notifyListeners();
        },
        onError: (error) {
          print('Error al cargar reservas: $error');
          _bookings = [];
          notifyListeners();
        }
      );
    } catch (e) {
      print('Error en _loadBookings: $e');
      _bookings = [];
      notifyListeners();
    }
  }
  
  // ============================================================================
  // ACCIONES DEL USUARIO
  // ============================================================================
  
  void selectCourt(String courtId) {
    print('🔧 LLAMANDO: selectCourt recibió = $courtId');
    print('🔧 ESTADO ANTES: _selectedCourtId = $_selectedCourtId');
    
    if (_selectedCourtId != courtId) {
      _selectedCourtId = courtId;
      print('🔧 ESTADO DESPUÉS: _selectedCourtId = $_selectedCourtId');
      notifyListeners();
    } else {
      print('🔧 NO CAMBIÓ: courtId ya era el mismo');
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
  // FILTRADO DE HORARIOS POR REGLA 72 HORAS
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
  
  Future<void> refresh() async {
    print('🔄 Refrescando datos...');
    await _loadBookings();
    
    // Forzar una segunda notificación después de un pequeño delay
    await Future.delayed(const Duration(milliseconds: 100));
    notifyListeners();
    print('🔄 Refresh completado - UI actualizada');
  }

  // ============================================================================
  // ✅ OPERACIONES CRUD - CON ESTADOS DINÁMICOS
  // ============================================================================
  
  /// Crea una reserva básica con validación completa
  Future<void> createBooking(Booking booking) async {
    try {
      _setLoading(true);
      print('➕ Creando nueva reserva...');
      
      // Validación completa
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

  /// ✅ MÉTODO PRINCIPAL MEJORADO - Crea reserva con estado dinámico y emails
  Future<bool> createBookingWithEmails({
    required String courtId,
    required String date,
    required String timeSlot,
    required List<BookingPlayer> players,
    BookingStatus? initialStatus, // NUEVO PARÁMETRO OPCIONAL
  }) async {
    try {
      _setLoading(true);
      print('📍 Creando reserva con emails automáticos...');
      
      // 1. Validación completa
      final playerNames = players.map((p) => p.name).toList();
      final validation = canCreateBooking(courtId, date, timeSlot, playerNames);
      
      if (!validation.isValid) {
        throw Exception(validation.reason!);
      }
      
      // 2. NUEVO: Determinar estado inicial
      final bookingStatus = initialStatus ?? determineInitialBookingStatus(courtId, players.length);
      
      print('🎯 ESTADO DETERMINADO PARA RESERVA:');
      print('   Court ID: $courtId');
      print('   Jugadores: ${players.length}');
      print('   Estado asignado: $bookingStatus');
      print('   Fue proporcionado externamente: ${initialStatus != null}');
      
      // Crear reserva en Firebase
      final booking = Booking(
        id: DateTime.now().millisecondsSinceEpoch.toString(), // Genera un ID temporal
        courtId: courtId,
        date: date,
        timeSlot: timeSlot,
        players: players,
        status: bookingStatus, // USAR EL ESTADO DINÁMICO
        createdAt: DateTime.now(),
        updatedAt: null,
      );

      print('📍 Guardando en Firebase...');
      final bookingId = await FirestoreService.createBooking(booking);

      if (bookingId.isEmpty) {
        throw Exception('Error al crear reserva en Firebase');
      }
      
      // 4. Actualizar booking con ID para emails
      final savedBooking = booking.copyWith(id: bookingId);
      
      // 5. Enviar emails de confirmación
      print('📧 Enviando emails de confirmación...');
      _isSendingEmails = true;
      notifyListeners();
      
      final emailsSent = await EmailService.sendBookingConfirmation(booking);
      
      _isSendingEmails = false;
      _setLoading(false);
      
      if (emailsSent) {
        print('✅ Reserva creada y emails enviados exitosamente');
        return true;
      } else {
        print('⚠️ Reserva creada pero algunos emails fallaron');
        return true;
      }
      
    } catch (e) {
      print('❌ Error creando reserva con emails: $e');
      _isSendingEmails = false;
      _setLoading(false);
      rethrow;
    }
  }

  /// Cancela reserva con notificaciones automáticas a participantes
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

  /// ✅ NUEVO: Edita una reserva existente
  /// El administrador puede agregar o remover jugadores
  Future<void> editBooking({
    required Booking updatedBooking,
  }) async {
    try {
      _setLoading(true);

      // 1. Obtener la reserva original desde la base de datos
      final originalBooking = await FirestoreService.getBookingById(updatedBooking.id ?? '');
      if (originalBooking == null) {
        _setError('La reserva a editar no fue encontrada.');
        return;
      }

      // 2. Actualizar la reserva en Firestore
      await FirestoreService.updateBooking(updatedBooking);

      // 3. Comparar las listas de jugadores para enviar notificaciones
      final originalPlayers = originalBooking.players.map((p) => p.email).toSet();
      final updatedPlayers = updatedBooking.players.map((p) => p.email).toSet();
      
      // Jugadores agregados (en la nueva lista pero no en la original)
      final playersAdded = updatedPlayers.difference(originalPlayers);
      
      // Jugadores removidos (en la original pero no en la nueva)
      final playersRemoved = originalPlayers.difference(updatedPlayers);

      // Enviar notificaciones
      if (playersAdded.isNotEmpty) {
        await EmailService.sendPlayerAddedNotification(
          updatedBooking: updatedBooking,
        );
      }
      
      if (playersRemoved.isNotEmpty) {
        final removedPlayerEmail = playersRemoved.first;
        final removedPlayer = originalBooking.players.firstWhere((p) => p.email == removedPlayerEmail);
        
        await EmailService.sendCancellationNotification(
          booking: updatedBooking,
          cancelingPlayer: removedPlayer,
        );
      }
      
      _setLoading(false);
      
    } catch (e) {
      _setError('Error al editar reserva: $e');
    }
  }

  /// ✅ CORRECCIÓN CRÍTICA: Editar solo la lista de jugadores de una reserva
  Future<void> editBookingPlayers({
    required String bookingId,
    required List<BookingPlayer> updatedPlayers,
  }) async {
    print('🔥 DEBUG BookingProvider: editBookingPlayers iniciado');
    print('🔥 DEBUG BookingProvider: bookingId = $bookingId');
    print('🔥 DEBUG BookingProvider: updatedPlayers = ${updatedPlayers.map((p) => p.name).toList()}');
    
    try {
      _setLoading(true);
      
      // Llamada atómica al servicio específico
      await FirestoreService.updateBookingPlayers(bookingId, updatedPlayers);
      print('🔥 DEBUG BookingProvider: FirestoreService.updateBookingPlayers completado');
      
      // Actualizar el estado local para reflejar los cambios inmediatamente
      final bookingIndex = _bookings.indexWhere((b) => b.id == bookingId);
      print('🔥 DEBUG BookingProvider: bookingIndex encontrado = $bookingIndex');
      
      if (bookingIndex != -1) {
        _bookings[bookingIndex] = _bookings[bookingIndex].copyWith(players: updatedPlayers);
        print('🔥 DEBUG BookingProvider: Estado local actualizado');
      }
      
      _setLoading(false);
      notifyListeners();
      
      print('🔥 DEBUG BookingProvider: editBookingPlayers completado exitosamente');
      
    } catch (e) {
      print('🔥 DEBUG BookingProvider: ERROR = $e');
      _setError('Error al editar los jugadores de la reserva: $e');
    }
  }

  /// ✅ NUEVO: Elimina una reserva completa
  Future<void> deleteBooking({required String bookingId}) async {
    try {
      _setLoading(true);
      
      // 1. Obtener la reserva para poder notificar a todos los jugadores
      final bookingToDelete = await FirestoreService.getBookingById(bookingId);
      if (bookingToDelete == null) {
        _setError('La reserva a eliminar no fue encontrada.');
        return;
      }
      
      // 2. Eliminar la reserva de Firestore
      await FirestoreService.deleteBooking(bookingId);
      
      // 3. Enviar notificación de eliminación a todos los jugadores
      for (final player in bookingToDelete.players) {
        await EmailService.sendCancellationNotification(
          booking: bookingToDelete.copyWith(players: bookingToDelete.players.where((p) => p.id != player.id).toList()),
          cancelingPlayer: player,
        );
      }
      
      _setLoading(false);
      
    } catch (e) {
      _setError('Error al eliminar reserva: $e');
    }
  }

  // Helper: Obtener reserva por ID
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

  /// Carga la lista de usuarios desde Firebase y la asigna a _users.
  /// Llama a notifyListeners() para actualizar la UI cuando los datos están listos.
  Future<void> fetchUsers() async {
    try {
      _setLoading(true);
      final firebaseUsers = await FirebaseUserService.getAllUsers();
      
      // ✅ AÑADE ESTA LÍNEA AQUÍ PARA VER QUÉ DEVUELVE FIREBASE
      print('📦 Datos de usuarios de Firebase: $firebaseUsers');

      _users = firebaseUsers.map((userMap) {
        return BookingPlayer(
          id: (userMap['uid'] as String?) ?? 'null-uid',
          name: (userMap['name'] as String?) ?? 'No Name',
          email: userMap['email'] as String?,
          phone: userMap['phone'] as String?,
        );
      }).toList();
      
      users = _users;

      print('DEBUG Provider: _users asignados: ${_users.length}');
      print('DEBUG Provider: users getter: ${users?.length ?? "null"}');
    
      notifyListeners();
      _setLoading(false);
    } catch (e) {
      _setError('Error al cargar la lista de usuarios: $e');
    }
  }

  /// Utiliza el servicio de Firestore para obtener las reservas.
  Future<void> fetchBookingsForSelectedDate(DateTime date) async {
    try {
      _setLoading(true);
      
      // Obtener reservas del stream
      final bookingsStream = FirestoreService.getBookingsByDate(date);
      _bookings = await bookingsStream.first;
      
      // Debug para ver cuántas reservas se cargaron
      print('DEBUG: Reservas cargadas para ${date}: ${_bookings.length}');
      
      // IMPORTANTE: Notificar a la UI que hay nuevos datos
      notifyListeners();
      _setLoading(false);
    } catch (e) {
      print('DEBUG: Error cargando reservas: $e');
      _setError('Error al cargar las reservas: $e');
    }
  }

  /// Carga las canchas disponibles desde el servicio de Firestore.
  Future<void> fetchCourts() async {
    try {
      _setLoading(true);
      _courts = await FirestoreService.getCourts().first;
      _setLoading(false);
    } catch (e) {
      _setError('Error al cargar las canchas: $e');
    }
  }

  // ============================================================================
  // GESTIÓN DE ESTADO INTERNO
  // ============================================================================
  
  void _setLoading(bool loading) {
    _isLoading = loading;
    if (loading) _error = null;
    notifyListeners();
  }
  
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
class ValidationResult {
  final bool isValid;
  final String? reason;

  ValidationResult({required this.isValid, this.reason});
}