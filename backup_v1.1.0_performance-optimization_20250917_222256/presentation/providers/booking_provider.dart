/// lib/presentation/providers/booking_provider.dart
/// 
/// CAMBIOS IMPLEMENTADOS:
/// âœ… Estados dinÃ¡micos segÃºn deporte y nÃºmero de jugadores
/// âœ… Pádel: Siempre BookingStatus.complete (4 jugadores obligatorio)
/// âœ… Tenis: BookingStatus.incomplete para 2-3 jugadores, complete para 4
/// âœ… ParÃ¡metro initialStatus en createBookingWithEmails
/// âœ… ValidaciÃ³n flexible por deporte

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

/// Provider principal para gestiÃ³n de estado de reservas
class BookingProvider extends ChangeNotifier {
  // ============================================================================
  // ESTADO PRIVADO
  // ============================================================================
  
  List<BookingPlayer> _users = [];
  List<BookingPlayer>? get users => _users;
  List<Court> _courts = [];
  List<Booking> _bookings = [];
  String _selectedCourtId = 'padel_court_1';
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  String? _error;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<DateTime> _availableDates = [];
  int _currentDateIndex = 0;
  
  bool _isSendingEmails = false;
  
  // Streams subscriptions para limpiar recursos
  StreamSubscription? _courtsSubscription;
  StreamSubscription? _bookingsSubscription;
  
  // ============================================================================
  // GETTERS PÃšBLICOS
  // ============================================================================
  
  // AGREGAR estos mÃ©todos despuÃ©s de las propiedades privadas
  DateTime _getSmartInitialDate() {
    final now = DateTime.now();
    final currentHour = now.hour;
    final currentMinute = now.minute;
    
    // DespuÃ©s de 4:01 PM - mostrar desde maÃ±ana
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
    
    // Entre 8:01 AM y 4:00 PM - 3 dÃ­as disponibles
    if ((currentHour == 8 && currentMinute >= 1) || 
        (currentHour > 8 && currentHour < 16) || 
        (currentHour == 16 && currentMinute == 0)) {
      return 3;
    }
    
    // Resto del tiempo - 2 dÃ­as disponibles
    return 2;
  }

  // MÃ©todo pÃºblico para inicializar fechas inteligentes de golf
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
    
    // DEBUG: print('ðŸ” DEBUG RESERVAS FILTRADAS:');
    // DEBUG: print('   Court seleccionada: $_selectedCourtId');
    // DEBUG: print('   Fecha seleccionada: $selectedDateStr ($_selectedDate)');
    // DEBUG: print('   Total bookings en _bookings: ${_bookings.length}');
    
    // Debug: Mostrar TODAS las reservas primero
    for (var booking in _bookings) {

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
    
    // DEBUG: print('ðŸ” getAllBookingsForDate para $dateStr:');
    // DEBUG: print('   Total en _bookings: ${_bookings.length}');
    // DEBUG: print('   Para fecha especÃ­fica: ${bookingsForDate.length}');
    
    for (var booking in bookingsForDate) {

    }
    
    return bookingsForDate;
  }
  
  // ============================================================================
  // âœ… NUEVO: DETERMINACIÃ“N DE ESTADO INICIAL POR DEPORTE
  // ============================================================================

  /// Determina el estado inicial de una reserva segÃºn el deporte y nÃºmero de jugadores
  /// 
  /// REGLAS:
  /// - PÃDEL: Siempre BookingStatus.complete (requiere exactamente 4 jugadores)
  /// - TENIS: BookingStatus.incomplete para 2-3 jugadores, complete para 4+
  /// 
  /// @param courtId ID de la cancha para identificar el deporte
  /// @param playerCount NÃºmero de jugadores en la reserva
  /// @return BookingStatus apropiado segÃºn las reglas de negocio
  BookingStatus determineInitialBookingStatus(String courtId, int playerCount) {
    // DEBUG: print('ðŸŽ¯ DETERMINANDO ESTADO INICIAL:');
    // DEBUG: print('   Court ID: $courtId');
    // DEBUG: print('   Jugadores: $playerCount');
    
    if (courtId.startsWith('padel_')) {
      // PERFORMANCE: print('   â†’ PÃDEL detectado: BookingStatus.complete');
      return BookingStatus.complete;
    } else if (courtId.startsWith('tennis_')) {
      // PERFORMANCE: print('   â†’ TENIS detectado: BookingStatus.complete');
      return BookingStatus.complete;
    }
    
    // PERFORMANCE: print('   â†’ FALLBACK: BookingStatus.complete');
    return BookingStatus.complete;
  }

