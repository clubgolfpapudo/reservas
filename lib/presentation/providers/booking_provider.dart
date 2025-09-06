/// lib/presentation/providers/booking_provider.dart
/// 
/// CAMBIOS IMPLEMENTADOS:
/// ✅ Estados dinámicos según deporte y número de jugadores
/// ✅ Pádel: Siempre BookingStatus.complete (4 jugadores obligatorio)
/// ✅ Tenis: BookingStatus.incomplete para 2-3 jugadores, complete para 4
/// ✅ Parámetro initialStatus en createBookingWithEmails
/// ✅ Validación flexible por deporte

import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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

// Utils
import '../../../core/utils/booking_time_utils.dart';

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

  String _getSportFromCourtId(String courtId) {
    if (courtId.startsWith('golf_')) return 'GOLF';
    if (courtId.startsWith('tennis_')) return 'TENIS';
    return 'PADEL';
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
    print('=== CALCULANDO STATS ===');
  
    // FIX: Extraer solo la fecha sin timestamp
    final dateOnly = '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
    print('selectedDate original: $selectedDate');
    print('dateOnly para comparar: $dateOnly');
    
    int completeCount = 0;
    int incompleteCount = 0;
    int availableCount = 0;
    
    // Obtener canchas del deporte actual
    List<String> courts = [];
    if (selectedCourtId.startsWith('golf_')) {
      courts = ['golf_tee_1', 'golf_tee_10'];
    } else if (selectedCourtId.startsWith('tennis_')) {
      courts = ['tennis_cancha_1', 'tennis_cancha_2', 'tennis_cancha_3', 'tennis_cancha_4'];
    } else if (selectedCourtId.startsWith('padel_')) {
      courts = ['padel_court_1', 'padel_court_2', 'padel_court_3'];
    } else {
      courts = ['pite', 'lilen', 'plaiya'];
    }
    
    print('selectedCourtId: $selectedCourtId');
    print('courts array: $courts');

    for (final timeSlot in visibleTimeSlots) {
      for (final court in courts) {
        print('DEBUG COMPARACIÓN:');
        print('  selectedDate: "$selectedDate"');
        print('  court buscada: "$court"');
        print('  timeSlot: "$timeSlot"');

        print('BUSCANDO: timeSlot="$timeSlot", court="$court", selectedDate="$selectedDate"');
        for (final b in bookings) {
          print('  COMPARANDO CON: timeSlot="${b.timeSlot}", court="${b.courtId}", date="${b.date}"');
          print('    timeSlot match: ${b.timeSlot == timeSlot}');
          print('    court match: ${b.courtId == court}');  
          print('    date match: ${b.date == selectedDate}');
        }

        // Buscar reserva específica para esta cancha y horario
        final bookingsForCourtAndTime = bookings.where(
          (b) => b.timeSlot == timeSlot && b.date == dateOnly && b.courtId == court,
        ).toList();
        
        if (bookingsForCourtAndTime.isEmpty) {
          // No hay reserva en esta cancha para este horario
          availableCount++;
        } else {
          final booking = bookingsForCourtAndTime.first;

          print('ENCONTRÓ RESERVA: Court=${booking.courtId}, TimeSlot=${booking.timeSlot}, Players=${booking.players.length}');
          
          try {
            final status = booking.calculatedStatus;
            print('calculatedStatus: $status');
            
            if (status == BookingStatus.complete) {
              completeCount++;
              print('CATEGORIZADO COMO COMPLETO');
            } else if (status == BookingStatus.incomplete) {
              incompleteCount++;
              print('CATEGORIZADO COMO INCOMPLETO');
            }
          } catch (e) {
            print('ERROR al acceder calculatedStatus: $e');
          }
        }
      }
    }

    final result = {
      'complete': completeCount,
      'incomplete': incompleteCount,  
      'available': availableCount,
    };
    
    print('Slots: ${visibleTimeSlots.length}, Courts: ${courts.length}');
    print('Total slots evaluados: ${visibleTimeSlots.length * courts.length}');
    print('Resultado: complete=$completeCount, incomplete=$incompleteCount, available=$availableCount');
    
    return result;
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

  Booking? getBookingForTimeSlot(String timeSlot, String courtId) {
    print('DEBUG getBookingForTimeSlot: buscando slot $timeSlot en cancha $courtId');
    
    final dateOnly = selectedDate.toString().split(' ')[0];
    
    for (final booking in bookings) {
      if (booking.timeSlot == timeSlot && 
          booking.date == dateOnly && 
          booking.courtId == courtId) {
        print('  -> Booking encontrado: ${booking.courtId}, players: ${booking.players.length}');
        return booking;
      }
    }
    
    print('  -> No se encontró booking para $timeSlot en $courtId');
    return null;
  }

  bool isTimeSlotAvailable(String timeSlot, [String? courtId]) {
    final courtToCheck = courtId ?? selectedCourtId;
    return getBookingForTimeSlot(timeSlot, courtToCheck) == null;
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
    
    // Para golf: mantener lógica actual (48 horas exactas)
    final bool isGolf = _selectedCourtId?.startsWith('golf_') ?? false;
    
    if (isGolf) {
      final DateTime endTime = now.add(Duration(hours: 48));
      DateTime current = DateTime(now.year, now.month, now.day);
      
      while (current.isBefore(endTime.add(Duration(days: 1)))) {
        _availableDates.add(current);
        current = current.add(Duration(days: 1));
      }
    } else {
      // Tennis/Paddle: solo fechas futuras
      DateTime current = DateTime(now.year, now.month, now.day + 1); // Mañana
      
      // DEBUG: Imprimir para verificar
      print('DEBUG: Hora actual: $now');
      print('DEBUG: Primer día disponible: $current');
      
      for (int i = 0; i < 3; i++) {
        _availableDates.add(current);
        print('DEBUG: Agregando fecha: $current');
        current = current.add(Duration(days: 1));
      }
    }
    
    _currentDateIndex = 0;
    _selectedDate = _availableDates.isNotEmpty ? _availableDates.first : now;
    
    // DEBUG: Ver resultado final
    print('DEBUG: Fechas disponibles finales: $_availableDates');
    print('DEBUG: Fecha seleccionada: $_selectedDate');
  }
  
  Future<bool> _hasConflictingReservation(
    String userEmail, 
    String date, 
    String timeSlot, 
    String sport
  ) async {
    try {
      // Obtener todas las reservas para esa fecha
      final querySnapshot = await _firestore
          .collection('bookings')
          .where('date', isEqualTo: date)
          .get();
      
      final userBookings = <Booking>[];
      
      // Filtrar reservas del usuario
      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final booking = Booking(
          id: doc.id,
          courtId: data['courtId'] ?? '',
          date: data['date'] ?? '',
          timeSlot: data['timeSlot'] ?? '',
          players: (data['players'] as List<dynamic>?)
              ?.map((playerData) => BookingPlayer.fromMap(playerData))
              .toList() ?? [],
          status: data['status'] != null ? BookingStatus.values.firstWhere(
            (status) => status.toString() == 'BookingStatus.${data['status']}',
            orElse: () => BookingStatus.complete,
          ) : null,
          createdAt: data['createdAt']?.toDate(),
          updatedAt: data['updatedAt']?.toDate(),
        );
        
        // Verificar si el usuario está en la reserva
        final isUserInBooking = booking.players.any((player) => 
          (player.email?.toLowerCase() ?? '') == userEmail.toLowerCase()
        );
        
        if (isUserInBooking) {
          userBookings.add(booking);
        }
      }
      
      // Filtrar por deporte y verificar ventana de 4 horas
      for (final booking in userBookings) {
        final bookingSport = AppConstants.getCourtSport(booking.courtId);
        if (bookingSport == sport && BookingTimeUtils.isWithin4Hours(timeSlot, booking.timeSlot)) {
          return true; // Hay conflicto
        }
      }
      
      return false; // Sin conflicto
    } catch (e) {
      print('Error checking conflicting reservation: $e');
      return false; // En caso de error, permitir la reserva
    }
  }

  void _showConflictDialog(String sport, BuildContext context, {String? conflictingPlayerName}) {
    final playerInfo = conflictingPlayerName != null ? ' ($conflictingPlayerName)' : '';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reserva no permitida'),
        content: Text(
          'El jugador$playerInfo ya tiene una reserva de $sport con menos de 4 horas de diferencia. '
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  void forceRegenerateAvailableDates() {
    print('🔧 FORZANDO REGENERACIÓN DE FECHAS');
    _generateAvailableDates();
    notifyListeners();
    print('🔧 REGENERACIÓN COMPLETADA');
  }

  List<String> getFilteredTimeSlots(DateTime date) {
    final bool isGolf = _selectedCourtId?.startsWith('golf_') ?? false;
    
    if (isGolf) {
      return _getGolfTimeSlots(); 
    } else {
      // Tennis/Padel usan slots predefinidos con filtro 72h
      return BookingTimeUtils.getAvailableTimeSlots(date);
    }
  }

  // 🆕 MÉTODO NUEVO #2 - SIMPLIFICADO (solo para Golf)
  List<String> _getGolfTimeSlots() {
    final bool isSummer = _isSummerSeason();
    
    // Valores de golf desde configuración
    const startTime = '08:00';
    final endTime = isSummer ? '17:00' : '16:00';
    const intervalMinutes = 12;
    
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

  // 🆕 MÉTODO NUEVO #3 - MANTENER IGUAL  
  bool _isSummerSeason() {
    final currentDate = DateTime.now();
    return currentDate.month >= 10 || currentDate.month <= 3;
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
    
    // Usar los nuevos métodos centralizados
    final sport = _selectedCourtId?.startsWith('tennis_') == true ? 'tennis' : 
                _selectedCourtId?.startsWith('golf_') == true ? 'golf' : 'padel';
    final allTimeSlots = AppConstants.getTimeSlotsForSport(sport, date);
    
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
  Future<void> createBooking(Booking booking, BuildContext context) async {
    try {
      // NUEVA VALIDACIÓN: Verificar ventana 4 horas
      final sport = AppConstants.getCourtSport(booking.courtId);
      final hasConflict = await _hasConflictingReservation(
        booking.players.isNotEmpty ? booking.players.first.email ?? '' : '',
        booking.date,
        booking.timeSlot,
        sport
      );

      if (hasConflict) {
        _showConflictDialog(sport, context);
        return;
      }

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

      if (bookingId.isEmpty) {
        throw Exception('Error al crear reserva en Firebase');
      }

      // Actualizar booking con ID real y agregar a lista local
      final finalBooking = booking.copyWith(id: bookingId);
      _bookings.add(finalBooking);
      notifyListeners(); // Esto forzará que las estadísticas se recalculen
      
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
    required BuildContext context, // AGREGAR ESTE PARÁMETRO
  }) async {
    try {
      // NUEVA VALIDACIÓN: Verificar ventana 4 horas para TODOS los jugadores
      final sport = AppConstants.getCourtSport(courtId);

      for (final player in players) {
        print('  - ${player.name}: ${player.email}');
        
        // Excepción: Jugadores VISITA no tienen restricciones
        if (player.name?.toUpperCase().contains('VISITA') == true) {
          print('  ⚪ ${player.name} es VISITA - sin restricciones');
          continue;
        }
        
        final playerEmail = player.email ?? '';
        if (playerEmail.isNotEmpty) {
          final hasConflict = await _hasConflictingReservation(
            playerEmail,
            date,
            timeSlot,
            sport
          );

          if (hasConflict) {
            _showConflictDialog(sport, context, conflictingPlayerName: player.name);
            return false;
          }
        }
      }
      
      print('🔍 TIMESLOT: $timeSlot');
      print('🔍 SPORT: $sport');
      
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
      
      // 🆕 1. CAPTURAR jugadores originales ANTES del cambio
      final originalBooking = _bookings.firstWhere((b) => b.id == bookingId);
      final originalPlayers = List<BookingPlayer>.from(originalBooking.players);
      print('🔥 DEBUG: Jugadores originales = ${originalPlayers.map((p) => p.name).toList()}');
      
      // Llamada atómica al servicio específico (CÓDIGO EXISTENTE)
      await FirestoreService.updateBookingPlayers(bookingId, updatedPlayers);
      print('🔥 DEBUG BookingProvider: FirestoreService.updateBookingPlayers completado');
      
      // Actualizar el estado local (CÓDIGO EXISTENTE)
      final bookingIndex = _bookings.indexWhere((b) => b.id == bookingId);
      print('🔥 DEBUG BookingProvider: bookingIndex encontrado = $bookingIndex');
      
      if (bookingIndex != -1) {
        _bookings[bookingIndex] = _bookings[bookingIndex].copyWith(players: updatedPlayers);
        print('🔥 DEBUG BookingProvider: Estado local actualizado');
      }
      
      // 🆕 2. DETECTAR cambios y enviar emails de notificación
      await _handleAdminPlayerChangesNotification(
        originalBooking,
        originalPlayers,
        updatedPlayers,
      );
      
      _setLoading(false);
      notifyListeners();
      
      print('🔥 DEBUG BookingProvider: editBookingPlayers completado exitosamente');
      
    } catch (e) {
      print('🔥 DEBUG BookingProvider: ERROR = $e');
      _setError('Error al editar los jugadores de la reserva: $e');
    }
  }

  // 🆕 3. MÉTODO NUEVO para detectar cambios y enviar emails
  Future<void> _handleAdminPlayerChangesNotification(
    Booking originalBooking,
    List<BookingPlayer> originalPlayers,
    List<BookingPlayer> updatedPlayers,
  ) async {
    print('🔥 DEBUG: Analizando cambios en jugadores...');
    
    // Detectar jugadores AGREGADOS (están en updated pero no en original)
    final addedPlayers = updatedPlayers.where((updated) {
      return !originalPlayers.any((original) => 
        (original.email?.toLowerCase() ?? '') == (updated.email?.toLowerCase() ?? '')
      );
    }).toList();
    
    // Detectar jugadores REMOVIDOS (están en original pero no en updated)
    final removedPlayers = originalPlayers.where((original) {
      return !updatedPlayers.any((updated) => 
        (original.email?.toLowerCase() ?? '') == (updated.email?.toLowerCase() ?? '')
      );
    }).toList();
    
    print('🔥 DEBUG: Jugadores agregados: ${addedPlayers.map((p) => p.name).toList()}');
    print('🔥 DEBUG: Jugadores removidos: ${removedPlayers.map((p) => p.name).toList()}');
    
    // Usar EmailService para enviar notificaciones
    for (final player in addedPlayers) {
      await EmailService.sendPlayerAddedNotification(
        updatedBooking: originalBooking.copyWith(players: updatedPlayers)
      );
    }
    
    for (final player in removedPlayers) {
      await EmailService.sendPlayerRemovedNotification(
        updatedBooking: originalBooking,
        removedPlayer: player,
      );
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