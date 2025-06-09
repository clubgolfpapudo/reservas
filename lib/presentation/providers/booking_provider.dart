// lib/presentation/providers/booking_provider.dart - VALIDACIÓN DE CONFLICTOS + EMAILS
import 'package:flutter/material.dart';
import 'dart:async';

// Entities
import '../../domain/entities/booking.dart';
import '../../domain/entities/court.dart';

// Services  
import '../../data/services/firestore_service.dart';
import '../../data/services/email_service.dart';

// Constants
import '../../core/constants/app_constants.dart';

// Importar ScheduleService
import '../../core/services/schedule_service.dart';

class BookingProvider extends ChangeNotifier {
  // ============================================================================
  // ESTADO PRIVADO
  // ============================================================================
  
  List<Court> _courts = [];
  List<Booking> _bookings = [];
  String _selectedCourtId = 'court_1';
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  String? _error;
  
  // NUEVO: Estado para navegación de fechas
  List<DateTime> _availableDates = [];
  int _currentDateIndex = 0;
  
  // NUEVO: Estado para sistema de emails
  bool _isSendingEmails = false;
  
  // Streams subscriptions para limpiar recursos
  StreamSubscription? _courtsSubscription;
  StreamSubscription? _bookingsSubscription;

  // 🔥 CONSTANTES DE VALIDACIÓN
  static const List<String> _specialVisitPlayers = [
    'VISITA1 PADEL',
    'VISITA2 PADEL', 
    'VISITA3 PADEL',
    'VISITA4 PADEL'
  ];
  
  // ============================================================================
  // GETTERS PÚBLICOS
  // ============================================================================
  
  List<Court> get courts => _courts;
  List<Booking> get bookings => _bookings;
  String get selectedCourtId => _selectedCourtId;
  DateTime get selectedDate => _selectedDate;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // NUEVOS: Getters para navegación de fechas
  List<DateTime> get availableDates => _availableDates;
  int get currentDateIndex => _currentDateIndex;
  int get totalAvailableDays => _availableDates.length;
  
  // NUEVO: Getter para estado de emails
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

  // 🔥 CORREGIDO: Filtrado de reservas por fecha Y cancha
  List<Booking> get currentBookings {
    final selectedDateStr = _formatDateForFirebase(_selectedDate);
    
    print('🔍 DEBUG RESERVAS FILTRADAS:');
    print('   Court seleccionada: $_selectedCourtId');
    print('   Fecha seleccionada: $selectedDateStr ($_selectedDate)');
    print('   Total bookings en _bookings: ${_bookings.length}');
    
    // 🔥 DEBUG: Mostrar TODAS las reservas primero
    for (var booking in _bookings) {
      print('   📋 ALL: ${booking.courtNumber} | ${booking.date} | ${booking.timeSlot} | ${booking.players.length} jugadores');
    }
    
    final filteredBookings = _bookings.where((booking) => 
      booking.courtNumber == _selectedCourtId && 
      booking.date == selectedDateStr
    ).toList();
    
    print('   Bookings filtradas: ${filteredBookings.length}');
    
    for (var booking in filteredBookings) {
      print('   ✅ FILTERED: ${booking.timeSlot} - ${booking.players.length} jugadores - ${booking.status}');
    }
    
    return filteredBookings;
  }

  // 🔥 NUEVO: Obtener TODAS las reservas de una fecha (sin filtrar por cancha)
  List<Booking> getAllBookingsForDate(DateTime date) {
    final dateStr = _formatDateForFirebase(date);
    final bookingsForDate = _bookings.where((booking) => booking.date == dateStr).toList();
    
    print('🔍 getAllBookingsForDate para $dateStr:');
    print('   Total en _bookings: ${_bookings.length}');
    print('   Para fecha específica: ${bookingsForDate.length}');
    
    for (var booking in bookingsForDate) {
      print('   📋 ${booking.courtNumber} ${booking.timeSlot} (${booking.players.length} jugadores)');
    }
    
    return bookingsForDate;
  }
  
  // ============================================================================
  // VALIDACIÓN DE CONFLICTOS DE JUGADORES
  // ============================================================================