  String _getSportFromCourtId(String courtId) {
    if (courtId.startsWith('golf_')) return 'GOLF';
    if (courtId.startsWith('tennis_')) return 'TENIS';
    return 'PADEL';
  }

  // ============================================================================
  // VALIDACIÃ“N DE CONFLICTOS - CON VALIDACIÃ“N POR DEPORTE
  // ============================================================================

  /// âœ… MEJORADO: Valida si se puede crear una reserva con reglas especÃ­ficas por deporte
  ValidationResult canCreateBooking(String courtId, String date, String timeSlot, List<String> playerNames) {
    // PERFORMANCE: print('\nðŸ” VALIDACIÃ“N COMPLETA - INICIO');
    // PERFORMANCE: print('   Court: $courtId');
    // PERFORMANCE: print('   Fecha: $date'); 
    // PERFORMANCE: print('   Hora: $timeSlot');
    // PERFORMANCE: print('   Jugadores: ${playerNames.join(", ")}');
    // PERFORMANCE: print('   Total reservas en memoria: ${_bookings.length}');

    // âœ… NUEVO: ValidaciÃ³n especÃ­fica por deporte ANTES de conflictos
    final sport = _getSportFromCourtId(courtId);
    final playerCount = playerNames.length;
    
    // PERFORMANCE: print('ðŸŽ¯ VALIDANDO LÃMITES POR DEPORTE:');
    // PERFORMANCE: print('   Deporte detectado: $sport');
    // PERFORMANCE: print('   Jugadores proporcionados: $playerCount');
    
    if (sport == 'PADEL') {
      // âœ… FIX: Solo validar lÃ­mites al crear la reserva, no al abrir modal
      if (playerCount < 1) {
        // PERFORMANCE: print('âŒ VALIDACIÃ“N: Pádel requiere al menos el organizador');
        return ValidationResult(
          isValid: false,
          reason: 'Se requiere al menos un jugador.'
        );
      } else if (playerCount > 4) {
        // PERFORMANCE: print('âŒ VALIDACIÃ“N: Pádel permite mÃ¡ximo 4 jugadores');
        return ValidationResult(
          isValid: false,
          reason: 'Pádel permite mÃ¡ximo 4 jugadores. Tienes $playerCount.'
        );
      }
      // PERFORMANCE: print('âœ… VALIDACIÃ“N: Pádel con $playerCount jugador(es) - validaciÃ³n inicial OK');
    } else if (sport == 'TENIS') {
      if (playerCount < 1) {
        // PERFORMANCE: print('âŒ VALIDACIÃ“N: Tenis requiere al menos el organizador');
        return ValidationResult(
          isValid: false,
          reason: 'Se requiere al menos un jugador.'
        );
      } else if (playerCount > 4) {
        // PERFORMANCE: print('âŒ VALIDACIÃ“N: Tenis permite mÃ¡ximo 4 jugadores');
        return ValidationResult(
          isValid: false,
          reason: 'Tenis permite mÃ¡ximo 4 jugadores. Tienes $playerCount.'
        );
      }
      // PERFORMANCE: print('âœ… VALIDACIÃ“N: Tenis con $playerCount jugador(es) - validaciÃ³n inicial OK');
    }

    // PERFORMANCE: print('âœ… LÃMITES POR DEPORTE: ValidaciÃ³n exitosa');

    // El resto del mÃ©todo sigue igual...
    // 1. Verificar reserva duplicada exacta (mismo slot, misma cancha)
    final exactDuplicates = _bookings.where(
      (booking) => 
        booking.courtId == courtId && 
        booking.date == date && 
        booking.timeSlot == timeSlot,
    ).toList();

    // PERFORMANCE: print('ðŸ” Verificando duplicados exactos: ${exactDuplicates.length} encontrados');
    
    if (exactDuplicates.isNotEmpty) {
      final existingBooking = exactDuplicates.first;
      // PERFORMANCE: print('âŒ VALIDACIÃ“N: Reserva duplicada detectada');
      // PERFORMANCE: print('   Jugadores existentes: ${existingBooking.players.map((p) => p.name).join(", ")}');
      return ValidationResult(
        isValid: false, 
        reason: 'Ya existe una reserva para este horario en esta cancha.'
      );
    }

    // PERFORMANCE: print('âœ… Sin duplicados exactos, verificando conflictos de jugadores...');

    // 2. Verificar conflictos de jugadores en otras canchas
    final allBookingsForDate = getAllBookingsForDate(DateTime.parse(date));
    final conflictingBookings = allBookingsForDate.where((booking) => 
      booking.timeSlot == timeSlot && booking.courtId != courtId
    ).toList();

    // PERFORMANCE: print('ðŸ” Reservas en otras canchas para $timeSlot: ${conflictingBookings.length}');

    for (final booking in conflictingBookings) {

      
      for (final existingPlayer in booking.players) {
        for (final newPlayerName in playerNames) {
          // Ignorar jugadores especiales VISITA
          if (_isSpecialVisitPlayer(newPlayerName) || _isSpecialVisitPlayer(existingPlayer.name)) {
            // PERFORMANCE: print('   âš ï¸ Jugador VISITA detectado, omitiendo validaciÃ³n: $newPlayerName o ${existingPlayer.name}');
            continue;
          }

          // Verificar conflicto de nombre (case-insensitive y limpio)
          if (_playersMatch(existingPlayer.name, newPlayerName)) {
            // PERFORMANCE: print('âŒ VALIDACIÃ“N: Conflicto detectado!');
            // PERFORMANCE: print('   Jugador: ${existingPlayer.name}');
            // PERFORMANCE: print('   Ya reservado en: ${booking.courtId} a las $timeSlot');
            return ValidationResult(
              isValid: false,
              reason: 'El jugador "${existingPlayer.name}" ya tiene una reserva a las $timeSlot en ${AppConstants.getCourtName(booking.courtId)}.'
            );
          }
        }
      }
    }

    // PERFORMANCE: print('âœ… VALIDACIÃ“N: Sin conflictos detectados - reserva permitida');
    // PERFORMANCE: print('ðŸ” VALIDACIÃ“N COMPLETA - FIN\n');
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
  
  // ============================================================================
  // ESTADÃSTICAS PARA UI
  // ============================================================================

  Map<String, int> getStatsForVisibleTimeSlots(List<String> visibleTimeSlots) {
    // // DEBUG: print('=== CALCULANDO STATS ===');
  
    // FIX: Extraer solo la fecha sin timestamp
    final dateOnly = '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
    // DEBUG: print('selectedDate original: $selectedDate');
    // DEBUG: print('dateOnly para comparar: $dateOnly');
    
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
    
    // PERFORMANCE: print('selectedCourtId: $selectedCourtId');
    // PERFORMANCE: print('courts array: $courts');

    for (final timeSlot in visibleTimeSlots) {
      for (final court in courts) {
        // PERFORMANCE: print('DEBUG COMPARACIÃ“N:');
        // PERFORMANCE: print('  selectedDate: "$selectedDate"');
        // PERFORMANCE: print('  court buscada: "$court"');
        // PERFORMANCE: print('  timeSlot: "$timeSlot"');

        // PERFORMANCE: print('BUSCANDO: timeSlot="$timeSlot", court="$court", selectedDate="$selectedDate"');
        for (final b in bookings) {
          }

        // Buscar reserva especÃ­fica para esta cancha y horario
        final bookingsForCourtAndTime = bookings.where(
          (b) => b.timeSlot == timeSlot && b.date == dateOnly && b.courtId == court,
        ).toList();
        
        if (bookingsForCourtAndTime.isEmpty) {
          // No hay reserva en esta cancha para este horario
          availableCount++;
        } else {
          final booking = bookingsForCourtAndTime.first;

          // PERFORMANCE: print('ENCONTRÃ“ RESERVA: Court=${booking.courtId}, TimeSlot=${booking.timeSlot}, Players=${booking.players.length}');
          
          try {
            final status = booking.calculatedStatus;
            // PERFORMANCE: print('calculatedStatus: $status');
            
            if (status == BookingStatus.complete) {
              completeCount++;
              // PERFORMANCE: print('CATEGORIZADO COMO COMPLETO');
            } else if (status == BookingStatus.incomplete) {
              incompleteCount++;
              // PERFORMANCE: print('CATEGORIZADO COMO INCOMPLETO');
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
    
    // PERFORMANCE: print('Slots: ${visibleTimeSlots.length}, Courts: ${courts.length}');
    // PERFORMANCE: print('Total slots evaluados: ${visibleTimeSlots.length * courts.length}');
    // PERFORMANCE: print('Resultado: complete=$completeCount, incomplete=$incompleteCount, available=$availableCount');
    
    return result;
  }

  // MÃ©todos de conveniencia que mantienen la API existente
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
  // MÃ‰TODOS AUXILIARES
  // ============================================================================

  Booking? getBookingForTimeSlot(String timeSlot, String courtId) {
    // PERFORMANCE: print('DEBUG getBookingForTimeSlot: buscando slot $timeSlot en cancha $courtId');
    
    final dateOnly = selectedDate.toString().split(' ')[0];
    
    for (final booking in bookings) {
      if (booking.timeSlot == timeSlot && 
          booking.date == dateOnly && 
          booking.courtId == courtId) {
        // PERFORMANCE: print('  -> Booking encontrado: ${booking.courtId}, players: ${booking.players.length}');
        return booking;
      }
    }
    
    // PERFORMANCE: print('  -> No se encontrÃ³ booking para $timeSlot en $courtId');
    return null;
  }

  bool isTimeSlotAvailable(String timeSlot, [String? courtId]) {
    final courtToCheck = courtId ?? selectedCourtId;
    return getBookingForTimeSlot(timeSlot, courtToCheck) == null;
  }

  // ============================================================================
  // INICIALIZACIÃ“N
  // ============================================================================
  
  BookingProvider() {
    _initializeProvider();
  }
  
  Future<void> _initializeProvider() async {
    // PERFORMANCE: print('ðŸ”¥ Inicializando BookingProvider con Firebase...');
    _generateAvailableDates();
    await _loadCourts();
    await _loadBookings();
    await initializeCurrentUser();
  }

  Future<void> initializeCurrentUser() async {
    try {
      final email = await UserService.getCurrentUserEmail();
      final name = await UserService.getCurrentUserName();
      
      // PERFORMANCE: print('ðŸ”¥ Auto-completando primer jugador: $name ($email)');
      
      // Exponer usuario actual para formularios
      _currentUserEmail = email;
      _currentUserName = name;
      
      notifyListeners();
    } catch (e) {
      print('âŒ Error inicializando usuario actual: $e');
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

  // Getters pÃºblicos para usuario actual
  String? get currentUserEmail => _currentUserEmail;
  String? get currentUserName => _currentUserName;
  bool get hasCurrentUser => _currentUserEmail != null && _currentUserName != null;

  void _generateAvailableDates() {
    _availableDates.clear();
    
    final now = DateTime.now();
    
    // Para golf: mantener lÃ³gica actual (48 horas exactas)
    final bool isGolf = _selectedCourtId?.startsWith('golf_') ?? false;
    
    if (isGolf) {
      final DateTime endTime = now.add(Duration(hours: 48));
      DateTime current = DateTime(now.year, now.month, now.day);
      
      while (current.isBefore(endTime.add(Duration(days: 1)))) {
        _availableDates.add(current);
        current = current.add(Duration(days: 1));
      }
    } else {
      // âœ… CORRECCIÃ“N: Tennis/Paddle empezar desde HOY, no maÃ±ana
      DateTime today = DateTime(now.year, now.month, now.day);
      
      // TEMPORAL: Siempre empezar desde HOY (simplificado)
      bool hasSlotsToday = now.hour < 16; // â† LÃ³gica simple temporal
      
      DateTime startDate = hasSlotsToday ? today : today.add(Duration(days: 1));
      
      // DEBUG: Imprimir para verificar
      // PERFORMANCE: print('DEBUG: Hora actual: $now');
      // PERFORMANCE: print('DEBUG: Â¿Empezar desde hoy?: $hasSlotsToday (hora: ${now.hour})');
      // PERFORMANCE: print('DEBUG: Fecha de inicio: $startDate');
      
      DateTime current = startDate;
      
      // Generar 3 dÃ­as desde la fecha de inicio
      for (int i = 0; i < 3; i++) {
        _availableDates.add(current);
        // PERFORMANCE: print('DEBUG: Agregando fecha: $current');
        current = current.add(Duration(days: 1));
      }
      
      // Si no incluimos hoy, agregar un dÃ­a mÃ¡s para mantener 3 dÃ­as de ventana
      if (!hasSlotsToday) {
        _availableDates.add(current);
        // PERFORMANCE: print('DEBUG: Agregando dÃ­a extra: $current');
      }
    }
    
    _currentDateIndex = 0;
    _selectedDate = _availableDates.isNotEmpty ? _availableDates.first : now;
    
    // DEBUG: Ver resultado final
    // PERFORMANCE: print('DEBUG: Fechas disponibles finales: $_availableDates');
    // PERFORMANCE: print('DEBUG: Fecha seleccionada: $_selectedDate');
  }

  // âœ… Verificar slots disponibles hoy  
  bool _hasAvailableSlotsToday(DateTime now) {
    // Slots estÃ¡ndar para Tennis/Paddle
    List<String> allSlots = [
      '9:00', '10:30', '12:00', '13:30', '15:00', '16:30'
    ];
    
    // Agregar slots de verano si aplica - USAR MÃ‰TODO EXISTENTE
    if (_isSummerSeason(now)) {
      allSlots.addAll(['18:00', '19:30']);
    }
    
    // Verificar si algÃºn slot es posterior a ahora + 1 hora (margen mÃ­nimo)
    DateTime minimumTime = now.add(Duration(hours: 1));
    
    for (String slotStr in allSlots) {
      DateTime slotTime = _parseSlotToDateTime(now, slotStr);
      if (slotTime.isAfter(minimumTime)) {
        // PERFORMANCE: print('DEBUG: Slot vÃ¡lido encontrado: $slotStr ($slotTime)');
        return true;
      }
    }
    
    // PERFORMANCE: print('DEBUG: No hay slots vÃ¡lidos restantes hoy');
    return false;
  }

  // âœ… Convertir slot string a DateTime
  DateTime _parseSlotToDateTime(DateTime baseDate, String timeSlot) {
    List<String> parts = timeSlot.split(':');
    int hour = int.parse(parts[0]);
    int minute = parts.length > 1 ? int.parse(parts[1]) : 0;
    
    return DateTime(
      baseDate.year,
      baseDate.month, 
      baseDate.day,
      hour,
      minute
    );
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
        
        // Verificar si el usuario estÃ¡ en la reserva
        final isUserInBooking = booking.players.any((player) => 
          (player.email?.toLowerCase() ?? '') == userEmail.toLowerCase()
        );
        
        if (isUserInBooking) {
          userBookings.add(booking);
        }
      }
      
      // Verificar conflictos de tiempo segÃºn deporte
      for (final existingBooking in userBookings) {
        String existingSport = AppConstants.getSportFromCourtId(existingBooking.courtId);
        
        // Solo verificar conflictos dentro del mismo deporte
        if (existingSport == sport) {
          // Verificar si estÃ¡n dentro de la ventana de 4 horas
          if (BookingTimeUtils.isWithin4Hours(
            existingBooking.timeSlot, 
            timeSlot
          )) {
            return true; // Hay conflicto
          }
        }
      }
      
      return false; // No hay conflicto
      
    } catch (e) {
      print('Error verificando conflictos: $e');
      return false; // En caso de error, permitir la reserva
    }
  }

  // âœ… NUEVO MÃ‰TODO: Determinar si es temporada de verano
  bool _isSummerSeason(DateTime date) {
    int month = date.month;
    // Verano en Chile: Octubre a Marzo
    return month >= 10 || month <= 3;
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
    // PERFORMANCE: print('ðŸ”§ FORZANDO REGENERACIÃ“N DE FECHAS');
    _generateAvailableDates();
    notifyListeners();
    // PERFORMANCE: print('ðŸ”§ REGENERACIÃ“N COMPLETADA');
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

  // ðŸ†• MÃ‰TODO NUEVO #2 - SIMPLIFICADO (solo para Golf)
  List<String> _getGolfTimeSlots() {
    final bool isSummer = _isSummerSeason(DateTime.now());
    
    // Valores de golf desde configuraciÃ³n
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
        // PÃDEL - Mantener IDs originales
        Court(
          id: 'padel_court_1',
          name: 'PITE',
          description: 'Cancha de Pádel PITE',
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
          description: 'Cancha de Pádel LILEN',
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
          description: 'Cancha de Pádel PLAIYA',
          number: 3,
          displayOrder: 3,
          status: 'active',
          isAvailableForBooking: true,
          createdAt: now,
          updatedAt: now,
        ),
        // TENIS - Nuevos IDs Ãºnicos
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
      // PERFORMANCE: print('Cargando reservas desde Firestore...');
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
          
          // PERFORMANCE: print('Reservas cargadas: ${_bookings.length}');
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
    // PERFORMANCE: print('ðŸ”§ LLAMANDO: selectCourt recibiÃ³ = $courtId');
    // PERFORMANCE: print('ðŸ”§ ESTADO ANTES: _selectedCourtId = $_selectedCourtId');
    
    if (_selectedCourtId != courtId) {
      _selectedCourtId = courtId;
      // DEBUG: print('ðŸ”§ ESTADO DESPUÃ‰S: _selectedCourtId = $_selectedCourtId');
      notifyListeners();
    } else {
      // PERFORMANCE: print('ðŸ”§ NO CAMBIÃ“: courtId ya era el mismo');
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
    
    // Usar los nuevos mÃ©todos centralizados
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
    // PERFORMANCE: print('ðŸ”„ Refrescando datos...');
    await _loadBookings();
    
    // Forzar una segunda notificaciÃ³n despuÃ©s de un pequeÃ±o delay
    await Future.delayed(const Duration(milliseconds: 100));
    notifyListeners();
    // PERFORMANCE: print('ðŸ”„ Refresh completado - UI actualizada');
  }

  // ============================================================================
  // âœ… OPERACIONES CRUD - CON ESTADOS DINÃMICOS
  // ============================================================================
  
  /// Crea una reserva bÃ¡sica con validaciÃ³n completa
  Future<void> createBooking(Booking booking, BuildContext context) async {
    try {
      // NUEVA VALIDACIÃ“N: Verificar ventana 4 horas
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
      // PERFORMANCE: print('âž• Creando nueva reserva...');
      
      // ValidaciÃ³n completa
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
      // PERFORMANCE: print('âœ… Reserva creada con ID: $bookingId');

      if (bookingId.isEmpty) {
        throw Exception('Error al crear reserva en Firebase');
      }

      // Actualizar booking con ID real y agregar a lista local
      final finalBooking = booking.copyWith(id: bookingId);
      _bookings.add(finalBooking);
      notifyListeners(); // Esto forzarÃ¡ que las estadÃ­sticas se recalculen
      
      _setLoading(false);
    } catch (e) {
      print('âŒ Error creando reserva: $e');
      _setLoading(false);
      rethrow;
    }
  }

  /// âœ… MÃ‰TODO PRINCIPAL MEJORADO - Crea reserva con estado dinÃ¡mico y emails
  Future<bool> createBookingWithEmails({
    required String courtId,
    required String date,
    required String timeSlot,
    required List<BookingPlayer> players,
    BookingStatus? initialStatus, // NUEVO PARÃMETRO OPCIONAL
    required BuildContext context, // AGREGAR ESTE PARÃMETRO
  }) async {
    try {
      // NUEVA VALIDACIÃ“N: Verificar ventana 4 horas para TODOS los jugadores
      final sport = AppConstants.getCourtSport(courtId);

      for (final player in players) {
        // PERFORMANCE: print('  - ${player.name}: ${player.email}');
        
        // ExcepciÃ³n: Jugadores VISITA no tienen restricciones
        if (player.name?.toUpperCase().contains('VISITA') == true) {
          // PERFORMANCE: print('  âšª ${player.name} es VISITA - sin restricciones');
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
      
      // PERFORMANCE: print('ðŸ” TIMESLOT: $timeSlot');
      // PERFORMANCE: print('ðŸ” SPORT: $sport');
      
      _setLoading(true);
      // PERFORMANCE: print('ðŸ“ Creando reserva con emails automÃ¡ticos...');
      
      // 1. ValidaciÃ³n completa
      final playerNames = players.map((p) => p.name).toList();
      final validation = canCreateBooking(courtId, date, timeSlot, playerNames);
      
      if (!validation.isValid) {
        throw Exception(validation.reason!);
      }
      
      // 2. NUEVO: Determinar estado inicial
      final bookingStatus = initialStatus ?? determineInitialBookingStatus(courtId, players.length);
      
      // PERFORMANCE: print('ðŸŽ¯ ESTADO DETERMINADO PARA RESERVA:');
      // PERFORMANCE: print('   Court ID: $courtId');
      // PERFORMANCE: print('   Jugadores: ${players.length}');
      // PERFORMANCE: print('   Estado asignado: $bookingStatus');
      // PERFORMANCE: print('   Fue proporcionado externamente: ${initialStatus != null}');
      
      // Crear reserva en Firebase
      final booking = Booking(
        id: DateTime.now().millisecondsSinceEpoch.toString(), // Genera un ID temporal
        courtId: courtId,
        date: date,
        timeSlot: timeSlot,
        players: players,
        status: bookingStatus, // USAR EL ESTADO DINÃMICO
        createdAt: DateTime.now(),
        updatedAt: null,
      );

      // PERFORMANCE: print('ðŸ“ Guardando en Firebase...');
      final bookingId = await FirestoreService.createBooking(booking);

      if (bookingId.isEmpty) {
        throw Exception('Error al crear reserva en Firebase');
      }
      
      // 4. Actualizar booking con ID para emails
      final savedBooking = booking.copyWith(id: bookingId);
      
      // 5. Enviar emails de confirmaciÃ³n
      // PERFORMANCE: print('ðŸ“§ Enviando emails de confirmaciÃ³n...');
      _isSendingEmails = true;
      notifyListeners();
      
      final emailsSent = await EmailService.sendBookingConfirmation(booking);
      
      _isSendingEmails = false;
      _setLoading(false);
      
      if (emailsSent) {
        // PERFORMANCE: print('âœ… Reserva creada y emails enviados exitosamente');
        return true;
      } else {
        // PERFORMANCE: print('âš ï¸ Reserva creada pero algunos emails fallaron');
        return true;
      }
      
    } catch (e) {
      print('âŒ Error creando reserva con emails: $e');
      _isSendingEmails = false;
      _setLoading(false);
      rethrow;
    }
  }

  /// Cancela reserva con notificaciones automÃ¡ticas a participantes
  Future<bool> cancelBookingWithNotifications({
    required String bookingId,
    required BookingPlayer cancelingPlayer,
  }) async {
    try {
      _setLoading(true);
      // PERFORMANCE: print('ðŸ—‘ï¸ Cancelando reserva con notificaciones...');
      
      // 1. Obtener datos completos de la reserva
      final booking = await _getBookingById(bookingId);
      if (booking == null) {
        throw Exception('Reserva no encontrada');
      }
      
      // 2. Enviar notificaciones a otros jugadores
      // PERFORMANCE: print('ðŸ“§ Enviando notificaciones de cancelaciÃ³n...');
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
        // PERFORMANCE: print('âœ… Reserva cancelada y notificaciones enviadas');
      } else {
        // PERFORMANCE: print('âš ï¸ Reserva cancelada pero algunas notificaciones fallaron');
      }
      
      return true;
      
    } catch (e) {
      print('âŒ Error cancelando reserva: $e');
      _isSendingEmails = false;
      _setLoading(false);
      rethrow;
    }
  }

  /// âœ… NUEVO: Edita una reserva existente
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

  /// âœ… CORRECCIÃ“N CRÃTICA: Editar solo la lista de jugadores de una reserva
  Future<void> editBookingPlayers({
    required String bookingId,
    required List<BookingPlayer> updatedPlayers,
  }) async {
    // PERFORMANCE: print('ðŸ”¥ DEBUG BookingProvider: editBookingPlayers iniciado');
    // PERFORMANCE: print('ðŸ”¥ DEBUG BookingProvider: bookingId = $bookingId');
    // PERFORMANCE: print('ðŸ”¥ DEBUG BookingProvider: updatedPlayers = ${updatedPlayers.map((p) => p.name).toList()}');
    
    try {
      _setLoading(true);
      
      // ðŸ†• 1. CAPTURAR jugadores originales ANTES del cambio
      final originalBooking = _bookings.firstWhere((b) => b.id == bookingId);
      final originalPlayers = List<BookingPlayer>.from(originalBooking.players);
      // PERFORMANCE: print('ðŸ”¥ DEBUG: Jugadores originales = ${originalPlayers.map((p) => p.name).toList()}');
      
      // Llamada atÃ³mica al servicio especÃ­fico (CÃ“DIGO EXISTENTE)
      await FirestoreService.updateBookingPlayers(bookingId, updatedPlayers);
      // PERFORMANCE: print('ðŸ”¥ DEBUG BookingProvider: FirestoreService.updateBookingPlayers completado');
      
      // Actualizar el estado local (CÃ“DIGO EXISTENTE)
      final bookingIndex = _bookings.indexWhere((b) => b.id == bookingId);
      // PERFORMANCE: print('ðŸ”¥ DEBUG BookingProvider: bookingIndex encontrado = $bookingIndex');
      
      if (bookingIndex != -1) {
        _bookings[bookingIndex] = _bookings[bookingIndex].copyWith(players: updatedPlayers);
        // PERFORMANCE: print('ðŸ”¥ DEBUG BookingProvider: Estado local actualizado');
      }
      
      // ðŸ†• 2. DETECTAR cambios y enviar emails de notificaciÃ³n
      await _handleAdminPlayerChangesNotification(
        originalBooking,
        originalPlayers,
        updatedPlayers,
      );
      
      _setLoading(false);
      notifyListeners();
      
      // PERFORMANCE: print('ðŸ”¥ DEBUG BookingProvider: editBookingPlayers completado exitosamente');
      
    } catch (e) {
      // PERFORMANCE: print('ðŸ”¥ DEBUG BookingProvider: ERROR = $e');
      _setError('Error al editar los jugadores de la reserva: $e');
    }
  }

  // ðŸ†• 3. MÃ‰TODO NUEVO para detectar cambios y enviar emails
  Future<void> _handleAdminPlayerChangesNotification(
    Booking originalBooking,
    List<BookingPlayer> originalPlayers,
    List<BookingPlayer> updatedPlayers,
  ) async {
    // PERFORMANCE: print('ðŸ”¥ DEBUG: Analizando cambios en jugadores...');
    
    // Detectar jugadores AGREGADOS (estÃ¡n en updated pero no en original)
    final addedPlayers = updatedPlayers.where((updated) {
      return !originalPlayers.any((original) => 
        (original.email?.toLowerCase() ?? '') == (updated.email?.toLowerCase() ?? '')
      );
    }).toList();
    
    // Detectar jugadores REMOVIDOS (estÃ¡n en original pero no en updated)
    final removedPlayers = originalPlayers.where((original) {
      return !updatedPlayers.any((updated) => 
        (original.email?.toLowerCase() ?? '') == (updated.email?.toLowerCase() ?? '')
      );
    }).toList();
    
    // PERFORMANCE: print('ðŸ”¥ DEBUG: Jugadores agregados: ${addedPlayers.map((p) => p.name).toList()}');
    // PERFORMANCE: print('ðŸ”¥ DEBUG: Jugadores removidos: ${removedPlayers.map((p) => p.name).toList()}');
    
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

  /// âœ… NUEVO: Elimina una reserva completa
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
      
      // 3. Enviar notificaciÃ³n de eliminaciÃ³n a todos los jugadores
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
      print('âŒ Error obteniendo reserva: $e');
      return null;
    }
  }

  /// Carga la lista de usuarios desde Firebase y la asigna a _users.
  /// Llama a notifyListeners() para actualizar la UI cuando los datos estÃ¡n listos.
  Future<void> fetchUsers() async {
    try {
      _setLoading(true);
      final firebaseUsers = await FirebaseUserService.getAllUsers();
      
      // PERFORMANCE: print('ðŸ“¦ Datos de usuarios de Firebase: $firebaseUsers');
      _users = firebaseUsers.map((userMap) {
        return BookingPlayer(
          id: (userMap['uid'] as String?) ?? 'null-uid',
          name: (userMap['name'] as String?) ?? 'No Name',
          email: userMap['email'] as String?,
          phone: userMap['phone'] as String?,
        );
      }).toList();
      
      // PERFORMANCE: print('DEBUG Provider: _users asignados: ${_users.length}');
      // PERFORMANCE: print('DEBUG Provider: users getter: ${users?.length ?? "null"}');
    
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
      
      // Debug para ver cuÃ¡ntas reservas se cargaron
      // PERFORMANCE: print('DEBUG: Reservas cargadas para ${date}: ${_bookings.length}');
      
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
  // GESTIÃ“N DE ESTADO INTERNO
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

/// Clase para encapsular resultados de validaciÃ³n de reservas
class ValidationResult {
  final bool isValid;
  final String? reason;

  ValidationResult({required this.isValid, this.reason});
}