  // 🔥 MÉTODO PRINCIPAL: Validar si se puede crear una reserva
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
        booking.courtNumber == courtId && 
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
      booking.timeSlot == timeSlot && booking.courtNumber != courtId
    ).toList();

    print('🔍 Reservas en otras canchas para $timeSlot: ${conflictingBookings.length}');

    for (final booking in conflictingBookings) {
      print('   📋 Verificando ${booking.courtNumber}: ${booking.players.map((p) => p.name).join(", ")}');
      
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
            print('   Ya reservado en: ${booking.courtNumber} a las $timeSlot');
            return ValidationResult(
              isValid: false,
              reason: 'El jugador "${existingPlayer.name}" ya tiene una reserva a las $timeSlot en ${_getCourtDisplayName(booking.courtNumber)}.'
            );
          }
        }
      }
    }

    print('✅ VALIDACIÓN: Sin conflictos detectados - reserva permitida');
    print('🔍 VALIDACIÓN COMPLETA - FIN\n');
    return ValidationResult(isValid: true, reason: null);
  }

  // 🔥 HELPER: Verificar si un jugador es especial (VISITA)
  bool _isSpecialVisitPlayer(String playerName) {
    final cleanName = playerName.trim().toUpperCase();
    return _specialVisitPlayers.contains(cleanName);
  }

  // 🔥 HELPER: Comparar nombres de jugadores (limpieza + case-insensitive)
  bool _playersMatch(String name1, String name2) {
    final clean1 = name1.trim().toUpperCase();
    final clean2 = name2.trim().toUpperCase();
    return clean1 == clean2;
  }

  // 🔥 HELPER: Obtener nombre amigable de cancha
  String _getCourtDisplayName(String courtId) {
    switch (courtId) {
      case 'court_1': return 'PITE';
      case 'court_2': return 'LILEN';
      case 'court_3': return 'PLAIYA';
      default: return courtId;
    }
  }
  
  // ============================================================================
  // ESTADÍSTICAS PARA UI COMPACTA
  // ============================================================================

  /// Calcula estadísticas basadas SOLO en los horarios visibles en pantalla
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
  // MÉTODOS AUXILIARES CORREGIDOS
  // ============================================================================

  // 🔥 MÉTODO CRÍTICO CORREGIDO - Búsqueda de reserva específica
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
  }
  
  // 🔥 MEJORADO: Generar fechas disponibles usando ScheduleService
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
  
  Future<void> _loadCourts() async {
    try {
      _setLoading(true);
      
      final now = DateTime.now();
      _courts = [
        Court(
          id: 'court_1',
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
          id: 'court_2',
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
          id: 'court_3',
          name: 'PLAIYA',
          description: 'Cancha de pádel PLAIYA',
          number: 3,
          displayOrder: 3,
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
  
  // 🔥 CORREGIDO: Carga de reservas más robusta
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
            print('   📋 LOADED: courtNumber="${booking.courtNumber}" | date="${booking.date}" | timeSlot="${booking.timeSlot}" | players=${booking.players.length} | status="${booking.status}"');
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
  // ACCIONES DEL USUARIO - SIN CAMBIOS MAYORES
  // ============================================================================
  
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
  // OPERACIONES CRUD CON VALIDACIÓN COMPLETA
  // ============================================================================
  
  // 🔥 CORREGIDO: Validación completa antes de crear reserva (método original)
  Future<void> createBooking(Booking booking) async {
    try {
      _setLoading(true);
      print('➕ Creando nueva reserva...');
      
      // 🔥 VALIDACIÓN COMPLETA
      final playerNames = booking.players.map((p) => p.name).toList();
      final validation = canCreateBooking(
        booking.courtNumber, 
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

  // 🔥 NUEVO: Crear reserva CON envío automático de emails
  Future<bool> createBookingWithEmails({
    required String courtNumber,
    required String date,
    required String timeSlot,
    required List<BookingPlayer> players,
  }) async {
    try {
      _setLoading(true);
      print('📝 Creando reserva con emails automáticos...');
      
      // 1. Validación completa (usar método existente)
      final playerNames = players.map((p) => p.name).toList();
      final validation = canCreateBooking(courtNumber, date, timeSlot, playerNames);
      
      if (!validation.isValid) {
        throw Exception(validation.reason!);
      }
      
      // 2. Crear reserva en Firebase (usar método existente)
      final booking = Booking(
        courtNumber: courtNumber,
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

  // 🔥 NUEVO: Cancelar reserva CON notificaciones por email
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
  // GESTIÓN DE ESTADO INTERNO - SIN CAMBIOS
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

// 🔥 CLASE PARA RESULTADOS DE VALIDACIÓN
class ValidationResult {
  final bool isValid;
  final String? reason;

  ValidationResult({required this.isValid, this.reason});
}